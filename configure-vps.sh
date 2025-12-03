#!/bin/bash

# ==========================================
# CONFIGURACIÓN VPS: DOCKER + SEGURIDAD (FINAL)
# ==========================================

# --- Colores ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Función para imprimir mensajes
print_msg() {
    echo -e "\n${GREEN}>>> $1${NC}"
}

# --- 1. Lógica de Usuario, Actualización Inicial y Sudo ---
CURRENT_USER=$(id -u)

if [ "$CURRENT_USER" -eq 0 ]; then
    echo -e "${YELLOW}🔑 Ejecutando como ROOT.${NC}"
    SUDO=""
    
    # Requisito: Actualizar e instalar sudo si no existe
    print_msg "Actualizando listas de paquetes..."
    DEBIAN_FRONTEND=noninteractive apt-get update -qq
    
    if ! command -v sudo >/dev/null 2>&1; then
        print_msg "Sudo no detectado. Instalando sudo..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y sudo -qq
    else
        echo "✅ Sudo ya está instalado."
    fi
else
    # Si no es root, verificamos que tenga sudo
    if ! command -v sudo >/dev/null 2>&1; then
        echo -e "${RED}❌ Error: No eres root y 'sudo' no está instalado. No puedo continuar.${NC}"
        exit 1
    fi
    SUDO="sudo"
    echo -e "${BLUE}👤 Ejecutando como usuario normal. Usando SUDO.${NC}"
    
    # Actualizamos listas
    print_msg "Actualizando listas de paquetes..."
    $SUDO DEBIAN_FRONTEND=noninteractive apt-get update -qq
fi

# --- 2. Actualización del Sistema (Upgrade) ---
print_msg "Aplicando actualizaciones del sistema..."
$SUDO DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq

# --- 3. Dependencias Básicas ---
print_msg "Instalando dependencias (curl, git, ufw, fail2ban)..."
$SUDO apt-get install -y curl gnupg ca-certificates lsb-release git ufw fail2ban

# --- 4. Configuración Fail2Ban (Protección SSH) ---
print_msg "Configurando Fail2Ban para proteger SSH..."

# Copiamos la configuración por defecto a .local para no tocar la original
if [ ! -f /etc/fail2ban/jail.local ]; then
    $SUDO cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
fi

# Configuramos reglas personalizadas (Banear 1 hora tras 5 intentos fallidos)
cat <<EOF | $SUDO tee /etc/fail2ban/jail.local
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF

$SUDO systemctl enable fail2ban
$SUDO systemctl restart fail2ban
print_msg "Fail2Ban activo y protegiendo el puerto 22."

# --- 5. Zona Horaria ---
print_msg "Configurando zona horaria (America/Santo_Domingo)..."
$SUDO timedatectl set-timezone America/Santo_Domingo

# --- 6. Instalación Docker (Oficial) ---
print_msg "Instalando Docker desde repositorios OFICIALES..."

$SUDO mkdir -p /etc/apt/keyrings
if [ -f /etc/apt/keyrings/docker.gpg ]; then $SUDO rm /etc/apt/keyrings/docker.gpg; fi

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

$SUDO apt-get update -qq
$SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# --- 7. Usuario Docker ---
if [ "$CURRENT_USER" -ne 0 ]; then
    print_msg "Agregando a $(whoami) al grupo Docker..."
    $SUDO usermod -aG docker "$(whoami)"
fi

# --- 8. Optimización Logs Docker ---
print_msg "Configurando rotación de logs de Docker..."
cat <<EOF | $SUDO tee /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
$SUDO systemctl restart docker

# --- 9. Firewall (UFW) ---
print_msg "Configurando Firewall..."
$SUDO ufw default deny incoming
$SUDO ufw default allow outgoing
$SUDO ufw allow ssh
$SUDO ufw allow 22/tcp
$SUDO ufw allow 80/tcp
$SUDO ufw allow 443/tcp
echo "y" | $SUDO ufw enable

# --- 10. Swap (Solo si es necesario) ---
TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
if [ "$TOTAL_MEM" -lt 4000000 ] && [ ! -f /swapfile ]; then
    print_msg "Creando SWAP de 2GB..."
    $SUDO fallocate -l 2G /swapfile
    $SUDO chmod 600 /swapfile
    $SUDO mkswap /swapfile
    $SUDO swapon /swapfile
    echo '/swapfile none swap sw 0 0' | $SUDO tee -a /etc/fstab
fi

print_msg "¡Instalación FINALIZADA!"
if [ "$CURRENT_USER" -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Cierra sesión y vuelve a entrar para usar Docker sin sudo.${NC}"
fi
echo -e "Estado de seguridad: UFW activo | Fail2Ban activo"
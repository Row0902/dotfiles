#!/bin/bash

# =================================================================
#  VPS SETUP: DOCKER + SEGURIDAD PRO (FAIL2BAN + UFW + SWAP + LOGS)
# =================================================================

# --- Colores para logs ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_msg() {
    echo -e "\n${GREEN}>>> $1${NC}"
}

# --- 1. DETECCIÓN DE USUARIO Y PREPARACIÓN DE SUDO ---
CURRENT_USER=$(id -u)

if [ "$CURRENT_USER" -eq 0 ]; then
    echo -e "${YELLOW}🔑 Ejecutando como ROOT.${NC}"
    SUDO=""
    
    # Si somos root, actualizamos e instalamos sudo si no existe
    print_msg "Actualizando listas de paquetes..."
    DEBIAN_FRONTEND=noninteractive apt-get update -qq
    
    if ! command -v sudo >/dev/null 2>&1; then
        print_msg "Sudo no detectado. Instalando sudo..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y sudo -qq
    fi
else
    # Si no somos root, sudo es obligatorio
    if ! command -v sudo >/dev/null 2>&1; then
        echo -e "${RED}❌ Error: No eres root y 'sudo' no está instalado. Ejecuta esto como root primero o pide permisos.${NC}"
        exit 1
    fi
    SUDO="sudo"
    echo -e "${BLUE}👤 Ejecutando como usuario normal. Usando SUDO.${NC}"
    
    print_msg "Actualizando listas de paquetes..."
    $SUDO DEBIAN_FRONTEND=noninteractive apt-get update -qq
fi

# --- 2. ACTUALIZACIÓN DEL SISTEMA ---
print_msg "Aplicando actualizaciones de seguridad..."
$SUDO DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq

# --- 3. INSTALACIÓN DE DEPENDENCIAS ---
print_msg "Instalando herramientas base (Curl, Git, Firewall, Fail2ban)..."
$SUDO apt-get install -y curl gnupg ca-certificates lsb-release git ufw fail2ban

# --- 4. DETECCIÓN INTELIGENTE DE PUERTO SSH ---
# Buscamos el puerto en la configuración. Si no está explícito, es el 22.
SSH_PORT=$($SUDO grep "^Port" /etc/ssh/sshd_config | awk '{print $2}' | head -n 1)

if [ -z "$SSH_PORT" ]; then
    SSH_PORT=22
    echo -e "${BLUE}ℹ️  Puerto SSH estándar detectado: 22${NC}"
else
    echo -e "${YELLOW}ℹ️  Puerto SSH personalizado detectado: $SSH_PORT${NC}"
fi

# --- 5. CONFIGURACIÓN FAIL2BAN (PROTECCIÓN SSH) ---
print_msg "Configurando Fail2Ban para proteger el puerto $SSH_PORT..."

if [ ! -f /etc/fail2ban/jail.local ]; then
    $SUDO cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
fi

# Reglas: Banear 1 hora tras 5 intentos fallidos
cat <<EOF | $SUDO tee /etc/fail2ban/jail.local
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port    = $SSH_PORT
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF

$SUDO systemctl enable fail2ban
$SUDO systemctl restart fail2ban

# --- 6. ZONA HORARIA ---
print_msg "Configurando zona horaria (America/Santo_Domingo)..."
$SUDO timedatectl set-timezone America/Santo_Domingo

# --- 7. INSTALACIÓN DE DOCKER (REPOS OFICIALES) ---
print_msg "Instalando Docker Engine..."

$SUDO mkdir -p /etc/apt/keyrings
if [ -f /etc/apt/keyrings/docker.gpg ]; then $SUDO rm /etc/apt/keyrings/docker.gpg; fi

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

$SUDO apt-get update -qq
$SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# --- 8. CONFIGURACIÓN USUARIO DOCKER ---
if [ "$CURRENT_USER" -ne 0 ]; then
    print_msg "Agregando usuario actual al grupo Docker..."
    $SUDO usermod -aG docker "$(whoami)"
fi

# --- 9. OPTIMIZACIÓN LOGS DOCKER (EVITAR DISCO LLENO) ---
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

# --- 10. FIREWALL (UFW) - PRODUCCIÓN ---
print_msg "Configurando Firewall (UFW)..."

# Resetear por seguridad (comentado por precaución, descomentar si el server es nuevo)
# $SUDO ufw --force reset 

# Políticas por defecto
$SUDO ufw default deny incoming
$SUDO ufw default allow outgoing

# 1. SSH (Limitado para evitar fuerza bruta)
print_msg "Abriendo SSH en puerto $SSH_PORT (Limitado)..."
$SUDO ufw limit "$SSH_PORT"/tcp comment 'SSH Port'

# 2. Web Standard (Proxy Inverso)
$SUDO ufw allow 80/tcp comment 'HTTP'
$SUDO ufw allow 443/tcp comment 'HTTPS'
$SUDO ufw allow 443/udp comment 'HTTP/3 QUIC'

# NOTA: Puerto 3000 NO se abre. Usar túnel SSH.

# Activar
echo "y" | $SUDO ufw enable

# --- 11. SWAP (MEMORIA VIRTUAL) ---
TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
# Si hay menos de 4GB de RAM y no existe swap
if [ "$TOTAL_MEM" -lt 4000000 ] && [ ! -f /swapfile ]; then
    print_msg "Detectada poca RAM. Creando SWAP de 2GB..."
    $SUDO fallocate -l 2G /swapfile
    $SUDO chmod 600 /swapfile
    $SUDO mkswap /swapfile
    $SUDO swapon /swapfile
    echo '/swapfile none swap sw 0 0' | $SUDO tee -a /etc/fstab
    print_msg "Swap creado."
fi

# --- FIN ---
print_msg "¡INSTALACIÓN COMPLETADA EXITOSAMENTE!"
echo -e "-----------------------------------------------------"
if [ "$CURRENT_USER" -ne 0 ]; then
    echo -e "${YELLOW}⚠️  ATENCIÓN: Cierra sesión y vuelve a entrar para usar Docker sin 'sudo'.${NC}"
fi
echo -e "${BLUE}ℹ️  Dokploy/Portainer:${NC} El puerto 3000 está CERRADO por seguridad."
echo -e "   Para configurar la primera vez, ejecuta en TU PC:"
echo -e "   ${GREEN}ssh -L 3000:localhost:3000 $(whoami)@<IP-DEL-VPS>${NC}"
echo -e "   Y abre en tu navegador: http://localhost:3000"
echo -e "-----------------------------------------------------"
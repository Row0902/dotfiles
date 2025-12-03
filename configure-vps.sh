#!/bin/bash

# =================================================================
#  VPS SETUP: DOCKER + DOKPLOY + TAILSCALE + SEGURIDAD
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

# --- 1. DETECCIÓN DE USUARIO Y SUDO ---
CURRENT_USER=$(id -u)

if [ "$CURRENT_USER" -eq 0 ]; then
    echo -e "${YELLOW}🔑 Ejecutando como ROOT.${NC}"
    SUDO=""
    print_msg "Actualizando listas de paquetes..."
    DEBIAN_FRONTEND=noninteractive apt-get update -qq
    if ! command -v sudo >/dev/null 2>&1; then
        print_msg "Instalando sudo..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y sudo -qq
    fi
else
    if ! command -v sudo >/dev/null 2>&1; then
        echo -e "${RED}❌ Error: 'sudo' no está instalado. Ejecuta como root.${NC}"
        exit 1
    fi
    SUDO="sudo"
    echo -e "${BLUE}👤 Ejecutando como usuario normal. Usando SUDO.${NC}"
    print_msg "Actualizando listas..."
    $SUDO DEBIAN_FRONTEND=noninteractive apt-get update -qq
fi

# --- 2. ACTUALIZACIÓN Y DEPENDENCIAS ---
print_msg "Actualizando sistema e instalando dependencias..."
$SUDO DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq
$SUDO apt-get install -y curl gnupg ca-certificates lsb-release git ufw fail2ban

# --- 3. ZONA HORARIA (RD) ---
print_msg "Configurando zona horaria (Santo Domingo)..."
$SUDO timedatectl set-timezone America/Santo_Domingo

# --- 4. INSTALACIÓN DE DOCKER (OFICIAL) ---
print_msg "Instalando Docker Engine..."
$SUDO mkdir -p /etc/apt/keyrings
if [ -f /etc/apt/keyrings/docker.gpg ]; then $SUDO rm /etc/apt/keyrings/docker.gpg; fi

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

$SUDO apt-get update -qq
$SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configurar usuario
if [ "$CURRENT_USER" -ne 0 ]; then
    $SUDO usermod -aG docker "$(whoami)"
fi

# Optimización de Logs Docker
cat <<EOF | $SUDO tee /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
EOF
$SUDO systemctl restart docker

# --- 5. INSTALACIÓN DE DOKPLOY ---
print_msg "Instalando Dokploy..."
# Dokploy requiere que Docker ya esté corriendo (ya lo hicimos arriba)
curl -sSL https://dokploy.com/install.sh | sh

# --- 6. INSTALACIÓN DE TAILSCALE ---
print_msg "Instalando Tailscale (VPN)..."
curl -fsSL https://tailscale.com/install.sh | sh

# --- 7. SEGURIDAD SSH (FAIL2BAN + PUERTO DINÁMICO) ---
SSH_PORT=$($SUDO grep "^Port" /etc/ssh/sshd_config | awk '{print $2}' | head -n 1)
if [ -z "$SSH_PORT" ]; then SSH_PORT=22; fi
print_msg "Protegiendo SSH (Puerto $SSH_PORT) con Fail2Ban..."

if [ ! -f /etc/fail2ban/jail.local ]; then $SUDO cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local; fi
cat <<EOF | $SUDO tee /etc/fail2ban/jail.local
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
[sshd]
enabled = true
port = $SSH_PORT
EOF
$SUDO systemctl restart fail2ban

# --- 8. FIREWALL (UFW) ---
print_msg "Configurando Firewall..."
$SUDO ufw default deny incoming
$SUDO ufw default allow outgoing

# Reglas Públicas (Internet)
$SUDO ufw limit "$SSH_PORT"/tcp comment 'SSH'
$SUDO ufw allow 80/tcp comment 'HTTP'
$SUDO ufw allow 443/tcp comment 'HTTPS'
$SUDO ufw allow 443/udp comment 'HTTP/3'

# Regla Mágica de Tailscale: Permitir TODO el tráfico que venga de la VPN
# Esto te permite entrar al puerto 3000 SOLO si estás conectado a Tailscale
print_msg "Autorizando tráfico interno de Tailscale..."
$SUDO ufw allow in on tailscale0 comment 'Allow Tailscale Network'

echo "y" | $SUDO ufw enable

# --- 9. SWAP (MEMORIA) ---
TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
if [ "$TOTAL_MEM" -lt 4000000 ] && [ ! -f /swapfile ]; then
    print_msg "Creando SWAP de 2GB..."
    $SUDO fallocate -l 2G /swapfile
    $SUDO chmod 600 /swapfile
    $SUDO mkswap /swapfile
    $SUDO swapon /swapfile
    echo '/swapfile none swap sw 0 0' | $SUDO tee -a /etc/fstab
fi

# --- FIN ---
print_msg "¡INSTALACIÓN COMPLETADA!"
echo -e "-----------------------------------------------------"
echo -e "${YELLOW}PASO FINAL REQUERIDO:${NC}"
echo -e "1. Ejecuta: ${GREEN}sudo tailscale up${NC} y autentícate en el enlace."
echo -e "2. Una vez conectado, obtén tu IP de Tailscale con: ${GREEN}tailscale ip -4${NC}"
echo -e "3. Accede a Dokploy de forma segura:"
echo -e "   👉 ${BLUE}http://<TU-IP-TAILSCALE>:3000${NC}"
echo -e "   (No necesitas abrir el puerto 3000 al público)"
echo -e "-----------------------------------------------------"
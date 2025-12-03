#!/bin/bash

# =================================================================
#  VPS SETUP: DOCKER + DOKPLOY + TAILSCALE + TOOLS
#  v3.0 - Multi-language & Production Ready
# =================================================================

# --- CONFIGURATION / CONFIGURACIÓN ---
# "auto" detects system language. Set "es" or "en" to force.
# "auto" detecta el idioma del sistema. Pon "es" o "en" para forzar.
LANGUAGE="auto"

# Timezone / Zona Horaria
TIMEZONE="America/Santo_Domingo"

# --- COLORS ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- I18N (Internationalization) ---
# Detect system language if set to auto
if [ "$LANGUAGE" == "auto" ]; then
    if [[ "$LANG" == *"es"* ]]; then
        LANGUAGE="es"
    else
        LANGUAGE="en"
    fi
fi

# Define messages
if [ "$LANGUAGE" == "es" ]; then
    MSG_ROOT_DETECT="🔑 Ejecutando como ROOT."
    MSG_USER_DETECT="👤 Ejecutando como usuario normal. Usando SUDO."
    MSG_NO_SUDO="❌ Error: Falta 'sudo'. Ejecuta como root o instálalo."
    MSG_UPDATE="Actualizando sistema e instalando dependencias..."
    MSG_TZ="Configurando zona horaria:"
    MSG_DOCKER="Instalando Docker Engine (Repos Oficiales)..."
    MSG_DOKPLOY="Instalando Dokploy..."
    MSG_TAILSCALE="Instalando Tailscale..."
    MSG_LAZYGIT="Instalando Lazygit..."
    MSG_LAZYGIT_APT="✅ Lazygit instalado vía APT."
    MSG_LAZYGIT_BIN="⚠️ Lazygit antiguo/no encontrado. Instalando binario..."
    MSG_BREW="Instalando Homebrew..."
    MSG_BREW_ROOT="⚠️ No se recomienda instalar Brew como root. Saltando."
    MSG_SEC="Configurando Seguridad (Fail2Ban + UFW)..."
    MSG_SSH_PORT="ℹ️  Puerto SSH detectado:"
    MSG_FIREWALL="Aplicando reglas de Firewall (Abriendo 80, 443, 3000, SSH)..."
    MSG_SWAP="Detectada poca RAM. Creando SWAP de 2GB..."
    MSG_DONE="¡INSTALACIÓN COMPLETADA!"
    MSG_NOTE_1="1. Docker, Dokploy y Tailscale instalados."
    MSG_NOTE_2="2. El puerto 3000 está ABIERTO públicamente."
    MSG_NOTE_3="3. Ejecuta 'sudo tailscale up' para conectar la VPN."
else
    MSG_ROOT_DETECT="🔑 Running as ROOT."
    MSG_USER_DETECT="👤 Running as normal user. Using SUDO."
    MSG_NO_SUDO="❌ Error: 'sudo' missing. Run as root or install it."
    MSG_UPDATE="Updating system and installing dependencies..."
    MSG_TZ="Setting timezone:"
    MSG_DOCKER="Installing Docker Engine (Official Repos)..."
    MSG_DOKPLOY="Installing Dokploy..."
    MSG_TAILSCALE="Installing Tailscale..."
    MSG_LAZYGIT="Installing Lazygit..."
    MSG_LAZYGIT_APT="✅ Lazygit installed via APT."
    MSG_LAZYGIT_BIN="⚠️ Lazygit old/missing. Installing binary..."
    MSG_BREW="Installing Homebrew..."
    MSG_BREW_ROOT="⚠️ Installing Brew as root is not recommended. Skipping."
    MSG_SEC="Configuring Security (Fail2Ban + UFW)..."
    MSG_SSH_PORT="ℹ️  SSH Port detected:"
    MSG_FIREWALL="Applying Firewall rules (Opening 80, 443, 3000, SSH)..."
    MSG_SWAP="Low RAM detected. Creating 2GB SWAP..."
    MSG_DONE="INSTALLATION COMPLETED!"
    MSG_NOTE_1="1. Docker, Dokploy & Tailscale installed."
    MSG_NOTE_2="2. Port 3000 is OPEN to the public."
    MSG_NOTE_3="3. Run 'sudo tailscale up' to connect VPN."
fi

print_msg() { echo -e "\n${GREEN}>>> $1${NC}"; }

# --- 1. USER DETECTION ---
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
    HOME_DIR=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER=$(whoami)
    HOME_DIR="$HOME"
fi

CURRENT_ID=$(id -u)
if [ "$CURRENT_ID" -eq 0 ]; then
    echo -e "${YELLOW}$MSG_ROOT_DETECT${NC}"
    SUDO=""
    DEBIAN_FRONTEND=noninteractive apt-get update -qq
    if ! command -v sudo >/dev/null 2>&1; then apt-get install -y sudo -qq; fi
else
    if ! command -v sudo >/dev/null 2>&1; then echo -e "${RED}$MSG_NO_SUDO${NC}"; exit 1; fi
    SUDO="sudo"
    echo -e "${BLUE}$MSG_USER_DETECT${NC}"
    $SUDO DEBIAN_FRONTEND=noninteractive apt-get update -qq
fi

# --- 2. UPDATES & DEPS ---
print_msg "$MSG_UPDATE"
$SUDO DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq
$SUDO apt-get install -y curl gnupg ca-certificates lsb-release git ufw fail2ban build-essential

# --- 3. TIMEZONE ---
print_msg "$MSG_TZ $TIMEZONE"
$SUDO timedatectl set-timezone "$TIMEZONE"

# --- 4. DOCKER ---
print_msg "$MSG_DOCKER"
$SUDO mkdir -p /etc/apt/keyrings
if [ -f /etc/apt/keyrings/docker.gpg ]; then $SUDO rm /etc/apt/keyrings/docker.gpg; fi

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
OS_ID=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -cs)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS_ID $CODENAME stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

$SUDO apt-get update -qq
$SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

if [ "$CURRENT_ID" -ne 0 ]; then $SUDO usermod -aG docker "$REAL_USER"; fi

# Log Rotation
cat <<EOF | $SUDO tee /etc/docker/daemon.json
{ "log-driver": "json-file", "log-opts": { "max-size": "10m", "max-file": "3" } }
EOF
$SUDO systemctl restart docker

# --- 5. DOKPLOY ---
print_msg "$MSG_DOKPLOY"
curl -sSL https://dokploy.com/install.sh | sh

# --- 6. TAILSCALE ---
print_msg "$MSG_TAILSCALE"
curl -fsSL https://tailscale.com/install.sh | sh

# --- 7. LAZYGIT ---
print_msg "$MSG_LAZYGIT"
if $SUDO apt-get install -y lazygit 2>/dev/null; then
    echo "$MSG_LAZYGIT_APT"
else
    echo "$MSG_LAZYGIT_BIN"
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    $SUDO install lazygit /usr/local/bin
    rm lazygit lazygit.tar.gz
fi

# --- 8. HOMEBREW ---
print_msg "$MSG_BREW"
if [ "$REAL_USER" == "root" ]; then
    echo -e "${YELLOW}$MSG_BREW_ROOT${NC}"
else
    echo | sudo -u "$REAL_USER" NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME_DIR/.bashrc"
    if [ -f "$HOME_DIR/.config/fish/config.fish" ]; then
        echo 'eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> "$HOME_DIR/.config/fish/config.fish"
    fi
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# --- 9. SECURITY (FAIL2BAN + UFW) ---
print_msg "$MSG_SEC"
SSH_PORT=$($SUDO grep "^Port" /etc/ssh/sshd_config | awk '{print $2}' | head -n 1)
[ -z "$SSH_PORT" ] && SSH_PORT=22
echo "$MSG_SSH_PORT $SSH_PORT"

# Fail2ban
if [ ! -f /etc/fail2ban/jail.local ]; then $SUDO cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local; fi
cat <<EOF | $SUDO tee /etc/fail2ban/jail.local
[DEFAULT]
bantime = 1h
maxretry = 5
[sshd]
enabled = true
port = $SSH_PORT
EOF
$SUDO systemctl restart fail2ban

# UFW Firewall
print_msg "$MSG_FIREWALL"
$SUDO ufw default deny incoming
$SUDO ufw default allow outgoing

# Rules
$SUDO ufw limit "$SSH_PORT"/tcp comment 'SSH'
$SUDO ufw allow 80/tcp comment 'Traefik HTTP'
$SUDO ufw allow 443/tcp comment 'Traefik HTTPS'
$SUDO ufw allow 443/udp comment 'QUIC'

# OPEN PORT 3000 (PUBLICLY ACCESSIBLE)
$SUDO ufw allow 3000/tcp comment 'Dokploy Public Dashboard'

echo "y" | $SUDO ufw enable

# --- 10. SWAP ---
TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
if [ "$TOTAL_MEM" -lt 4000000 ] && [ ! -f /swapfile ]; then
    print_msg "$MSG_SWAP"
    $SUDO fallocate -l 2G /swapfile
    $SUDO chmod 600 /swapfile
    $SUDO mkswap /swapfile
    $SUDO swapon /swapfile
    echo '/swapfile none swap sw 0 0' | $SUDO tee -a /etc/fstab
fi

# --- FIN ---
print_msg "$MSG_DONE"
echo -e "-----------------------------------------------------"
echo -e "$MSG_NOTE_1"
echo -e "$MSG_NOTE_2"
echo -e "$MSG_NOTE_3"
echo -e "-----------------------------------------------------"
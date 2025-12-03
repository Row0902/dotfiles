#!/bin/bash

# --- Configuración ---
REPO_URL="https://github.com/row0902/dotfiles.git"
CONFIG_DIR="$HOME/.config/fish"
TEMP_DIR="$HOME/tmp_dotfiles_installer"
BASH_CUSTOM_FILE="$HOME/.bash_custom"

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Detener el script si hay errores críticos (opcional, recomendado)
# set -e 

# --- 1. Detección ---
detect_env() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) LAZYGIT_ARCH="x86_64" ;;
        aarch64|arm64) LAZYGIT_ARCH="arm64" ;;
        *) LAZYGIT_ARCH="x86_64" ;; 
    esac

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="${NAME:-Linux}"
    else
        OS_NAME="$(uname -s)"
    fi

    if command -v apt-get >/dev/null 2>&1; then
        PM="apt-get"
        # FIX: Noninteractive para evitar ventanas azules en VPS
        INSTALL_CMD="sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq"
        UPDATE_CMD="sudo apt-get update -qq"
        PKG_7Z="p7zip-full"
        PKG_BAT="bat"
        PKG_DEV="jq neovim" # Quitamos tldr si quieres ahorrar espacio, o déjalo.
    elif command -v dnf >/dev/null 2>&1; then
        PM="dnf"
        INSTALL_CMD="sudo dnf install -y"
        UPDATE_CMD="sudo dnf check-update"
        PKG_7Z="p7zip p7zip-plugins"
        PKG_BAT="bat"
        PKG_DEV="jq neovim"
    else
        printf "${RED}❌ Error: Gestor de paquetes no soportado o no encontrado.${NC}\n"
        exit 1
    fi
}

ensure_command() {
    cmd="$1"
    pkg="${2:-$1}"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf "${YELLOW}📦 Instalando $pkg...${NC}\n"
        if [ "$PM" = "apt-get" ] && [ -z "$APT_UPDATED" ]; then 
            $UPDATE_CMD >/dev/null 2>&1
            APT_UPDATED=true
        fi
        $INSTALL_CMD "$pkg" >/dev/null 2>&1
    else
        printf "${GREEN}✅ $cmd ya está instalado.${NC}\n"
    fi
}

ensure_bat() {
    if command -v bat >/dev/null 2>&1; then
        printf "${GREEN}✅ bat ya está instalado.${NC}\n"
    elif command -v batcat >/dev/null 2>&1; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
        printf "${GREEN}✅ batcat enlazado como bat.${NC}\n"
    else
        printf "${YELLOW}📦 Instalando bat...${NC}\n"
        if [ "$PM" = "apt-get" ] && [ -z "$APT_UPDATED" ]; then $UPDATE_CMD >/dev/null 2>&1; APT_UPDATED=true; fi
        $INSTALL_CMD "$PKG_BAT" >/dev/null 2>&1
        if command -v batcat >/dev/null 2>&1; then
             mkdir -p "$HOME/.local/bin"
             ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
        fi
    fi
}

add_line_to_file() {
    line="$1"
    file="$2"
    if [ -f "$file" ]; then
        if ! grep -Fq "$line" "$file"; then
            echo "" >> "$file"
            echo "$line" >> "$file"
            printf "${GREEN}➕ Agregado a $(basename "$file")${NC}\n"
        fi
    fi
}

prepare_repo() {
    if [ -d "$TEMP_DIR" ]; then rm -rf "$TEMP_DIR"; fi
    printf "${BLUE}⬇️  Descargando dotfiles...${NC}\n"
    git clone --quiet "$REPO_URL" "$TEMP_DIR"
}

# --- 2. INSTALACIÓN SHELL & CORE (Solo herramientas binarias) ---
install_shell_core() {
    printf "\n${BLUE}🛠  Configurando 'Host Ligero' (Shell + CLI Tools)...${NC}\n"
    
    # Herramientas básicas del sistema
    ensure_command "git"
    ensure_command "curl"
    ensure_command "unzip"
    ensure_command "7z" "$PKG_7Z"
    
    # Modern Stack (Binarios ligeros que hacen la vida fácil)
    ensure_command "fzf"
    ensure_command "zoxide"
    ensure_command "rg" "ripgrep"
    ensure_bat
    
    # Editor y JSON parser (útil para scripts)
    if [ -n "$PKG_DEV" ]; then
        $INSTALL_CMD $PKG_DEV >/dev/null 2>&1
    fi

    # Eza (ls moderno)
    if ! command -v eza >/dev/null 2>&1; then
        printf "${YELLOW}📦 Instalando eza...${NC}\n"
        # Intenta instalar desde repos oficiales si existe, si no, habría que usar cargo o binary, 
        # pero asumimos que el package manager lo tiene o fallará silenciosamente.
        $INSTALL_CMD eza >/dev/null 2>&1 || printf "${RED}⚠️ No se pudo instalar eza (quizás requiere repo externo).${NC}\n"
    fi

    # Lazygit (Gestión de git visual)
    if ! command -v lazygit >/dev/null 2>&1; then
        printf "${YELLOW}📦 Descargando Lazygit...${NC}\n"
        LG_VER=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VER}_Linux_${LAZYGIT_ARCH}.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit /usr/local/bin
        rm lazygit lazygit.tar.gz
    fi

    # Lazydocker (VITAL para ti: gestión de Docker visual)
    if ! command -v lazydocker >/dev/null 2>&1; then
        printf "${YELLOW}📦 Instalando Lazydocker...${NC}\n"
        curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash >/dev/null 2>&1
    else
        printf "${GREEN}✅ Lazydocker ya está instalado.${NC}\n"
    fi
    
    # Atuin (Historial de comandos sync) - Opcional, pero muy útil
    if ! command -v atuin >/dev/null 2>&1; then
          printf "${YELLOW}📦 Instalando Atuin...${NC}\n"
          curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh >/dev/null 2>&1
    fi
}

# --- 3. CONFIGURACIÓN FISH ---
install_fish_config() {
    # Aseguramos que fish esté instalado primero
    ensure_command "fish"

    prepare_repo
    if [ -d "$CONFIG_DIR" ]; then mv "$CONFIG_DIR" "${CONFIG_DIR}.backup.$(date +%s)"; fi
    mkdir -p "$CONFIG_DIR"
    cp -r "$TEMP_DIR/fish/." "$CONFIG_DIR/"
    chmod -R 755 "$CONFIG_DIR/functions"
    
    # Limpieza de archivos autogenerados viejos
    rm -f "$CONFIG_DIR/functions/_fzf_"* 2>/dev/null
    rm -f "$CONFIG_DIR/functions/fisher.fish" 2>/dev/null

    printf "${BLUE}🔌 Plugins Fisher...${NC}\n"
    if command -v fish >/dev/null 2>&1; then
        # Instalación de Fisher y Plugins
        fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update" >/dev/null 2>&1
        
        CFILE="$CONFIG_DIR/config.fish"
        # Integraciones solo si las herramientas existen
        add_line_to_file 'if status is-interactive; and type -q atuin; atuin init fish | source; end' "$CFILE"
        add_line_to_file 'if type -q zoxide; zoxide init fish | source; end' "$CFILE"
    fi

    FISH_BIN=$(which fish)
    if [ "$SHELL" != "$FISH_BIN" ] && [ -n "$FISH_BIN" ]; then
        # Cambio automático de shell sin preguntar (ideal para setups desatendidos)
        # Ojo: requiere sudo para editar /etc/shells
        if ! grep -q "$FISH_BIN" /etc/shells; then echo "$FISH_BIN" | sudo tee -a /etc/shells >/dev/null; fi
        
        printf "\n${YELLOW}🔄 Cambiando shell por defecto a Fish...${NC}\n"
        sudo chsh -s "$FISH_BIN" $(whoami)
        printf "${GREEN}✅ ¡Listo! Cierra sesión y entra de nuevo.${NC}\n"
    fi
    rm -rf "$TEMP_DIR"
}

# --- MAIN MENU ---
detect_env
USER_NAME=$(whoami)

# Verificación de Docker existente
if command -v docker >/dev/null 2>&1; then
    DOCKER_STATUS="${GREEN}Instalado✅${NC}"
else
    DOCKER_STATUS="${RED}No encontrado (Se usará solo para herramientas CLI)${NC}"
fi

printf "\n${BLUE}=================================================${NC}\n"
printf "${BLUE}   VPS SETUP: HOST LIGERO (DOCKER EDITION)       ${NC}\n"
printf "${BLUE}   👋 $USER_NAME | 💻 $OS_NAME | 🐳 Docker: $DOCKER_STATUS ${NC}\n"
printf "${BLUE}=================================================${NC}\n"

printf "Iniciando configuración...\n"
# Ejecución directa: Instalar herramientas base + Configurar Fish
install_shell_core
install_fish_config

printf "\n${GREEN}✨ Instalación completada. Escribe 'fish' para empezar.${NC}\n"
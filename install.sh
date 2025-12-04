#!/bin/bash

# ==============================================================================
#  DOTFILES INSTALLER - PRODUCTION READY
#  Repo: https://github.com/row0902/dotfiles
# ==============================================================================

# --- Configuración Global ---
set -e  # Detener el script si hay un error
REPO_URL="https://github.com/row0902/dotfiles.git"
CONFIG_DIR="$HOME/.config/fish"
TEMP_DIR="$HOME/tmp_dotfiles_installer_$(date +%s)"
BASH_CUSTOM_FILE="$HOME/.bash_custom"

# Colores y Formato
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Helpers de Logging ---
log_info() { printf "${BLUE}ℹ️  %s${NC}\n" "$1"; }
log_success() { printf "${GREEN}✅ %s${NC}\n" "$1"; }
log_warn() { printf "${YELLOW}⚠️  %s${NC}\n" "$1"; }
log_error() { printf "${RED}❌ %s${NC}\n" "$1"; }

# --- Limpieza Automática (Trap) ---
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# --- 1. Detección del Entorno ---
detect_env() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) LAZYGIT_ARCH="x86_64" ;;
        aarch64|arm64) LAZYGIT_ARCH="arm64" ;;
        *) LAZYGIT_ARCH="x86_64" ;; 
    esac

    # Detectar Sistema Operativo
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="${NAME:-Linux}"
    elif [ "$(uname)" = "Darwin" ]; then
        OS_NAME="macOS"
    else
        OS_NAME="$(uname -s)"
    fi

    # Determinar si necesitamos sudo
    if [ "$EUID" -eq 0 ]; then
        SUDO_CMD=""
    else
        if ! command -v sudo >/dev/null 2>&1; then
            log_error "Este script requiere 'sudo' o ser ejecutado como root."
            exit 1
        fi
        SUDO_CMD="sudo"
    fi

    # Detectar Gestor de Paquetes
    if command -v apt-get >/dev/null 2>&1; then
        PM="apt-get"
        INSTALL_CMD="$SUDO_CMD apt-get install -y -qq"
        UPDATE_CMD="$SUDO_CMD apt-get update -qq"
        PKG_7Z="p7zip-full"
        PKG_BAT="bat"
        PKG_DEV="jq neovim tldr build-essential"
    elif command -v dnf >/dev/null 2>&1; then
        PM="dnf"
        INSTALL_CMD="$SUDO_CMD dnf install -y"
        UPDATE_CMD="$SUDO_CMD dnf check-update"
        PKG_7Z="p7zip p7zip-plugins"
        PKG_BAT="bat"
        PKG_DEV="jq neovim tldr"
    elif command -v pacman >/dev/null 2>&1; then
        PM="pacman"
        INSTALL_CMD="$SUDO_CMD pacman -S --noconfirm"
        UPDATE_CMD="$SUDO_CMD pacman -Sy"
        PKG_7Z="p7zip"
        PKG_BAT="bat"
        PKG_DEV="jq neovim tldr"
    elif command -v brew >/dev/null 2>&1; then
        PM="brew"
        INSTALL_CMD="brew install"
        UPDATE_CMD="brew update"
        PKG_7Z="p7zip"
        PKG_BAT="bat"
        PKG_DEV="jq neovim tldr"
    else
        log_error "Gestor de paquetes no soportado."
        exit 1
    fi
}

# --- Funciones Auxiliares ---
ensure_command() {
    local cmd="$1"
    local pkg="${2:-$1}"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_info "Instalando $pkg..."
        # Actualizar repositorios solo la primera vez en apt
        if [ "$PM" = "apt-get" ] && [ -z "$APT_UPDATED" ]; then 
            $UPDATE_CMD >/dev/null 2>&1
            APT_UPDATED=true
        fi
        $INSTALL_CMD "$pkg" >/dev/null 2>&1 || log_warn "Falló la instalación de $pkg (puede que no esté en los repos)."
    else
        log_success "$cmd ya está instalado."
    fi
}

ensure_bat() {
    if command -v bat >/dev/null 2>&1; then
        log_success "bat ya está instalado."
    elif command -v batcat >/dev/null 2>&1; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
        log_success "batcat enlazado como bat."
    else
        log_info "Instalando bat..."
        [ "$PM" = "apt-get" ] && [ -z "$APT_UPDATED" ] && { $UPDATE_CMD >/dev/null 2>&1; APT_UPDATED=true; }
        $INSTALL_CMD "$PKG_BAT" >/dev/null 2>&1
        if command -v batcat >/dev/null 2>&1; then
             mkdir -p "$HOME/.local/bin"
             ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
        fi
    fi
}

add_line_to_file() {
    local line="$1"
    local file="$2"
    if [ -f "$file" ]; then
        if ! grep -Fq "$line" "$file"; then
            echo "" >> "$file"
            echo "$line" >> "$file"
            log_success "Agregado config a $(basename "$file")"
        fi
    fi
}

prepare_repo() {
    if [ ! -d "$TEMP_DIR" ]; then
        log_info "Descargando dotfiles..."
        git clone --quiet "$REPO_URL" "$TEMP_DIR"
    fi
}

# --- 2. INSTALACIÓN SHELL & CORE ---
install_shell_core() {
    log_info "Configurando Core Tools..."
    
    ensure_command "git"
    ensure_command "curl"
    ensure_command "direnv"
    ensure_command "unzip"
    ensure_command "7z" "$PKG_7Z"
    
    # Modern Stack
    ensure_command "fzf"
    ensure_command "zoxide"
    ensure_command "rg" "ripgrep"
    ensure_command "delta" "git-delta"
    ensure_bat
    
    if [ -n "$PKG_DEV" ]; then
        # shellcheck disable=SC2086
        $INSTALL_CMD $PKG_DEV >/dev/null 2>&1
    fi

    # Eza (Puede fallar en repos viejos)
    if ! command -v eza >/dev/null 2>&1; then
        log_info "Intentando instalar eza..."
        $INSTALL_CMD eza >/dev/null 2>&1 || log_warn "No se pudo instalar eza automáticamente."
    fi

    # Configuración Git Delta
    if command -v delta >/dev/null 2>&1; then
        git config --global core.pager "delta"
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.navigate true
    fi

    # Lazygit (Binario directo si falla package manager)
    if ! command -v lazygit >/dev/null 2>&1; then
        if [ "$PM" = "brew" ]; then
            brew install lazygit
        else
            log_info "Descargando Lazygit..."
            LG_VER=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
            curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VER}_Linux_${LAZYGIT_ARCH}.tar.gz"
            tar xf lazygit.tar.gz lazygit
            $SUDO_CMD install lazygit /usr/local/bin
            rm lazygit lazygit.tar.gz
        fi
    fi

    # Lazydocker
    if ! command -v lazydocker >/dev/null 2>&1; then
        log_info "Instalando Lazydocker..."
        curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash >/dev/null 2>&1
    fi

    # Atuin
    if ! command -v atuin >/dev/null 2>&1; then
         log_info "Instalando Atuin..."
         curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh >/dev/null 2>&1
    fi
}

# --- 3. INSTALACIÓN DEV STACK ---
install_dev_stack() {
    log_info "Configurando Entorno Dev (Node, Python, Docker)..."

    # FNM (Fast Node Manager)
    if ! command -v fnm >/dev/null 2>&1; then
        log_info "Instalando FNM..."
        curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/bin" --skip-shell
    else
        log_success "FNM ya instalado."
    fi

    # UV (Python Manager)
    if ! command -v uv >/dev/null 2>&1; then
        log_info "Instalando UV..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
    else
        log_success "UV ya instalado."
    fi

    # Docker
    if ! command -v docker >/dev/null 2>&1; then
        log_info "Instalando Docker..."
        if [ "$OS_NAME" = "macOS" ]; then
             log_warn "En macOS instala Docker Desktop manualmente."
        else
             curl -fsSL https://get.docker.com | $SUDO_CMD sh
             $SUDO_CMD usermod -aG docker "$(whoami)"
        fi
    else
        log_success "Docker ya instalado."
    fi

    # Zellij
    if ! command -v zellij >/dev/null 2>&1; then
        log_info "Instalando Zellij..."
        bash <(curl -L https://zellij.dev/launch) --install >/dev/null 2>&1 || log_warn "Fallo instalación Zellij"
    fi
}

# --- 4. CONFIGURACIÓN FISH ---
install_fish_config() {
    ensure_command "fish"
    prepare_repo
    
    if [ -d "$CONFIG_DIR" ]; then 
        mv "$CONFIG_DIR" "${CONFIG_DIR}.backup.$(date +%s)"
        log_info "Backup de config fish anterior creado."
    fi
    
    mkdir -p "$CONFIG_DIR"
    cp -r "$TEMP_DIR/fish/." "$CONFIG_DIR/"
    chmod -R 755 "$CONFIG_DIR/functions"
    
    # Limpieza
    rm -f "$CONFIG_DIR/functions/_fzf_"* 2>/dev/null
    rm -f "$CONFIG_DIR/functions/fisher.fish" 2>/dev/null

    log_info "Instalando Plugins Fisher..."
    if command -v fish >/dev/null 2>&1; then
        fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update" >/dev/null 2>&1
        
        CFILE="$CONFIG_DIR/config.fish"
        add_line_to_file 'if status is-interactive; and type -q atuin; atuin init fish | source; end' "$CFILE"
        add_line_to_file 'if type -q direnv; direnv hook fish | source; end' "$CFILE"
    fi

    # Preguntar cambio de shell solo si es interactivo
    FISH_BIN=$(which fish)
    if [ "$SHELL" != "$FISH_BIN" ] && [ -n "$FISH_BIN" ]; then
        local change_shell="n"
        # Si NO hay argumentos (modo interactivo), preguntamos
        if [ $# -eq 0 ]; then
             printf "\n${YELLOW}❓ ¿Usar Fish como default? (s/n): ${NC}"
             # FIX CRÍTICO: Leer de /dev/tty para soportar tuberías
             read -r change_shell < /dev/tty
        elif [ "$1" == "--auto" ]; then
             change_shell="s"
        fi

        if [ "$change_shell" = "s" ]; then
             if ! grep -q "$FISH_BIN" /etc/shells; then echo "$FISH_BIN" | $SUDO_CMD tee -a /etc/shells >/dev/null; fi
             chsh -s "$FISH_BIN"
             log_success "Shell cambiada a Fish. Reinicia tu sesión."
        fi
    fi
}

# --- 5. CONFIGURACIÓN BASH ---
install_bash_config() {
    prepare_repo
    cp "$TEMP_DIR/bash/.bash_custom" "$BASH_CUSTOM_FILE"
    if command -v sed >/dev/null 2>&1; then sed -i 's/\r$//' "$BASH_CUSTOM_FILE"; fi
    mkdir -p "$HOME/.bash_completions_linux"

    if ! grep -q ".bash_custom" "$HOME/.bashrc"; then
        echo "" >> "$HOME/.bashrc"
        echo "if [ -f ~/.bash_custom ]; then source ~/.bash_custom; fi" >> "$HOME/.bashrc"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
    fi

    # Integraciones Bash
    add_line_to_file '[[ -f ~/.atuin/bin/env ]] && source ~/.atuin/bin/env' "$HOME/.bashrc"
    add_line_to_file 'if command -v atuin >/dev/null; then eval "$(atuin init bash)"; fi' "$HOME/.bashrc"
    add_line_to_file 'if command -v direnv >/dev/null; then eval "$(direnv hook bash)"; fi' "$HOME/.bashrc"
    add_line_to_file 'if command -v fnm >/dev/null; then eval "$(fnm env --use-on-cd)"; fi' "$HOME/.bashrc"
    add_line_to_file 'if command -v uv >/dev/null; then eval "$(uv generate-shell-completion bash)"; fi' "$HOME/.bashrc"

    log_success "Bash configurado."
}

# --- MAIN FLOW ---
detect_env

# Argument Parsing (Modo Automatizado)
if [ $# -gt 0 ]; then
    case "$1" in
        --fish) install_shell_core; install_fish_config --auto ;;
        --bash) install_shell_core; install_bash_config ;;
        --dev)  install_dev_stack ;;
        --full) install_shell_core; install_dev_stack; install_fish_config --auto ;;
        *) log_error "Opción desconocida: $1"; exit 1 ;;
    esac
    exit 0
fi

# Modo Interactivo (Menú)
USER_NAME=$(whoami)
printf "\n${BLUE}=================================================${NC}\n"
printf "${BLUE}   DOTFILES INSTALLER v6.0 (Production Ready)    ${NC}\n"
printf "${BLUE}   👋 $USER_NAME | 💻 $OS_NAME | 📦 $PM ${NC}\n"
printf "${BLUE}=================================================${NC}\n"

printf "Selecciona una opción:\n"
printf "  ${GREEN}1)${NC} 🐟 Configurar Solo Fish Shell (Incluye Core Tools)\n"
printf "  ${GREEN}2)${NC} 🐚 Configurar Solo Bash Shell (Incluye Core Tools)\n"
printf "  ${GREEN}3)${NC} 🛠️  Instalar Solo Entorno Dev (Docker, Node, Python)\n"
printf "  ${GREEN}4)${NC} 🚀 Instalación Completa (Fish + Dev Stack)\n"
printf "Opción: "

# FIX CRÍTICO: Forzar lectura desde la terminal real
read -r opcion < /dev/tty

case "$opcion" in
    1) install_shell_core; install_fish_config ;;
    2) install_shell_core; install_bash_config ;;
    3) install_dev_stack ;;
    4) install_shell_core; install_dev_stack; install_fish_config ;;
    *) log_error "Opción inválida."; exit 1 ;;
esac
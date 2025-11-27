#!/bin/sh

# --- Configuración ---
REPO_URL="https://github.com/row0902/dotfiles.git"
CONFIG_DIR="$HOME/.config/fish"
TEMP_DIR="$HOME/tmp_dotfiles_installer"
BASH_CUSTOM_FILE="$HOME/.bash_custom"

# Colores (Output Visual)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- 1. Detección del Entorno ---
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
    elif [ "$(uname)" = "Darwin" ]; then
        OS_NAME="macOS"
    else
        OS_NAME="$(uname -s)"
    fi

    if command -v apt-get >/dev/null 2>&1; then
        PM="apt-get"
        INSTALL_CMD="sudo apt-get install -y -qq"
        UPDATE_CMD="sudo apt-get update -qq"
        PKG_7Z="p7zip-full"
        PKG_BAT="bat"
        PKG_DEV="jq neovim tldr" # Recomendaciones para Debian
    elif command -v dnf >/dev/null 2>&1; then
        PM="dnf"
        INSTALL_CMD="sudo dnf install -y"
        UPDATE_CMD="sudo dnf check-update"
        PKG_7Z="p7zip p7zip-plugins"
        PKG_BAT="bat"
        PKG_DEV="jq neovim tldr"
    elif command -v pacman >/dev/null 2>&1; then
        PM="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"
        UPDATE_CMD="sudo pacman -Sy"
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
        printf "${RED}❌ Error: No se encontró un gestor de paquetes soportado.${NC}\n"
        exit 1
    fi
}

# --- Funciones Auxiliares ---

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
            printf "${GREEN}➕ Configuración agregada a $(basename "$file")${NC}\n"
        fi
    fi
}

prepare_repo() {
    if [ -d "$TEMP_DIR" ]; then rm -rf "$TEMP_DIR"; fi
    printf "${BLUE}⬇️  Descargando dotfiles...${NC}\n"
    git clone --quiet "$REPO_URL" "$TEMP_DIR"
}

# --- HERRAMIENTAS BASE ---
install_core_tools() {
    printf "\n${BLUE}🛠  Verificando herramientas base...${NC}\n"
    
    ensure_command "git"
    ensure_command "curl"
    ensure_command "direnv"
    
    # Compresión
    ensure_command "unzip"
    ensure_command "unrar"
    ensure_command "7z" "$PKG_7Z"
    
    # Modern Stack (Rust)
    ensure_command "fzf"
    ensure_command "zoxide"
    ensure_command "rg" "ripgrep"
    ensure_command "delta" "git-delta"
    ensure_bat
    
    # Recomendaciones extra (jq, tldr, neovim)
    if [ -n "$PKG_DEV" ]; then
        printf "${BLUE}🎁 Instalando recomendaciones (jq, tldr, nvim)...${NC}\n"
        # Instalamos sin verificar uno por uno para velocidad
        $INSTALL_CMD $PKG_DEV >/dev/null 2>&1
    fi

    # Eza
    if ! command -v eza >/dev/null 2>&1; then
        printf "${YELLOW}📦 Instalando eza...${NC}\n"
        $INSTALL_CMD eza >/dev/null 2>&1 || printf "${RED}⚠️ No se pudo instalar eza (se usará ls).${NC}\n"
    fi

    # Configuración Delta
    if command -v delta >/dev/null 2>&1; then
        git config --global core.pager "delta"
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.navigate true
    fi

    # Lazygit
    if ! command -v lazygit >/dev/null 2>&1; then
        if [ "$PM" = "brew" ]; then
            brew install lazygit
        else
            printf "${YELLOW}📦 Descargando Lazygit...${NC}\n"
            LG_VER=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
            curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VER}_Linux_${LAZYGIT_ARCH}.tar.gz"
            tar xf lazygit.tar.gz lazygit
            sudo install lazygit /usr/local/bin
            rm lazygit lazygit.tar.gz
        fi
    fi

    # Lazydocker
    if ! command -v lazydocker >/dev/null 2>&1; then
        printf "${YELLOW}📦 Instalando Lazydocker...${NC}\n"
        curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash >/dev/null 2>&1
    fi

    # Atuin
    if ! command -v atuin >/dev/null 2>&1; then
         printf "${YELLOW}📦 Instalando Atuin...${NC}\n"
         curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh >/dev/null 2>&1
    fi
}

# --- ENTORNO DE DESARROLLO (DEV STACK) ---
install_dev_stack() {
    printf "\n${BLUE}🚀 Configurando Entorno de Desarrollo (Docker, Node, Python)...${NC}\n"

    # 1. FNM (Node.js)
    if ! command -v fnm >/dev/null 2>&1; then
        printf "${YELLOW}📦 Instalando FNM (Node Manager)...${NC}\n"
        curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$HOME/.local/bin" --skip-shell
    else
        printf "${GREEN}✅ FNM ya está instalado.${NC}\n"
    fi

    # 2. UV (Python)
    if ! command -v uv >/dev/null 2>&1; then
        printf "${YELLOW}📦 Instalando UV (Python Manager)...${NC}\n"
        curl -LsSf https://astral.sh/uv/install.sh | sh
    else
        printf "${GREEN}✅ UV ya está instalado.${NC}\n"
    fi

    # 3. Docker
    if ! command -v docker >/dev/null 2>&1; then
        printf "${YELLOW}🐳 Docker no detectado. Intentando instalar...${NC}\n"
        if [ "$OS_NAME" = "macOS" ]; then
             printf "${RED}⚠️  En macOS, por favor instala 'Docker Desktop' manualmente.${NC}\n"
        else
             # Script oficial de instalación de Docker para Linux
             curl -fsSL https://get.docker.com | sudo sh
             # Agregar usuario al grupo docker para no usar sudo
             sudo usermod -aG docker $(whoami)
             printf "${GREEN}✅ Docker instalado. (Nota: Puede requerir reiniciar sesión).${NC}\n"
        fi
    else
        printf "${GREEN}✅ Docker ya está instalado.${NC}\n"
    fi

    # 4. Zellij (Recomendación)
    if ! command -v zellij >/dev/null 2>&1; then
        printf "${YELLOW}📦 Instalando Zellij (Multiplexer)...${NC}\n"
        # Intenta instalar con cargo si existe, sino descarga binario
        if command -v cargo >/dev/null 2>&1; then
            cargo install zellij --locked
        else
            bash <(curl -L zellij.dev/launch) --install >/dev/null 2>&1
        fi
    fi
}

# --- FISH ---
install_fish_config() {
    prepare_repo
    if [ -d "$CONFIG_DIR" ]; then mv "$CONFIG_DIR" "${CONFIG_DIR}.backup.$(date +%s)"; fi
    mkdir -p "$CONFIG_DIR"
    cp -r "$TEMP_DIR/fish/." "$CONFIG_DIR/"
    chmod -R 755 "$CONFIG_DIR/functions"
    rm -f "$CONFIG_DIR/functions/_fzf_"* 2>/dev/null
    rm -f "$CONFIG_DIR/functions/fisher.fish" 2>/dev/null

    printf "${BLUE}🔌 Instalando plugins Fisher...${NC}\n"
    if command -v fish >/dev/null 2>&1; then
        fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update" >/dev/null 2>&1
        
        # Hooks
        CFILE="$CONFIG_DIR/config.fish"
        add_line_to_file 'if status is-interactive; and type -q atuin; atuin init fish | source; end' "$CFILE"
        add_line_to_file 'if type -q direnv; direnv hook fish | source; end' "$CFILE"
    fi

    FISH_BIN=$(which fish)
    if [ "$SHELL" != "$FISH_BIN" ] && [ -n "$FISH_BIN" ]; then
        printf "\n${YELLOW}❓ ¿Establecer Fish como default? (s/n): ${NC}"
        read choice
        if [ "$choice" = "s" ]; then
             if ! grep -q "$FISH_BIN" /etc/shells; then echo "$FISH_BIN" | sudo tee -a /etc/shells >/dev/null; fi
             chsh -s "$FISH_BIN"
             printf "${GREEN}✅ Shell cambiada a Fish. Reinicia sesión.${NC}\n"
        fi
    fi
    rm -rf "$TEMP_DIR"
}

# --- BASH ---
install_bash_config() {
    prepare_repo
    cp "$TEMP_DIR/bash/.bash_custom" "$BASH_CUSTOM_FILE"
    if command -v sed >/dev/null 2>&1; then sed -i 's/\r$//' "$BASH_CUSTOM_FILE"; fi
    mkdir -p "$HOME/.bash_completions_linux"

    if ! grep -q ".bash_custom" "$HOME/.bashrc"; then
        echo "" >> "$HOME/.bashrc"
        echo "# --- Custom Bash Config ---" >> "$HOME/.bashrc"
        echo "if [ -f ~/.bash_custom ]; then source ~/.bash_custom; fi" >> "$HOME/.bashrc"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
    fi

    add_line_to_file '[[ -f ~/.atuin/bin/env ]] && source ~/.atuin/bin/env' "$HOME/.bashrc"
    add_line_to_file 'if command -v atuin >/dev/null; then eval "$(atuin init bash)"; fi' "$HOME/.bashrc"
    add_line_to_file 'if command -v direnv >/dev/null; then eval "$(direnv hook bash)"; fi' "$HOME/.bashrc"
    
    # Hooks para Dev Tools en Bash
    add_line_to_file 'if command -v fnm >/dev/null; then eval "$(fnm env --use-on-cd)"; fi' "$HOME/.bashrc"
    add_line_to_file 'if command -v uv >/dev/null; then eval "$(uv generate-shell-completion bash)"; fi' "$HOME/.bashrc"

    rm -rf "$TEMP_DIR"
    printf "${GREEN}🎉 Bash configurado.${NC}\n"
}

# --- MAIN ---
detect_env
USER_NAME=$(whoami)

# Header Informativo
printf "\n${BLUE}=================================================${NC}\n"
printf "${BLUE}   DOTFILES INSTALLER v4.0 (Dev Stack)           ${NC}\n"
printf "${BLUE}   👋 Usuario: ${GREEN}$USER_NAME${NC}\n"
printf "${BLUE}   💻 Sistema: ${GREEN}$OS_NAME${NC}\n"
printf "${BLUE}   📦 Gestor:  ${GREEN}$PM${NC}\n"
printf "${BLUE}=================================================${NC}\n"

printf "Selecciona entorno:\n"
printf "  ${GREEN}0)${NC} Fish (Full Dev Stack: Docker, Node, Python)\n"
printf "  ${GREEN}1)${NC} Bash (Full Dev Stack: Docker, Node, Python)\n"
printf "Opción: "
read opcion

case "$opcion" in
    0) install_core_tools; install_dev_stack; install_fish_config ;;
    1) install_core_tools; install_dev_stack; install_bash_config ;;
    *) echo "Opción inválida."; exit 1 ;;
esac
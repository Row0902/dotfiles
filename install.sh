#!/bin/sh

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

# --- Funciones de Ayuda ---

# Verifica si un comando existe. Si no, intenta instalarlo.
ensure_command() {
    cmd="$1"
    pkg="${2:-$1}" # Si se da un segundo argumento, es el nombre del paquete en apt
    
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf "${YELLOW}📦 Instalando $pkg...${NC}\n"
        sudo apt-get update -qq >/dev/null 2>&1
        sudo apt-get install -y -qq "$pkg"
    else
        printf "${GREEN}✅ $cmd ya está instalado.${NC}\n"
    fi
}

# Función especial para 'bat' que en Debian/Ubuntu se llama 'batcat'
ensure_bat() {
    if command -v bat >/dev/null 2>&1; then
        printf "${GREEN}✅ bat ya está instalado.${NC}\n"
    elif command -v batcat >/dev/null 2>&1; then
        printf "${GREEN}✅ batcat ya está instalado. Creando enlace 'bat'...${NC}\n"
        # Crear enlace simbólico seguro en ~/.local/bin
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
    else
        printf "${YELLOW}📦 Instalando bat...${NC}\n"
        sudo apt-get update -qq >/dev/null 2>&1
        sudo apt-get install -y -qq bat
        # Verificar si se instaló como batcat y enlazar
        if command -v batcat >/dev/null 2>&1; then
             mkdir -p "$HOME/.local/bin"
             ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
        fi
    fi
}

prepare_repo() {
    if [ -d "$TEMP_DIR" ]; then rm -rf "$TEMP_DIR"; fi
    printf "${BLUE}⬇️  Descargando configuración...${NC}\n"
    git clone --quiet "$REPO_URL" "$TEMP_DIR"
}

# --- INSTALACIÓN DE FISH ---
install_fish_config() {
    prepare_repo
    ensure_command "curl"
    
    # Backup y Copia
    if [ -d "$CONFIG_DIR" ]; then 
        printf "${YELLOW}🧹 Respaldando configuración anterior de Fish...${NC}\n"
        mv "$CONFIG_DIR" "${CONFIG_DIR}.backup.$(date +%s)"
    fi
    mkdir -p "$CONFIG_DIR"
    
    printf "${BLUE}📂 Copiando archivos de Fish...${NC}\n"
    cp -r "$TEMP_DIR/fish/." "$CONFIG_DIR/"
    chmod -R 755 "$CONFIG_DIR/functions"

    # Limpieza preventiva de conflictos
    rm -f "$CONFIG_DIR/functions/_fzf_"* 2>/dev/null
    rm -f "$CONFIG_DIR/functions/_autopair_"* 2>/dev/null
    rm -f "$CONFIG_DIR/functions/fisher.fish" 2>/dev/null
    rm -f "$CONFIG_DIR/completions/fisher.fish" 2>/dev/null

    printf "${BLUE}🔌 Instalando plugins con Fisher...${NC}\n"
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update"

    # VERIFICACIÓN DE SHELL POR DEFECTO
    CURRENT_SHELL=$(grep "^$(whoami):" /etc/passwd | cut -d: -f7)
    FISH_BIN=$(which fish)

    if [ "$CURRENT_SHELL" = "$FISH_BIN" ]; then
        printf "${GREEN}✅ Fish ya es tu shell por defecto.${NC}\n"
    else
        printf "\n${YELLOW}❓ Configuración final:${NC}\n"
        printf "  ¿Deseas establecer Fish como tu terminal por defecto? (s/n): "
        read choice
        case "$choice" in
            [sS]|[yY])
                if ! grep -q "$FISH_BIN" /etc/shells; then
                    echo "$FISH_BIN" | sudo tee -a /etc/shells > /dev/null
                fi
                chsh -s "$FISH_BIN"
                printf "${GREEN}✅ Fish establecida como default. Reinicia tu sesión.${NC}\n"
                ;;
            *)
                printf "${BLUE}ℹ️  Omitido.${NC}\n"
                ;;
        esac
    fi
    rm -rf "$TEMP_DIR"
}

# --- INSTALACIÓN DE BASH ---
install_bash_config() {
    prepare_repo
    
    printf "${BLUE}📂 Instalando .bash_custom...${NC}\n"
    cp "$TEMP_DIR/bash/.bash_custom" "$BASH_CUSTOM_FILE"
    
    # Corrección de saltos de línea Windows -> Unix
    if command -v sed >/dev/null 2>&1; then
        sed -i 's/\r$//' "$BASH_CUSTOM_FILE"
        printf "${GREEN}🔧 Formato de archivo corregido (Windows -> Unix).${NC}\n"
    fi

    mkdir -p "$HOME/.bash_completions_linux"

    if ! grep -q ".bash_custom" "$HOME/.bashrc"; then
        printf "\n# --- Custom Bash Config ---\n" >> "$HOME/.bashrc"
        printf "if [ -f ~/.bash_custom ]; then\n" >> "$HOME/.bashrc"
        printf "    source ~/.bash_custom\n" >> "$HOME/.bashrc"
        printf "fi\n" >> "$HOME/.bashrc"
        # Asegurar que ~/.local/bin esté en el PATH para bat/zoxide
        printf "export PATH=\"\$HOME/.local/bin:\$PATH\"\n" >> "$HOME/.bashrc"
        printf "${GREEN}✅ Configuración añadida a .bashrc${NC}\n"
    else
        printf "${GREEN}✅ .bashrc ya estaba configurado.${NC}\n"
    fi
    
    rm -rf "$TEMP_DIR"
    printf "${GREEN}🎉 Bash configurado. Ejecuta 'source ~/.bashrc' para ver cambios.${NC}\n"
}

# --- INSTALACIÓN DE HERRAMIENTAS COMUNES ---
install_tools() {
    printf "\n${BLUE}🛠  Instalando herramientas modernas (Rust)...${NC}\n"
    ensure_command "git"
    ensure_command "curl"
    ensure_command "fzf"
    ensure_command "zoxide"
    ensure_command "rg" "ripgrep"
    ensure_bat  # Instala bat o batcat y lo vincula
    
    # Eza es más nuevo, intentamos instalarlo, si falla no rompemos el script
    if ! command -v eza >/dev/null 2>&1; then
        printf "${YELLOW}📦 Intentando instalar eza (ls moderno)...${NC}\n"
        sudo apt-get install -y -qq eza 2>/dev/null || printf "${RED}⚠️ No se pudo instalar 'eza' automáticamente (quizás tu distro es antigua). Se usará 'ls'.${NC}\n"
    else
        printf "${GREEN}✅ eza ya está instalado.${NC}\n"
    fi
}

# --- MENÚ PRINCIPAL ---
clear
printf "${BLUE}=========================================${NC}\n"
printf "${BLUE}   INSTALADOR DE DOTFILES (Rowell)       ${NC}\n"
printf "${BLUE}=========================================${NC}\n"
printf "Selecciona qué entorno deseas configurar:\n\n"
printf "  ${GREEN}0)${NC} Bash (Personalizado + Tools)\n"
printf "  ${GREEN}1)${NC} Fish (Completo + Tools)\n\n"
printf "Opción: "
read opcion

case "$opcion" in
    1)
        printf "\n${BLUE}🚀 Iniciando instalación de Fish...${NC}\n"
        install_tools
        install_fish_config
        ;;
    0)
        printf "\n${BLUE}🚀 Iniciando instalación de Bash...${NC}\n"
        install_tools
        install_bash_config
        ;;
    *)
        printf "\n${RED}❌ Opción no válida.${NC}\n"
        exit 1
        ;;
esac
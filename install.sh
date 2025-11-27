# --- Configuración ---
REPO_URL="https://github.com/row0902/dotfiles.git"
CONFIG_DIR="$HOME/.config/fish"
TEMP_DIR="$HOME/tmp_dotfiles_installer"

# Colores (ANSI estándar)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Funciones de Ayuda ---

# Función para verificar e instalar dependencias solo si faltan
ensure_command() {
    cmd="$1"
    if command -v "$cmd" >/dev/null 2>&1; then
        printf "${GREEN}✅ $cmd ya está instalado.${NC}\n"
    else
        printf "${YELLOW}📦 Instalando $cmd...${NC}\n"
        sudo apt-get update -qq >/dev/null 2>&1
        sudo apt-get install -y -qq "$cmd"
    fi
}

install_fish_config() {
    printf "${BLUE}⬇️  Descargando configuración...${NC}\n"
    # Limpieza previa del temp
    if [ -d "$TEMP_DIR" ]; then rm -rf "$TEMP_DIR"; fi
    
    git clone --quiet "$REPO_URL" "$TEMP_DIR"

    # Backup
    if [ -d "$CONFIG_DIR" ]; then
        printf "${YELLOW}🧹 Respaldando configuración anterior...${NC}\n"
        mv "$CONFIG_DIR" "${CONFIG_DIR}.backup.$(date +%s)"
    fi

    mkdir -p "$CONFIG_DIR"

    printf "${BLUE}📂 Copiando archivos...${NC}\n"
    cp -r "$TEMP_DIR/fish/." "$CONFIG_DIR/"
    chmod -R 755 "$CONFIG_DIR/functions"

    # --- LIMPIEZA CRÍTICA DE CONFLICTOS ---
    # Borramos archivos que Fisher intenta generar para evitar el error "File exists"
    printf "${YELLOW}🧹 Limpiando conflictos de plugins...${NC}\n"
    rm -f "$CONFIG_DIR/functions/_fzf_"* 2>/dev/null
    rm -f "$CONFIG_DIR/functions/_autopair_"* 2>/dev/null
    rm -f "$CONFIG_DIR/functions/fisher.fish" 2>/dev/null
    rm -f "$CONFIG_DIR/completions/fisher.fish" 2>/dev/null

    printf "${BLUE}🔌 Instalando plugins con Fisher...${NC}\n"
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update"

    # Configuración de Shell por defecto
    printf "\n${YELLOW}❓ Configuración final:${NC}\n"
    printf "  ¿Deseas establecer Fish como tu terminal por defecto? (s/n): "
    
    # Lectura compatible con POSIX
    read choice
    
    case "$choice" in
        [sS]|[yY])
            FISH_PATH=$(which fish)
            if [ -z "$FISH_PATH" ]; then
                printf "${RED}❌ Error: No se encontró la ruta de fish.${NC}\n"
            else
                # Verificar si está en /etc/shells
                if ! grep -q "$FISH_PATH" /etc/shells; then
                    printf "  Añadiendo Fish a shells permitidas...\n"
                    echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
                fi
                
                # Cambiar shell
                printf "  Cambiando shell a $FISH_PATH...\n"
                chsh -s "$FISH_PATH"
                printf "${GREEN}✅ Fish establecida como default. Reinicia tu sesión.${NC}\n"
            fi
            ;;
        *)
            printf "${BLUE}ℹ️  Omitido. Puedes probarla escribiendo 'fish'.${NC}\n"
            ;;
    esac

    rm -rf "$TEMP_DIR"
    printf "${GREEN}🎉 Instalación de Fish completada.${NC}\n"
}

# --- MENÚ PRINCIPAL ---
clear
printf "${BLUE}=========================================${NC}\n"
printf "${BLUE}   INSTALADOR DE DOTFILES (Rowell)       ${NC}\n"
printf "${BLUE}=========================================${NC}\n"
printf "Selecciona qué entorno deseas configurar:\n\n"
printf "  ${GREEN}0)${NC} Bash (Personalizado) - ${YELLOW}Próximamente${NC}\n"
printf "  ${GREEN}1)${NC} Fish (Completo)\n\n"
printf "Opción: "
read opcion

case "$opcion" in
    1)
        printf "\n${BLUE}🚀 Iniciando instalación de Fish...${NC}\n"
        ensure_command "git"
        ensure_command "fish"
        ensure_command "curl"
        install_fish_config
        ;;
    0)
        printf "\n${YELLOW}🚧 La configuración de Bash estará disponible pronto.${NC}\n"
        ;;
    *)
        printf "\n${RED}❌ Opción no válida.${NC}\n"
        exit 1
        ;;
esac
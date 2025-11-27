# --- Configuración ---
REPO_URL="https://github.com/row0902/dotfiles.git"
CONFIG_DIR="$HOME/.config/fish"
TEMP_DIR="$HOME/tmp_dotfiles_installer"

# Colores para que se vea profesional
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Iniciando instalador de entorno Fish...${NC}"

# 1. Verificar e instalar dependencias básicas (Git y Fish)
# Esto suele requerir sudo, pero es necesario para que funcione.
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}📦 Git no encontrado. Instalando...${NC}"
    sudo apt update && sudo apt install -y git
fi

if ! command -v fish &> /dev/null; then
    echo -e "${YELLOW}🐟 Fish no encontrado. Instalando...${NC}"
    sudo apt-add-repository ppa:fish-shell/release-3 -y
    sudo apt update
    sudo apt install -y fish
fi

# 2. Clonar el repositorio (siempre fresco)
if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi
echo -e "${BLUE}⬇️  Descargando configuración desde GitHub...${NC}"
git clone --quiet "$REPO_URL" "$TEMP_DIR"

# 3. Backup inteligente
if [ -d "$CONFIG_DIR" ]; then
    echo -e "${YELLOW}🧹 Respaldando configuración anterior...${NC}"
    mv "$CONFIG_DIR" "${CONFIG_DIR}.backup.$(date +%s)"
fi

# Crear estructura limpia
mkdir -p "$CONFIG_DIR"

# 4. Copiar archivos (Manejando tu estructura de subcarpeta 'fish')
echo -e "${BLUE}📂 Aplicando configuraciones...${NC}"

# Copiamos todo el contenido de la carpeta 'fish' del repo a ~/.config/fish
cp -r "$TEMP_DIR/fish/." "$CONFIG_DIR/"

# Asegurar permisos correctos en funciones (por si acaso)
chmod -R 755 "$CONFIG_DIR/functions"

# 5. Instalar Fisher y Plugins
echo -e "${BLUE}🔌 Instalando gestor de plugins Fisher...${NC}"
fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher update"

# 6. Interacción: Preguntar por la Shell por defecto (LO QUE PEDISTE)
echo ""
echo -e "${YELLOW}❓ Configuración final:${NC}"
read -p "  ¿Deseas establecer Fish como tu terminal por defecto? (s/n): " respuesta

if [[ "$respuesta" =~ ^[Ss]$ ]]; then
    FISH_PATH=$(which fish)
    
    # Añadir a /etc/shells si no existe (requiere sudo)
    if ! grep -q "$FISH_PATH" /etc/shells; then
        echo "  Añadiendo Fish a shells permitidas..."
        echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
    fi
    
    # Cambiar shell
    chsh -s "$FISH_PATH"
    echo -e "${GREEN}✅ Fish establecida como default. Reinicia tu sesión.${NC}"
else
    echo -e "${BLUE}ℹ️  Omitido. Puedes probarla escribiendo 'fish'.${NC}"
fi

# Limpieza
rm -rf "$TEMP_DIR"
echo -e "${GREEN}🎉 ¡Instalación completada con éxito!${NC}"
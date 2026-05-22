#!/bin/bash
# ─── Bootstrap ──────────────────────────────────────────────────────────
# Configura una máquina nueva después de chezmoi init --apply.
#
# Uso:
#   (chezmoi source-path)/scripts/bootstrap.sh
#   # o si estás en el repo:
#   ./scripts/bootstrap.sh
#
# Hace:
#   1. brew bundle (instala todas las tools del Brewfile)
#   2. Git identidad local (name, email) si no existe ~/.gitconfig.local
#   3. Fish como shell por defecto (chsh)
#   4. Detecta / importa / genera claves SSH
#   5. gh auth login
#   6. Cambia remote a SSH
#
# Es IDEMPOTENTE — podés correrlo varias veces sin romper nada.
# ────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Colores ────────────────────────────────────────────────────────────
BOLD='\033[1m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

info()  { echo -e "${BLUE}→${NC} $*"; }
ok()    { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; }

# Detectar directorio del repo
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BOLD}
╔══════════════════════════════════════════╗
║      Bienvenido al bootstrap de 🏡       ║
║  Configurando tu máquina nueva...        ║
╚══════════════════════════════════════════╝${NC}
"

# ═══════════════════════════════════════════════════════════════════════
# FASE 1: Homebrew
# ═══════════════════════════════════════════════════════════════════════

phase_1_install_tools() {
    info "Phase 1: Installing tools"

    # Si run_once_ ya instaló (chezmoi apply ejecutado antes), skip
    if command -v fish &>/dev/null && command -v starship &>/dev/null; then
        info "Tools already installed (run_once_ completed), skipping Phase 1"
        return 0
    fi

    # Fallback: correr brew bundle si estamos antes del primer apply
    if ! command -v brew &>/dev/null; then
        info "Instalando Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        ok "Homebrew instalado"
    else
        ok "Homebrew ya instalado"
    fi

    info "Instalando tools via brew bundle..."
    brew bundle --file "$REPO_DIR/Brewfile" --no-lock || warn "brew bundle tuvo issues (podés re-ejecutarlo)"
    ok "Tools instaladas"
}

phase_1_install_tools

# ═══════════════════════════════════════════════════════════════════════
# FASE 2: Git identidad local
# ═══════════════════════════════════════════════════════════════════════

info "Fase 2/6: Git identidad local"

GITCONFIG_LOCAL="$HOME/.gitconfig.local"
if [ -f "$GITCONFIG_LOCAL" ] && grep -q "\[user\]" "$GITCONFIG_LOCAL" 2>/dev/null; then
    ok "~/.gitconfig.local ya existe con identidad configurada"
else
    info "Configurando identidad git..."
    echo ""
    read -rp "  Nombre completo: " git_name
    read -rp "  Email: " git_email
    read -rp "  GPG signing key (vacío si no tenés): " git_key
    echo ""

    cat > "$GITCONFIG_LOCAL" <<-EOF
[user]
    name = $git_name
    email = $git_email
EOF
    if [ -n "$git_key" ]; then
        echo "    signingkey = $git_key" >> "$GITCONFIG_LOCAL"
    fi
    ok "~/.gitconfig.local creado"
fi

# ═══════════════════════════════════════════════════════════════════════
# FASE 2: Fish shell
# ═══════════════════════════════════════════════════════════════════════

info "Fase 3/6: Fish shell"

FISH_PATH="$(command -v fish || echo "")"
if [ -z "$FISH_PATH" ]; then
    warn "Fish no está instalado. Primero corré: brew bundle --file $REPO_DIR/Brewfile"
else
    if [ "$SHELL" != "$FISH_PATH" ]; then
        info "Cambiando shell por defecto a Fish..."
        if chsh -s "$FISH_PATH" 2>/dev/null; then
            ok "Shell cambiado a Fish (efectivo al próximo login)"
        else
            warn "No se pudo cambiar la shell. Probá: chsh -s $FISH_PATH"
        fi
    else
        ok "Fish ya es el shell por defecto"
    fi
fi

# ═══════════════════════════════════════════════════════════════════════
# FASE 3: SSH
# ═══════════════════════════════════════════════════════════════════════

info "Fase 4/6: SSH"

detect_ssh_keys() {
    local dir="$1"
    for f in "$dir"/*; do
        [ -f "$f" ] || continue
        case "${f##*/}" in
            *.pub|known_hosts|authorized_keys|config|environment) continue ;;
        esac
        if file "$f" | grep -qi "private key"; then
            echo "$f"
        fi
    done
}

ssh_keys=()
while IFS= read -r -d '' key; do
    ssh_keys+=("$key")
done < <(detect_ssh_keys "$HOME/.ssh" | tr '\n' '\0')

if [ ${#ssh_keys[@]} -gt 0 ]; then
    ok "Claves SSH encontradas en ~/.ssh/:"
    for key in "${ssh_keys[@]}"; do
        echo "   • $key"
    done
    echo ""
    read -rp "¿Usar estas claves y cambiar remote a SSH? (S/n): " choice
    if [[ ! "$choice" =~ ^[Nn] ]]; then
        setup_ssh_remote=true
    fi
else
    info "No se encontraron claves SSH en ~/.ssh/"

    # WSL: buscar en Windows
    if grep -qi microsoft /proc/version 2>/dev/null; then
        info "Ejecutando en WSL"

        # Buscar usuario de Windows
        win_user=$(ls /mnt/c/Users/ 2>/dev/null | grep -v "^Public$\|^Default$" | head -1)
        win_ssh_dir="/mnt/c/Users/$win_user/.ssh"

        if [ -n "$win_user" ] && [ -d "$win_ssh_dir" ]; then
            win_keys=()
            while IFS= read -r -d '' key; do
                win_keys+=("$key")
            done < <(detect_ssh_keys "$win_ssh_dir" | tr '\n' '\0')

            if [ ${#win_keys[@]} -gt 0 ]; then
                echo ""
                warn "Se encontraron claves SSH en Windows ($win_ssh_dir):"
                for key in "${win_keys[@]}"; do
                    echo "   • $key"
                done
                echo ""
                read -rp "¿Importar estas claves a WSL? (S/n): " import_choice
                if [[ ! "$import_choice" =~ ^[Nn] ]]; then
                    mkdir -p "$HOME/.ssh"
                    for key in "${win_keys[@]}"; do
                        cp "$key" "$HOME/.ssh/"
                        chmod 600 "$HOME/.ssh/$(basename "$key")"
                        pub_key="${key}.pub"
                        if [ -f "$pub_key" ]; then
                            cp "$pub_key" "$HOME/.ssh/"
                            chmod 644 "$HOME/.ssh/$(basename "$pub_key")"
                        fi
                        ok "Importada: $(basename "$key")"
                    done
                    setup_ssh_remote=true
                fi
            fi
        fi
    fi

    # Si aún no hay claves, ofrecer generar
    if [ "${#ssh_keys[@]}" -eq 0 ] && [ "${#win_keys[@]}" -eq 0 ]; then
        echo ""
        read -rp "¿Generar nueva clave SSH ed25519? (S/n): " gen_choice
        if [[ ! "$gen_choice" =~ ^[Nn] ]]; then
            read -rp "Email para la clave SSH: " ssh_email
            ssh-keygen -t ed25519 -C "$ssh_email"
            eval "$(ssh-agent -s)"
            ssh-add "$HOME/.ssh/id_ed25519"
            ok "Clave SSH generada"

            # gh auth + add key
            if command -v gh &>/dev/null; then
                info "Autenticando en GitHub para agregar la clave..."
                gh auth login
                gh ssh-key add "$HOME/.ssh/id_ed25519.pub"
                ok "Clave SSH agregada a GitHub"
            fi

            setup_ssh_remote=true
        fi
    fi
fi

# ═══════════════════════════════════════════════════════════════════════
# FASE 4: GitHub Auth
# ═══════════════════════════════════════════════════════════════════════

info "Fase 5/6: GitHub CLI"

if command -v gh &>/dev/null; then
    if ! gh auth status &>/dev/null; then
        info "Autenticando gh CLI..."
        gh auth login
        ok "gh CLI autenticado"
    else
        ok "gh CLI ya autenticado"
    fi
else
    warn "gh no está instalado, omitiendo autenticación"
fi

# ═══════════════════════════════════════════════════════════════════════
# FASE 5: Remote SSH
# ═══════════════════════════════════════════════════════════════════════

info "Fase 6/6: Remote"

if [ "${setup_ssh_remote:-false}" = true ]; then
    remote_url="$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || echo "")"
    if echo "$remote_url" | grep -q "^https://"; then
        info "Cambiando remote de HTTPS a SSH..."
        git -C "$REPO_DIR" remote set-url origin git@github.com:Row0902/dotfiles.git
        ok "Remote cambiado a SSH"
    else
        ok "Remote ya está en SSH"
    fi
fi

# ═══════════════════════════════════════════════════════════════════════
# FIN
# ═══════════════════════════════════════════════════════════════════════

echo ""
echo -e "${GREEN}${BOLD}✓ Bootstrap completo.${NC}"
echo ""
echo "  Recordá:"
echo "  • Los cambios de shell son efectivos al próximo login (o exec fish)"
echo "  • Git config local se configuró con chezmoi prompt"
echo "  • Cualquier fase podés re-ejecutarla con: $0"
echo ""

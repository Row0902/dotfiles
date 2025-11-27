# NOTA: Este archivo solo contiene variables, alias y llamadas a 'eval'.
# Las funciones personalizadas deben estar en ~/.config/fish/functions/

# --- Configuración Base y Comandos Interactivos ---
if status is-interactive
    # Desactivar el mensaje de bienvenida
    set -g fish_greeting ''

    # Configuración del historial: Limitar el número de entradas
    set -g fish_history_max_entries 20000

    # --- Alias Globales ---

    # Alias Generales
    alias cls 'clear'
    alias .bash 'source ~/.bashrc'
    alias cd.. 'cd ..'
    alias src 'source'
    alias lzg 'lazygit'
    alias lzd 'lazydocker'
    alias g 'git'
    alias nd 'node'
    alias nv 'nvim'
    alias wg 'winget.exe'

    # Alias para Git
    alias ga 'git add'
    alias gc 'git commit'
    alias gp 'git push'
    alias gl 'git pull'
    alias gs 'git status'
    alias gb 'git branch'
    alias gco 'git checkout'

    # Alias para Docker
    alias dk 'docker'
    alias dkc 'docker compose'
    alias dkps 'docker ps -a'
    alias dki 'docker images'
    alias dkr 'docker run'
    alias dkb 'docker build'
    
    # --- Gestores de versiones (Fast Node Manager) ---
    # CORREGIDO: Usar 'eval' para ejecutar la salida de fnm.
    # Esto define las variables y la función de autoload de fnm.
    # Esto asume que el binario 'fnm' está instalado.
    #eval (fnm env --use-on-cd --shell fish)

    # --- Plugins de Fisher ---
    # Ejemplo: Si usas fzf, debes asegurarte que el binario esté instalado.

    # --- Funciones Personalizadas ---
    # No es necesario listar las funciones, Fish las cargará automáticamente
    # si están en ~/.config/fish/functions/
    
    # --- Starship (Deshabilitado, si lo quieres usar, DESCOMENTA la línea de abajo) ---
    # Esto asume que tienes Starship instalado. Reemplazará tu fish_prompt.
    # starship init fish | source
end
# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# ... tus otras configuraciones ...

    # --- Herramientas Modernas ---
    # Zoxide (Reemplazo de cd)
    if type -q zoxide
        zoxide init fish | source
        alias cd='z'
    end

    # Eza (Reemplazo de ls)
    if type -q eza
        alias ls='eza --icons'
        alias ll='eza -la --icons'
        alias lt='eza --tree --level=2 --icons'
    end

    # Bat (Reemplazo de cat)
    if type -q bat
        alias cat='bat'
    end
    
    # FZF con Ripgrep (Para búsquedas rápidas)
    if type -q rg
        set -gx FZF_DEFAULT_COMMAND 'rg --files --hidden --follow --no-ignore-vcs'
        set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
    end
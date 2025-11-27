# --- 1. CONFIGURACIÓN INTERACTIVA ---
if status is-interactive
    set -g fish_greeting ''
    set -g fish_history_max_entries 20000
end

# --- 2. RUTAS (PATH) ---
# Agregamos las rutas explícitamente.
# Si la carpeta no existe, Fish simplemente la ignora (no da error).
fish_add_path -p ~/.local/bin
fish_add_path -p ~/.cargo/bin
fish_add_path -p ~/.bun/bin
fish_add_path -p ~/go/bin
fish_add_path -p /opt/homebrew/bin # macOS
fish_add_path -p /home/linuxbrew/.linuxbrew/bin # Linuxbrew

# --- 3. INICIALIZACIÓN DE HERRAMIENTAS ---

# Zoxide (cd inteligente)
if type -q zoxide
    zoxide init fish | source
    alias cd='z'
end

# FNM (Node.js)
if type -q fnm
    fnm env --use-on-cd --shell fish | source
end

# UV (Python)
if type -q uv
    uv generate-shell-completion fish | source
end

# Atuin (Historial)
if type -q atuin
    atuin init fish | source
end

# Direnv (Variables de entorno)
if type -q direnv
    direnv hook fish | source
end

# Starship (Prompt)
if type -q starship
    starship init fish | source
end

# --- 4. ALIAS Y UTILIDADES ---

# Sistema
alias cls='clear'
alias ..='cd ..'
alias src='source ~/.config/fish/config.fish'

# Git
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gs='git status'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# --- ALIAS DINÁMICOS (Solo si existen) ---

# Lazygit
if type -q lazygit; alias lzg='lazygit'; end

# Lazydocker
if type -q lazydocker; alias lzd='lazydocker'; end

# Bat (cat con alas)
if type -q bat; alias cat='bat'; end

# Eza (ls moderno)
if type -q eza
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -la --icons --group-directories-first'
    alias lt='eza --tree --level=2 --icons'
end

# Neovim
if type -q nvim
    alias vim='nvim'
    alias vi='nvim'
end

# Editor
set -gx EDITOR code
set -gx VISUAL code
# ── Atuin Initialization ──────────────────────────────────────────────
set -l brew_atuin "/home/linuxbrew/.linuxbrew/bin"

# 1. Si existe la ruta de Homebrew, la inyectamos de manera segura
if test -d $brew_atuin
    fish_add_path --global --prepend $brew_atuin
end

# 2. Inicializamos comprobando el binario local o global sin fallos
if test -x "$brew_atuin/atuin"; or type -q atuin
    command atuin init fish | source
end

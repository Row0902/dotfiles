set -l brew_bin "/home/linuxbrew/.linuxbrew/bin"

if test -d "$brew_bin"
    fish_add_path "$brew_bin"
end

# Usamos --use-on-cd para que cambie de versión según el directorio
if type -q fnm
    fnm env --use-on-cd --shell fish | source
end

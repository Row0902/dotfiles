set -l brew_bin "/home/linuxbrew/.linuxbrew/bin"

if test -d "$brew_bin"
    fish_add_path "$brew_bin"
end

if type -q fnm
    set -l old_xdg $XDG_RUNTIME_DIR
    set -e XDG_RUNTIME_DIR

    fnm env --use-on-cd --corepack-enabled --shell fish | source

    set -gx XDG_RUNTIME_DIR $old_xdg
end
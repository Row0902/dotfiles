set -l brew_direnv "/home/linuxbrew/.linuxbrew/bin"

if test -d "$brew_direnv"
    set -gx DIRENV_PATH "$brew_direnv"
else if type -q direnv
    set -gx DIRENV_PATH ""
end

if set -q DIRENV_PATH
    if test -n "$DIRENV_PATH"
        if not contains "$DIRENV_PATH" $PATH
            set -gx PATH "$DIRENV_PATH" $PATH
        end
    end

    direnv hook fish | source
    alias dv='direnv'
end
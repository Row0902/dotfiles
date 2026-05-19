set -l brew_zoxide "/home/linuxbrew/.linuxbrew/bin"

if test -d "$brew_zoxide"
    set -gx ZOXIDE_PATH "$brew_zoxide"
else if type -q zoxide
    set -gx ZOXIDE_PATH ""
end

if set -q ZOXIDE_PATH
    if test -n "$ZOXIDE_PATH"
        if not contains "$ZOXIDE_PATH" $PATH
            set -gx PATH "$ZOXIDE_PATH" $PATH
        end
    end

    zoxide init fish | source
    alias cd='z'
end
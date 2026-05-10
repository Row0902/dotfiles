set -l brew_atuin "/home/linuxbrew/.linuxbrew/bin"


if test -d "$brew_atuin"
    set -gx ATUIN_PATH "$brew_atuin"
else if type -q atuin
    set -gx ATUIN_PATH ""
end

if set -q ATUIN_PATH
    if test -n "$ATUIN_PATH"
        if not contains "$ATUIN_PATH" $PATH
            set -gx PATH "$ATUIN_PATH" $PATH
        end
    end

    atuin init fish | source
end

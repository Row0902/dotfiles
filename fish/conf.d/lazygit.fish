set -l brew_lazygit "/home/linuxbrew/.linuxbrew/bin"

if test -d "$brew_lazygit"
    set -gx LAZYGIT_PATH "$brew_lazygit"
else if type -q lazygit
    set -gx LAZYGIT_PATH ""
end

if set -q LAZYGIT_PATH
    if test -n "$LAZYGIT_PATH"
        if not contains "$LAZYGIT_PATH" $PATH
            set -gx PATH "$LAZYGIT_PATH" $PATH
        end
    end

    alias lg='lazygit'
end

set -l brew_eza "/home/linuxbrew/.linuxbrew/bin"


if test -d "$brew_eza"
    set -gx EZA_PATH "$brew_eza"
else if type -q eza
    set -gx EZA_PATH ""
end

if set -q EZA_PATH
    if test -n "$EZA_PATH"
        if not contains "$EZA_PATH" $PATH
            set -gx PATH "$EZA_PATH" $PATH
        end
    end

    alias ls='eza --icons --group-directories-first'
    alias ll='eza -la --icons --group-directories-first'
    alias lt='eza --tree --level=2 --icons'
end
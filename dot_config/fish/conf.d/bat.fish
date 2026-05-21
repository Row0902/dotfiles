set -l brew_bat "/home/linuxbrew/.linuxbrew/bin"
if test -d "$brew_bat"
    set -gx BAT_PATH "$brew_bat"
else if type -q bat
    set -gx BAT_PATH ""
end

if set -q BAT_PATH
    if test -n "$BAT_PATH"
        if not contains "$BAT_PATH" $PATH
            set -gx PATH "$BAT_PATH" $PATH
        end
    end

    alias cat='bat'
end
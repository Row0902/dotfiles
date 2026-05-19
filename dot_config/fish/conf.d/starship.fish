set -l brew_starship "/home/linuxbrew/.linuxbrew/bin"

if test -d "$brew_starship"
    set -gx STARSHIP_PATH "$brew_starship"
else if type -q starship
    set -gx STARSHIP_PATH ""
end

if set -q STARSHIP_PATH
    if test -n STARSHIP_PATH
        if not contains "$STARSHIP_PATH" $PATH
            set -gx PATH "$STARSHIP_PATH" $PATH
        end
    end

    starship init fish | source
end

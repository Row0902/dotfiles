set -l brew_opencode "/home/linuxbrew/.linuxbrew/bin"

if test -d "$brew_opencode"
    set -gx OPENCODE_PATH "$brew_opencode"
else if type -q opencode
    set -gx OPENCODE_PATH ""
end

if set -q OPENCODE_PATH
    if test -n "$OPENCODE_PATH"
        if not contains "$OPENCODE_PATH" $PATH
            set -gx PATH "$OPENCODE_PATH" $PATH
        end
    end

    alias oc='opencode'
end

set -l brew_fnm "/home/linuxbrew/.linuxbrew/bin"

if test -d "$brew_fnm"
    set -gx FNM_PATH "$brew_path"
else if type -q fnm
    set -gx ""
end

if set -q "$FNM_PATH"
    if test -n "$FNM_PATH"
        if not contains "$FNM_PATH" $PATH
            set -gx PATH "$FNM_PATH" $PATH
        end
    end

    fnm env --use-on-cd --shell fish | source
end
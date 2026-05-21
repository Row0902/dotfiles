set -l brew_fzf "/home/linuxbrew/.linuxbrew/bin"

if test -d "$brew_fzf"
    set -gx FZF_PATH "$brew_fzf"
else if type -q fzf
    set -gx FZF_PATH ""
end

if set -q FZF_PATH
    if test -n "$FZF_PATH"
        if not contains "$FZF_PATH" $PATH
            set -gx PATH "$FZF_PATH" $PATH
        end
    end

    # Preview de archivos con bat en fzf si está disponible
    set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --line-range :50 {}'"
    set -gx FZF_ALT_C_OPTS "--preview 'eza --icons --tree --level=2 {}'"

    # Cargar keybindings de fzf (ctrl+T archivos, alt+C cd)
    fzf --fish | source 2>/dev/null

    # Si atuin está instalado, restaurar ctrl+R para atuin
    # (fzf también intenta asignar ctrl+R, atuin es mejor para historial)
    if type -q atuin
        bind \cr _atuin_search
    end
end

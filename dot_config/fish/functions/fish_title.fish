function fish_title --description "Set terminal title: user:dir (branch)"
    # Ruta actual
    set -l current_path (string replace -r "^$HOME" '~' $PWD)
    set -l user_name (whoami)

    # Git branch si estamos en un repo
    set -l git_info ""
    if type -q git
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1
            set -l branch (git branch --show-current 2>/dev/null)
            if test -n "$branch"
                set git_info " ($branch)"
            end
        end
    end

    # Home
    if test "$current_path" = "~"
        echo -n "$user_name:~$git_info"
        return
    end

    # Última carpeta
    set -l last_dir (basename "$current_path")
    echo -n "$user_name:$last_dir$git_info"
end

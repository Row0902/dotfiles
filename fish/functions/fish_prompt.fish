function fish_prompt --description 'Write out the prompt'
    # 1. Definir la ruta actual y HOME
    set -l current_path $PWD
    set -l user_home $HOME
    
    # 2. Obtener el estado de Git (e.g., (main))
    set -l git_status (fish_vcs_prompt)

    # 3. Caso especial: estamos en $HOME
    if test "$current_path" = "$user_home"
        set -l prompt_symbol '#'
        if not test (id -u) = 0
            set prompt_symbol '$'
        end
        
        # Imprimir: (rama) $
        echo -n -s $git_status (set_color green) $prompt_symbol ' '
        return
    end

    # 4. Caso normal: obtener solo la última carpeta.
    set -l path_components (string split / $current_path)
    set -l last_dir (echo $path_components[-1])

    # 5. Definir el símbolo del prompt (usando $ o #)
    set -l prompt_symbol '#'
    if not test (id -u) = 0
        set prompt_symbol '$'
    end

    # 6. Imprimir el prompt: Carpeta (rama) $
    echo -n -s (set_color blue) $last_dir (set_color normal) " " $git_status " " (set_color green) $prompt_symbol ' '
end

function fish_title
    # 1. Define la ruta actual, reemplazando $HOME por ~ para simplificar
    set -l current_path (string replace -r "^$HOME" '~' $PWD)
    
    # 2. Obtener el nombre del usuario
    set -l user_name (whoami)
    
    # 3. Caso especial: estamos en $HOME
    if test "$current_path" = "~"
        # Mostrar solo el usuario y el tilde: row:~
        echo -n "$user_name:~"
        return
    end

    # 4. Caso normal: obtener solo la última carpeta.
    set -l path_components (string split / $current_path)
    set -l last_dir (echo $path_components[-1])

    # 5. Imprimir el título en el formato Usuario:Carpeta: row:development
    echo -n "$user_name:$last_dir"
end


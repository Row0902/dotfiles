function cdrm
    set -l current_dir (pwd)
    set -l dir_name (basename "$current_dir")
    
    read -P "¿Estás seguro de que quieres eliminar '$dir_name'? (s/n): " confirm
    
    if test "$confirm" != "s"
        echo "Operación cancelada."
        return 1
    end
    
    if cd ..
        if test -d "$current_dir"
            if rm -rf "$current_dir" > /dev/null 2>&1
                echo "Directorio '$dir_name' eliminado con éxito."
            else
                echo "Error: No se pudo eliminar el directorio '$current_dir'. Puede estar en uso."
                return 1
            end
        else
            echo "Error: El directorio '$current_dir' no existe."
            return 1
        end
    else
        echo "Error: No se pudo salir del directorio."
        return 1
    end
end
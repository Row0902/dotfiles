function cleanempty
    set -l empty_dirs (find . -type d -empty 2>/dev/null)
    
    if test (count $empty_dirs) -eq 0
        echo "No hay directorios vacíos en (pwd)."
        return 0
    end
    
    echo "Directorios vacíos encontrados:"
    for dir in $empty_dirs
        echo "$dir"
    end
    
    read -P "¿Eliminar estos directorios? (s/n): " confirm
    
    if test "$confirm" = "s"
        # find . -type d -empty -delete (El comando find es el mismo en Bash/Fish)
        find . -type d -empty -delete
        echo "Directorios vacíos eliminados."
    else
        echo "Operación cancelada."
    end
end
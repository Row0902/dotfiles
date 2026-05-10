function multidir
    set -l command "$argv[1]"
    set -l marker (test -n "$argv[2]"; and echo "$argv[2]"; or echo ".git")
    
    if test -z "$command"
        echo "Error: Debes especificar un comando."
        return 1
    end
    
    # Encontrar directorios que contengan el marcador (ej: .git)
    set -l dirs (find . -type d -name "$marker" -exec dirname {} \;)
    
    if test (count $dirs) -eq 0
        echo "No se encontraron directorios con '$marker'."
        return 1
    end
    
    for dir in $dirs
        echo "Ejecutando '$command' en '$dir'..."
        # Ejecutar el comando en un subshell para no afectar el directorio actual
        if begin 
            cd "$dir"
            eval "$command"
        end
        # Si el bloque anterior falla, imprime un error
        or echo "Error al ejecutar en '$dir'."
    end
end
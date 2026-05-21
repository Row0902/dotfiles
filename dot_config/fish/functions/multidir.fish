function multidir --description "Ejecuta un comando en todos los subdirectorios que contengan un marcador"
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
        if not begin
                pushd "$dir"
                fish -c "$command"
                popd
            end
            echo "Error al ejecutar en '$dir'."
        end
    end
end

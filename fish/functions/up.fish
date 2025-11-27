function up
    set -l levels (test -n "$argv[1]"; and echo "$argv[1]"; or echo 1)
    set -l path ""
    
    for i in (seq 1 $levels)
        set path "../$path"
    end
    
    if cd "$path"
        # Éxito
    else
        echo "Error: No se pudo subir $levels niveles."
        return 1
    end
end
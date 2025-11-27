function gitinit
    set -l dir "$argv[1]"
    # El segundo argumento es opcional, por defecto es 'yes'
    set -l create_readme (test -n "$argv[2]"; and echo "$argv[2]"; or echo "yes")
    
    if test -z "$dir"
        echo "Error: Debes especificar un nombre de directorio."
        return 1
    end
    
    # Crear y entrar al directorio
    if not mkdir -p "$dir"; or not cd "$dir"
        echo "Error: No se pudo crear o entrar al directorio '$dir'."
        return 1
    end
    
    # Inicializar Git
    if not git init
        echo "Error: No se pudo inicializar el repositorio Git."
        return 1
    end
    
    if test "$create_readme" = "yes"
        echo "# $dir" > README.md
        git add README.md
        
        # Crear commit inicial
        if not git commit -m "Initial commit"
            echo "Error: No se pudo crear el commit inicial."
            return 1
        end
        echo "Repositorio Git inicializado en '$dir' con README.md."
    else
        echo "Repositorio Git inicializado en '$dir'."
    end
end
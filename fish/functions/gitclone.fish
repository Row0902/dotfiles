function gitclone
    set -l repo_url "$argv[1]"
    
    if test -z "$repo_url"
        echo "Error: Debes especificar una URL de repositorio."
        return 1
    end
    
    # Extraer el nombre del repositorio de la URL
    set -l repo_name (basename "$repo_url" .git)
    
    # Clonar
    if not git clone "$repo_url"
        echo "Error: No se pudo clonar el repositorio."
        return 1
    end
    
    # Entrar al directorio
    if not cd "$repo_name"
        echo "Error: No se pudo entrar al directorio '$repo_name'."
        return 1
    end
    
    echo "Repositorio clonado y entrado en '$repo_name'."
end
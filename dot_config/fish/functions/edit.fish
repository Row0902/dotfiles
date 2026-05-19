function edit
    # Obtener el editor de la variable $EDITOR o usar 'code' por defecto
    set -l editor (test -n "$EDITOR"; and echo "$EDITOR"; or echo "code")
    
    if not command -s $editor
        echo "Error: El editor '$editor' no está instalado o no se encuentra en el PATH. Verifica la variable \$EDITOR."
        return 1
    end

    # Ejecutar el editor en el directorio actual
    if not $editor .
        echo "Error: No se pudo abrir el editor '$editor'."
        return 1
    end
    
    echo "Abriendo el directorio actual en '$editor'."
end
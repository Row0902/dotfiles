function edit --description "Abre el directorio actual en el editor configurado"
    # Obtener el editor de la variable $EDITOR o usar 'code' por defecto
    set -l editor (test -n "$EDITOR"; and echo "$EDITOR"; or echo "code")

    if not command -q $editor
        echo "Error: El editor '$editor' no está instalado o no se encuentra en el PATH. Verifica la variable \$EDITOR."
        return 1
    end

    echo "Abriendo el directorio actual en '$editor'..."

    if not $editor .
        echo "Error: No se pudo abrir el editor '$editor'."
        return 1
    end
end

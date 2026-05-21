function edit --description "Abre el directorio actual en el editor configurado"
    # Obtener el editor de $EDITOR o usar 'code' por defecto
    set -l editor_cmd
    if test -n "$EDITOR"
        # $EDITOR puede contener argumentos (ej: "emacs -nw")
        # En Fish, las variables se comportan como listas al no estar entrecomilladas
        set editor_cmd $EDITOR
    else
        set editor_cmd code
    end

    if not command -q $editor_cmd[1]
        echo "Error: El editor '$editor_cmd[1]' no está instalado o no se encuentra en el PATH. Verifica la variable \$EDITOR."
        return 1
    end

    echo "Abriendo el directorio actual en '$editor_cmd[1]'..."

    if not $editor_cmd .
        echo "Error: No se pudo abrir el editor '$editor_cmd[1]'."
        return 1
    end
end

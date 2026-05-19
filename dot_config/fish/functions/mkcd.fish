function mkcd
    if mkdir -p "$argv[1]"
        cd "$argv[1]"
    else
        echo "Error: No se pudo crear o entrar al directorio '$argv[1]'."
        return 1
    end
end
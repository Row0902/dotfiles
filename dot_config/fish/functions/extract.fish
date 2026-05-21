function extract --description "Expandir o extraer archivos comprimidos automáticamente"
    if not test -f "$argv[1]"
        echo "'$argv[1]' no es un archivo válido"
        return 1
    end

    # Flag para no silenciar errores de herramientas no encontradas
    set -l tool

    switch "$argv[1]"
        case '*.tar.bz2'
            set tool tar; and tar xjf "$argv[1]"
        case '*.tar.gz'
            set tool tar; and tar xzf "$argv[1]"
        case '*.tar.xz'
            set tool tar; and tar xJf "$argv[1]"
        case '*.tar.zst'
            set tool tar; and tar --zstd -xf "$argv[1]"
        case '*.bz2'
            set tool bunzip2; and bunzip2 "$argv[1]"
        case '*.rar'
            set tool unrar; and unrar x "$argv[1]"
        case '*.gz'
            set tool gunzip; and gunzip "$argv[1]"
        case '*.tar'
            set tool tar; and tar xf "$argv[1]"
        case '*.tbz2'
            set tool tar; and tar xjf "$argv[1]"
        case '*.tgz'
            set tool tar; and tar xzf "$argv[1]"
        case '*.zip'
            set tool unzip; and unzip "$argv[1]"
        case '*.zst'
            set tool unzstd; and unzstd "$argv[1]"
        case '*.xz'
            set tool unxz; and unxz "$argv[1]"
        case '*.7z'
            set tool 7z; and 7z x "$argv[1]"
        case '*.Z'
            set tool uncompress; and uncompress "$argv[1]"
        case '*'
            echo "'$argv[1]' no puede ser extraído mediante extract"
            return 1
    end

    # Verificar si el comando se ejecutó correctamente o la herramienta faltaba
    if test $status -ne 0
        if not command -q $tool
            echo "Error: '$tool' no está instalado. Instalalo con tu gestor de paquetes."
            return 1
        end
        echo "Error: Falló la extracción de '$argv[1]'."
        return 1
    end
end

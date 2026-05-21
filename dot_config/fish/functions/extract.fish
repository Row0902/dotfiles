function extract --description "Expandir o extraer archivos comprimidos automáticamente"
    if not test -f "$argv[1]"
        echo "'$argv[1]' no es un archivo válido"
        return 1
    end

    # Mapear extensión → herramienta (pre-check antes de ejecutar)
    set -l tool
    switch "$argv[1]"
        case '*.tar.bz2' '*.tar.gz' '*.tar.xz' '*.tar.zst' '*.tar' '*.tbz2' '*.tgz'
            set tool tar
        case '*.bz2'
            set tool bunzip2
        case '*.rar'
            set tool unrar
        case '*.gz'
            set tool gunzip
        case '*.zip'
            set tool unzip
        case '*.zst'
            set tool unzstd
        case '*.xz'
            set tool unxz
        case '*.7z'
            set tool 7z
        case '*.Z'
            set tool uncompress
        case '*'
            echo "'$argv[1]' no puede ser extraído mediante extract"
            return 1
    end

    # Pre-check: la herramienta debe estar instalada
    if not command -q $tool
        echo "Error: '$tool' no está instalado. Instalalo con tu gestor de paquetes."
        return 1
    end

    # Ejecutar comando específico por extensión
    switch "$argv[1]"
        case '*.tar.bz2'
            tar xjf "$argv[1]"
        case '*.tar.gz'
            tar xzf "$argv[1]"
        case '*.tar.xz'
            tar xJf "$argv[1]"
        case '*.tar.zst'
            tar --zstd -xf "$argv[1]"
        case '*.bz2'
            bunzip2 "$argv[1]"
        case '*.rar'
            unrar x "$argv[1]"
        case '*.gz'
            gunzip "$argv[1]"
        case '*.tar'
            tar xf "$argv[1]"
        case '*.tbz2'
            tar xjf "$argv[1]"
        case '*.tgz'
            tar xzf "$argv[1]"
        case '*.zip'
            unzip "$argv[1]"
        case '*.zst'
            unzstd "$argv[1]"
        case '*.xz'
            unxz "$argv[1]"
        case '*.7z'
            7z x "$argv[1]"
        case '*.Z'
            uncompress "$argv[1]"
    end
    or begin
        echo "Error: Falló la extracción de '$argv[1]'."
        return 1
    end
end

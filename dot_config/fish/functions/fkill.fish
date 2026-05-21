function fkill --description "Mata procesos por nombre con confirmación"
    if test -z "$argv[1]"
        echo "Uso: fkill <nombre-del-proceso>"
        return 1
    end

    # Buscar procesos que coincidan
    set -l matches (ps aux | grep -i "$argv[1]" | grep -v grep)

    if test (count $matches) -eq 0
        echo "No se encontraron procesos con '$argv[1]'."
        return 1
    end

    # Mostrar los procesos encontrados
    echo "Procesos encontrados:"
    for line in $matches
        echo "$line"
    end

    read -P "¿Matar estos procesos? (s/n): " confirm
    if test "$confirm" != "s"
        echo "Operación cancelada."
        return 1
    end

    # Extraer PIDs y matar
    ps aux | grep -i "$argv[1]" | grep -v grep | awk '{print $2}' | xargs -r kill -9
    echo "Procesos terminados."
end

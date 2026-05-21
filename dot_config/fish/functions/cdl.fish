function cdl --description "Navega a un subdirectorio seleccionándolo por número"
    set -l dirs (command ls -d */ 2>/dev/null | string replace -r "/$" "")

    if test (count $dirs) -eq 0
        echo "No hay directorios en (pwd)."
        return 1
    end

    echo "Directorios disponibles:"
    for i in (seq 0 (math (count $dirs) - 1))
        echo "$i: $dirs[(math $i + 1)]"
    end

    read -P "Selecciona un número (0-(math (count $dirs) - 1)): " choice

    if not string match -q -r '^[0-9]+$' "$choice"
        echo "Selección inválida."
        return 1
    end

    if test "$choice" -lt 0; or test "$choice" -ge (count $dirs)
        echo "Selección inválida."
        return 1
    end

    set -l target_dir $dirs[(math $choice + 1)]
    if not cd "$target_dir"
        echo "Error: No se pudo entrar a '$target_dir'."
        return 1
    end
end

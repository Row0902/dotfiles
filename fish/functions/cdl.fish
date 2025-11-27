function cdl
    set -l dirs (ls -d */ 2>/dev/null | string replace -r "/$" "")
    
    if test (count $dirs) -eq 0
        echo "No hay directorios en (pwd)."
        return 1
    end
    
    echo "Directorios disponibles:"
    for i in (seq 0 (math (count $dirs) - 1))
        echo "$i: $dirs[(math $i + 1)]"
    end
    
    read -P "Selecciona un número (0-(math (count $dirs) - 1)): " choice
    
    if string match -q -r '^[0-9]+$' "$choice" 
        if test "$choice" -ge 0; and test "$choice" -lt (count $dirs)
            set -l target_dir $dirs[(math $choice + 1)]
            if cd "$target_dir"
                # Éxito
            else
                echo "Error: No se pudo entrar a '$target_dir'."
                return 1
            end
        else
            echo "Selección inválida."
            return 1
        end
    else
        echo "Selección inválida."
        return 1
    end
end
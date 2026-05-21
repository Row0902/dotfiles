function tree --description "Lista directorios en árbol con profundidad configurable"
    set -l depth (test -n "$argv[1]"; and echo "$argv[1]"; or echo "2")

    if not command -q eza
        echo "Error: eza no está instalado."
        return 1
    end

    eza --tree --level=$depth --icons --group-directories-first $argv[2..]
end

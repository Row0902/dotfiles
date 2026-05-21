function ports --description "Muestra qué procesos están escuchando en qué puertos"
    if command -q ss
        ss -tlnp4
    else if command -q netstat
        netstat -tlnp 2>/dev/null | grep LISTEN
    else
        echo "Error: No se encontró ss ni netstat."
        return 1
    end
end

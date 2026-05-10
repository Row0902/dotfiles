if status is-interactive
    set -g fish_greeting ''
    set -g fish_history_max_entries 20000
end


fish_add_path -p ~/.local/bin
fish_add_path -p ~/.cargo/bin
fish_add_path -p ~/.bun/bin
fish_add_path -p ~/go/bin
fish_add_path -p /opt/homebrew/bin # macOS
fish_add_path -p /home/linuxbrew/.linuxbrew/bin # Linuxbrew



# Direnv
if type -q direnv
    direnv hook fish | source
end

# Starship
if type -q starship
    starship init fish | source
end

# --- CONFIGURACIÓN DE VARIABLES GLOBALES ---

# Editor
set -gx EDITOR code
set -gx VISUAL code


# proto
set -gx PROTO_HOME "$HOME/.proto";
set -gx PATH "$PROTO_HOME/shims" "$PROTO_HOME/bin" $PATH;

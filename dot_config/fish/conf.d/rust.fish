# ── Rust / Cargo Universal Environment ────────────────────────────────

# 1. Ruta estándar del script oficial (Shims de Cargo)
set -l cargo_bin "$HOME/.cargo/bin"
if test -d $cargo_bin
    fish_add_path --global --append $cargo_bin
end

# 2. Ruta alternativa de Toolchains (Instalaciones vía Gestores de Paquetes)
set -l rustup_bin "$HOME/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin"
if test -d $rustup_bin
    fish_add_path --global --append $rustup_bin
end

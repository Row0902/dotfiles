# ── Rust / Cargo Environment ──────────────────────────────────────────
set -l cargo_bin "$HOME/.cargo/bin"

if test -d $cargo_bin
    # fish_add_path es inteligente y no duplica si ya existe, 
    # pero al meterlo en conf.d nos aseguramos de mantener el PATH limpio.
    fish_add_path --global --append $cargo_bin
end

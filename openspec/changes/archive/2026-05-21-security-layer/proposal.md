# Proposal: Security Layer

## Intent

Preparar chezmoi para manejar secretos (claves SSH, tokens, API keys) de forma segura mediante age encryption, y agregar modify templates para cirugía de precisión en archivos existentes.

## Scope

### In Scope
1. **age encryption setup** — `chezmoi age-keygen` + config en `chezmoi.toml`
2. **modify template** — `modify_dot_gitconfig.local` para editar `~/.gitconfig.local`

### Out of Scope
- Encryptar archivos existentes (setup only)
- Refactor templates
- Fix pre-existing promptOnce

## Approach
- age asymmetric con clave X25519 dedicada, identity en `~/.config/chezmoi/key.txt`
- modify template recibe stdin, transforma, emite stdout

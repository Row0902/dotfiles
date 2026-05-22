# Proposal: Config Foundation

## Intent

Chezmoi corre hoy con cero configuración: sin auto-commit, sin merge tool, sin interpreters declarados. Los brew paths están duplicados a mano en `config.fish.tmpl` y `gitconfig.tmpl`. Este cambio establece la base configurable que los cambios 2 y 3 van a necesitar.

## Scope

### In Scope
- `chezmoi.toml` en `~/.config/chezmoi/` con auto-commit, diff pager (delta), merge tool, interpreters declarados
- `.chezmoidata.toml` en la raíz del repo con datos públicos (brew paths por OS, editor, git defaults)
- `.chezmoitemplates/` en la raíz con partials reutilizables: `brew-path`, `git-identity`, `os-path`

### Out of Scope
- age encryption / secrets (Change 3)
- `run_once_*` scripts (Change 2)
- `.chezmoiexternal.toml` (Change 2)
- Migración de datos sensibles a age
- Cambios en el `bootstrap.sh` existente

## Approach

| Feature | Strategy |
|---------|----------|
| `chezmoi.toml` | Archivo en `~/.config/chezmoi/chezmoi.toml` (fuera del repo chezmoi, se gestiona con `chezmoi add`). `autoCommit=true`, `autoPush=false`, `diff.pager="delta"`, `merge.command="vimdiff"`, interpreters para `fish` |
| `.chezmoidata.toml` | En raíz del repo. Datos: brew paths por OS, editor, git defaults |
| `.chezmoitemplates/` | Partial `brew-path` → resuelve según `.chezmoi.os`. Partial `git-identity` → nombre/email desde `.chezmoidata` con fallback a `promptOnce`. Partial `os-path` → resuelve rutas base por OS |

## Risks

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| `chezmoi.toml` no detectado por estar fuera del repo | Low | Usar `chezmoi add ~/.config/chezmoi/chezmoi.toml` — chezmoi lo trackea aunque esté fuera del source dir |
| `autoCommit=true` genera commits no deseados | Medium | `autoPush=false`. El usuario revisa antes de push. Fácil de revertir |
| Partials rompen templates existentes si cambia la firma | Low | Los partials nuevos NO modifican templates existentes en este cambio — solo se crean |

## Rollback Plan

1. `chezmoi remove ~/.config/chezmoi/chezmoi.toml` → borra el config y vuelve a defaults
2. `chezmoi rm .chezmoidata.toml` + `chezmoi rm -r .chezmoitemplates/` → elimina del source state
3. Si `autoCommit` dejó commits no deseados: `git reset HEAD~N --soft` + `git restore --staged .` en el source dir

## Dependencies

- Ninguna. Es el cambio fundacional. Los cambios 2 y 3 dependen de este.

## Success Criteria

- [ ] `chezmoi diff` usa delta como pager
- [ ] `chezmoi add` crea auto-commit en el source dir
- [ ] `{{ template "brew-path" . }}` resuelve `/opt/homebrew` en Darwin y `/home/linuxbrew/.linuxbrew` en Linux
- [ ] `{{ .brew_prefix_darwin }}` y `{{ .brew_prefix_linux }}` disponibles en todos los templates
- [ ] `chezmoi merge` abre vimdiff
- [ ] `chezmoi apply` no cambia comportamiento existente (no regresión)

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `~/.config/chezmoi/chezmoi.toml` | **New** | Config del tool: auto-commit, diff, merge, interpreters |
| `.chezmoidata.toml` | **New** | Datos centralizados públicos (brew paths, editor, git defaults) |
| `.chezmoitemplates/brew-path.tmpl` | **New** | Partial para brew prefix por OS |
| `.chezmoitemplates/git-identity.tmpl` | **New** | Partial para user/email config |
| `.chezmoitemplates/os-path.tmpl` | **New** | Partial para rutas base por OS |

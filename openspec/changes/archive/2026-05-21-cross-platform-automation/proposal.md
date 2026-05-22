# Proposal: Cross-Platform Automation

## Intent

Automatizar package installation y binary downloads para que chezmoi sea self-provisioning cross-platform desde el primer `chezmoi apply`.

## Scope

### In Scope
- `run_once_before_install-packages.sh.tmpl` — brew/winget install en primera ejecución
- `run_once_before_install-packages.ps1.tmpl` — Windows equivalent
- `.chezmoiexternal.toml` — auto-download delta, starship per OS/arch
- `.chezmoiignore` — OS-based script filters (MODIFICAR existente)
- `scripts/bootstrap.sh` — refactor: mover Phase 1 no-interactiva a run_once_

### Out of Scope
- age encryption / secrets (Change 3)
- Refactor templates existentes con partials
- Fix pre-existing `promptOnce` en `dot_gitconfig.local.tmpl`
- Modify `.chezmoitemplates/` existentes

## Approach

| Feature | Strategy |
|---------|----------|
| Package scripts | Dual `.sh.tmpl`/`.ps1.tmpl` con `.chezmoiignore` OS filters. `run_once_before_` ejecuta en primer apply |
| External binaries | `.chezmoiexternal.toml` con `{{ .chezmoi.os }}_{{ .chezmoi.arch }}` en URLs, `refreshPeriod: 168h` |
| Bootstrap refactor | Mover brew bundle a `run_once_`. Mantener SSH, gh auth, chsh en bootstrap.sh interactivo |
| Windows | `.ps1.tmpl` llama winget. Auto-fallback pwsh → powershell.exe |

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `run_once_before_install-packages.sh.tmpl` | **New** | brew/winget install script (Unix) |
| `run_once_before_install-packages.ps1.tmpl` | **New** | winget install script (Windows) |
| `.chezmoiexternal.toml` | **New** | Binary downloads from GitHub releases |
| `.chezmoiignore` | **Modified** | OS filters for run_once_ scripts |
| `scripts/bootstrap.sh` | **Modified** | Delegate Phase 1 a run_once_ |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| `.ps1` execution policy blocks script | Medium | chezmoi invoca con `-ExecutionPolicy Bypass` |
| `winget` no disponible (Windows viejo) | Low | Check availability, warn y skip |
| URL externa cambia | Low | URLs pinned a releases específicas |
| Bootstrap Phase 1 removida pero run_once_ no ejecutó | Low | run_once_ corre en próximo apply; bootstrap.sh como fallback |

## Rollback Plan

1. `chezmoi rm run_once_before_install-packages.sh.tmpl run_once_before_install-packages.ps1.tmpl .chezmoiexternal.toml`
2. `git checkout .chezmoiignore` + `git checkout scripts/bootstrap.sh`
3. Borrar binaries descargados del PATH

## Dependencies

- ✅ Config Foundation (archivado) — `.chezmoidata.toml`, partials

## Success Criteria

- [ ] Script .sh instala Brewfile packages en primer apply (Linux/macOS)
- [ ] Script .ps1 instala packages via winget en Windows
- [ ] `.chezmoiexternal.toml` descarga delta y starship por OS/arch
- [ ] `.chezmoiignore` filtra `.ps1` en non-Windows y `.sh` en Windows
- [ ] `bootstrap.sh` interactivo sigue funcionando post-refactor

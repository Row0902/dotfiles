# Archive Report: Cross-Platform Automation

## Status

✅ **Success**

## Executive Summary

Se automatizó la instalación de packages y descarga de binaries para que chezmoi sea self-provisioning cross-platform.

### Logros
- **`run_once_before_install-packages.sh.tmpl`** — brew bundle en primer apply (Linux/macOS)
- **`run_once_before_install-packages.ps1.tmpl`** — winget install en primer apply (Windows)
- **`.chezmoiexternal.toml`** — delta + starship descargados por OS/arch
- **`.chezmoiignore`** — filtros OS para scripts
- **`scripts/bootstrap.sh`** — Phase 1 con sentinel check

## Delta Spec

| ID | Tipo | Cambio | Archivo |
|---|---|---|---|
| PKG-01 | ADDED | OS-aware package install via run_once_ | `run_once_before_install-packages.sh.tmpl` |
| PKG-02 | ADDED | OS filtering via .chezmoiignore | `.chezmoiignore` |
| BIN-01 | ADDED | Binary download delta + starship | `.chezmoiexternal.toml` |
| PROV-01 | MODIFIED | bootstrap.sh Phase 1 con sentinel | `scripts/bootstrap.sh` |

## Issues resueltos en fix commit

| Issue | Severidad | Fix |
|-------|:---------:|-----|
| `{{ fail }}` en externals rompía `chezmoi apply` en Windows | 🔴 CRITICAL | ✅ Envuelto en `{{ if ne .chezmoi.os "windows" }}` |
| brew bundle failure fatal (`set -e`) | 🟡 WARNING | ✅ `--no-lock \|\| true` + path quote |
| `.sh` sin `exit 0` explícito | 🟡 WARNING | ✅ Agregado |

## Known Issues

- `chezmoi apply --dry-run` bloqueado por pre-existing `promptOnce` en `dot_gitconfig.local.tmpl`
- Windows externals solo via winget (delta/starship no se descargan como binaries en Windows)

## Commits

- `32a03a8` — feat: cross-platform automation (5 tareas)
- `8c37025` — fix: windows-safe externals, non-fatal brew bundle

## Next

| Prioridad | Cambio | Dependencias |
|---|---|---|
| 1️⃣ | **Security Layer** (age encryption + modify templates) | ✅ Config Foundation |
| 2️⃣ | **Fix pre-existing**: corregir `promptOnce` en `dot_gitconfig.local.tmpl` | Ninguna |

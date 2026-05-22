# Cross-Platform Automation — Tasks

## Phase 1: Foundation

### 1.1 Modify `.chezmoiignore` — OS filters for scripts

**Archivos**: `.chezmoiignore`
**Dependencias**: ninguna
**Criterio de aceptación**: `.ps1` ignorado en Unix, `.sh` ignorado en Windows
**Verificación**: `chezmoi apply --dry-run` (aunque dry-run falla por pre-existing, verificar con `chezmoi execute-template`)
**Contenido a agregar al final**:
```
{{ if eq .chezmoi.os "windows" }}run_once_*.sh{{ end }}
{{ if ne .chezmoi.os "windows" }}run_once_*.ps1{{ end }}
```

### 1.2 Create `.chezmoiexternal.toml` — binary downloads

**Archivos**: `.chezmoiexternal.toml`
**Dependencias**: ninguna
**Criterio de aceptación**: `chezmoi apply` descarga delta y starship en `~/.local/bin/`
**Verificación**: `chezmoi apply --refresh-externals` — verificar que los archivos existen después

---

## Phase 2: Core Scripts

### 2.1 Create `run_once_before_install-packages.sh.tmpl` — Unix

**Archivos**: `run_once_before_install-packages.sh.tmpl`
**Dependencias**: 1.1 (filtros OS)
**Criterio de aceptación**: En Linux/macOS, primer apply ejecuta brew bundle
**Verificación**: `chezmoi apply` en Linux — brew bundle ejecuta una vez

### 2.2 Create `run_once_before_install-packages.ps1.tmpl` — Windows

**Archivos**: `run_once_before_install-packages.ps1.tmpl`
**Dependencias**: 1.1 (filtros OS)
**Criterio de aceptación**: En Windows, primer apply ejecuta winget install
**Verificación**: `chezmoi apply` en Windows — packages instalados

---

## Phase 3: Integration

### 3.1 Modify `scripts/bootstrap.sh` — Phase 1 sentinel

**Archivos**: `scripts/bootstrap.sh`
**Dependencias**: 2.1 (run_once_ existe)
**Criterio de aceptación**: bootstrap.sh saltea Phase 1 si run_once_ ya instaló
**Verificación**: `./scripts/bootstrap.sh` después de apply — no reinstala packages

---

## Review Workload Forecast

- Estimated changed lines: **~90**
- 400-line budget risk: **Low**
- Chained PRs recommended: **No**
- Single PR: ✅ sin excepción

## Rollback Plan

| Tarea | Rollback |
|-------|----------|
| 1.1 | `git checkout .chezmoiignore` |
| 1.2 | `chezmoi rm .chezmoiexternal.toml` + borrar binaries |
| 2.1 | `chezmoi rm run_once_before_install-packages.sh.tmpl` |
| 2.2 | `chezmoi rm run_once_before_install-packages.ps1.tmpl` |
| 3.1 | `git checkout scripts/bootstrap.sh` |

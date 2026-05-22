# Archive Report: Config Foundation

## Status

✅ **Success**

## Executive Summary

Se estableció la base configurable de chezmoi en el repo de dotfiles. Antes de este cambio, chezmoi operaba sin configuración explícita (sin auto-commit, sin merge tool, sin pager configurado) y los brew paths estaban duplicados manualmente en templates.

Este cambio creó 3 capas independientes:

1. **`dot_config/chezmoi/chezmoi.toml`** — Config del tool: auto-commit con mensaje `"chore: sync dotfiles"`, delta como pager diff, vimdiff como merge tool. Interpreters de ps1 delegados al auto-fallback de chezmoi.

2. **`.chezmoidata.toml`** — Datos públicos centralizados: brew paths por OS, editor, git defaults, os config dir.

3. **`.chezmoitemplates/`** — 3 partials reutilizables: `brew-path`, `git-identity`, `os-path`.

## Delta Spec

### Domain: chezmoi-config

| ID | Tipo | Cambio | Archivo |
|---|---|---|---|
| CFG-01 | ADDED | `git.autoAdd = true` | `dot_config/chezmoi/chezmoi.toml` |
| CFG-02 | ADDED | `git.autoCommit = true` + template msg | 〃 |
| CFG-03 | ADDED | `git.autoPush = false` | 〃 |
| CFG-04 | ADDED | `diff.pager = "delta"` | 〃 |
| CFG-05 | ADDED | `merge.command = "vimdiff"` + template args | 〃 |
| CFG-06 | MODIFIED | Spec declaraba `interpreters.ps1` explícito → implementación lo omite, delega fallback a chezmoi | 〃 |

### Domain: chezmoi-data

| ID | Tipo | Cambio | Archivo |
|---|---|---|---|
| DAT-01 | ADDED | `brew.prefix_darwin`, `brew.prefix_linux` | `.chezmoidata.toml` |
| DAT-02 | ADDED | `editor.command`, `editor.diff`, `git.default_branch`, `os.config_dir` | 〃 |
| DAT-03 | ADDED | Sin secrets/credentials (público) | 〃 |

### Domain: chezmoi-templates

| ID | Tipo | Cambio | Archivo |
|---|---|---|---|
| TPL-01 | ADDED | Partial `brew-path` por OS | `.chezmoitemplates/brew-path.tmpl` |
| TPL-02 | ADDED | Partial `git-identity` con `promptStringOnce` | `.chezmoitemplates/git-identity.tmpl` |
| TPL-03 | ADDED | Partial `os-path` para Unix | `.chezmoitemplates/os-path.tmpl` |

## Known Issues

### Pre-existing (no de este cambio)
- **`dot_gitconfig.local.tmpl`** usa `promptOnce` (debería ser `promptStringOnce`). Bloquea `chezmoi apply --dry-run`.

### Riesgo residual
- **Bootstrapping de 2 applies**: el config se activa recién en el segundo `chezmoi apply`.

## Next

| Prioridad | Cambio | Dependencias |
|---|---|---|
| 1️⃣ | **Cross-Platform Automation** (run_once_ scripts + .chezmoiexternal.toml) | ✅ Config Foundation |
| 2️⃣ | **Security Layer** (age encryption + modify templates) | ✅ Config Foundation |
| 3️⃣ | **Fix pre-existing**: corregir `promptOnce` en `dot_gitconfig.local.tmpl` | Ninguna |

# Config Foundation — Tasks

## Phase 1: Data Layer

### 1.1 Create `.chezmoidata.toml` ✅

**Archivos**: `.chezmoidata.toml`
**Dependencias**: ninguna
**Criterio de aceptación**: `{{ .brew.prefix_linux }}` resuelve en templates
**Verificación**:
```bash
chezmoi execute-template "{{ .brew.prefix_linux }}"
# → /home/linuxbrew/.linuxbrew
```

---

## Phase 2: Template Layer

### 2.1 Create `.chezmoitemplates/brew-path.tmpl`

**Archivos**: `.chezmoitemplates/brew-path.tmpl`
**Dependencias**: 1.1 (lee de `.chezmoidata`)
**Criterio de aceptación**: `{{ template "brew-path" . }}` resuelve según OS
**Verificación**:
```bash
chezmoi execute-template "{{ template \"brew-path\" . }}"
# → /home/linuxbrew/.linuxbrew (en Linux)
```

### 2.2 Create `.chezmoitemplates/git-identity.tmpl`

**Archivos**: `.chezmoitemplates/git-identity.tmpl`
**Dependencias**: 1.1 (opcional, usa prompt fallback)
**Criterio de aceptación**: Renderiza sección `[user]` con name + email
**Verificación**:
```bash
chezmoi execute-template "{{ template \"git-identity\" . }}"
# → [user]
# →     name = "..."
# →     email = "..."
```

### 2.3 Create `.chezmoitemplates/os-path.tmpl`

**Archivos**: `.chezmoitemplates/os-path.tmpl`
**Dependencias**: 1.1 (opcional, usa `.os.config_dir`)
**Criterio de aceptación**: Renderiza `$HOME/.config` en Unix
**Verificación**:
```bash
chezmoi execute-template "{{ template \"os-path\" . }}"
# → /home/row/.config (en Linux)
```

---

## Phase 3: Config Layer

### 3.1 Create `dot_config/chezmoi/chezmoi.toml`

**Archivos**: `dot_config/chezmoi/chezmoi.toml`
**Dependencias**: ninguna (archivo independiente)
**Criterio de aceptación**: `chezmoi diff` usa delta, `chezmoi add` genera auto-commit
**Verificación**:
```bash
chezmoi apply          # primer apply → crea ~/.config/chezmoi/chezmoi.toml
chezmoi diff           # debe usar delta como pager
touch /tmp/test-dotfile && chezmoi add /tmp/test-dotfile && git log -1
# → commit con mensaje "chore: sync dotfiles"
```

---

## Phase 4: Bootstrap & Verify

### 4.1 Two-apply bootstrap

**Archivos**: todos los anteriores
**Dependencias**: 3.1
**Criterio de aceptación**: Después del segundo `chezmoi apply`, la config está activa
**Verificación**:
```bash
chezmoi apply          # primer apply
chezmoi apply          # segundo apply (ya con config activa)
```

### 4.2 Verify partials rendering

**Archivos**: `.chezmoitemplates/*.tmpl`
**Dependencias**: 2.1, 2.2, 2.3
**Criterio de aceptación**: Todos los partials renderizan correctamente
**Verificación**:
```bash
for p in brew-path git-identity os-path; do
    echo "=== $p ==="
    chezmoi execute-template "{{ template \"$p\" . }}"
done
```

### 4.3 Verify no regression

**Dependencias**: 4.1
**Criterio de aceptación**: `chezmoi apply --dry-run` no muestra cambios inesperados en archivos existentes
**Verificación**:
```bash
chezmoi apply --dry-run
# → solo debe mostrar los archivos nuevos de este cambio
```

---

## Estimación

| Fase | Archivos | Líneas aprox |
|------|----------|:------------:|
| 1. Data | 1 crear | ~15 |
| 2. Templates | 3 crear | ~15 |
| 3. Config | 1 crear | ~15 |
| 4. Bootstrap | — | ~10 (verificación) |
| **Total** | **5 crear** | **~55** |

## Review Workload Forecast

- Estimated changed lines: **~55**
- 400-line budget risk: **Low**
- Chained PRs recommended: **No**
- Single PR: ✅ sin excepción

## Rollback Plan

| Tarea | Rollback |
|-------|----------|
| 1.1 | `chezmoi rm .chezmoidata.toml` |
| 2.1-2.3 | `chezmoi rm -r .chezmoitemplates/` |
| 3.1 | `chezmoi rm ~/.config/chezmoi/chezmoi.toml` |
| 4.1 | `git reset HEAD~2 --soft` (si auto-commit generó commits) |

# Config Foundation — Design

## Architecture Overview

```
~/.config/chezmoi/chezmoi.toml     ← Tool behavior (auto-commit, diff, merge, interpreters)
        │
        ▼
.chezmoidata.toml                   ← Template variables (brew paths, editor, git defaults)
        │
        ▼
.chezmoitemplates/                  ← Reusable partials
  ├── brew-path.tmpl                → Brew prefix por OS
  ├── git-identity.tmpl             → [user] section
  └── os-path.tmpl                  → Base paths por OS
```

Tres capas independientes con una sola dirección de dependencia: config afecta el comportamiento del tool, data alimenta templates, partials consumen data.

## Architecture Decisions

### AD-01: Archivos separados vs monolito
- **Opción**: Un solo `chezmoi.toml` con `[data]` inline vs `.chezmoidata.toml` separado
- **Elegido**: `.chezmoidata.toml` separado
- **Motivo**: Los datos de template deben ser editables sin tocar la config del tool. Además, `.chezmoidata.toml` hace deep-merge con `[data]` en config, permitiendo overrides por máquina.

### AD-02: TOML para data vs YAML/JSON
- **Elegido**: TOML (`.chezmoidata.toml`)
- **Motivo**: Chezmoi soporta TOML, YAML, y JSON para data files. TOML es el formato nativo de la config de chezmoi, consistente con `chezmoi.toml`.

### AD-03: Partials data-driven vs hardcodeados
- **Opción**: Valores fijos en partials vs valores desde `.chezmoidata`
- **Elegido**: Data-driven (partials leen de `.chezmoidata`)
- **Motivo**: Si el path de brew cambia (ej: Apple Silicon → Intel), se actualiza un solo lugar en `.chezmoidata.toml`.

### AD-04: Prompt fallback para git identity
- **Opción**: Datos fijos en `.chezmoidata.toml` con `promptStringOnce` en el partial
- **Elegido**: Datos en `.chezmoidata` como fuente principal, `promptStringOnce` como fallback
- **Motivo**: `.chezmoidata.toml` se trackea en git (público). Para datos personales (name, email), el partial puede caer en `promptStringOnce` + `oncefor` para evitar preguntar siempre.

### AD-05: Interpreters explícitos
- **Elegido**: Declarar `interpreters.ps1` en `chezmoi.toml`
- **Motivo**: En Windows, si `pwsh` no está, chezmoi cae a `powershell.exe` automáticamente. Pero declararlo explícitamente evita ambigüedad y permite al usuario override local.

### AD-06: `private_` prefix para chezmoi.toml
- **Elegido**: Usar `dot_config/chezmoi/chezmoi.toml` (source) → `~/.config/chezmoi/chezmoi.toml` (target)
- **Motivo**: No se puede usar `private_dot_config/` porque `dot_config/` ya existe en el source y chezmoi no permite dos entradas para el mismo directorio target con atributos distintos. Las claves age se manejarán aparte.

## File Specifications

### 1. `dot_config/chezmoi/chezmoi.toml` (target: `~/.config/chezmoi/chezmoi.toml`)

```toml
[git]
    autoAdd = true
    autoCommit = true
    autoPush = false
    commitMessageTemplate = "chore: sync dotfiles"

[diff]
    pager = "delta"

[merge]
    command = "vimdiff"
    args = ["-d", "{{ .Destination }}", "{{ .Source }}", "{{ .Target }}"]

[interpreters]
    ps1 = { command = "pwsh", args = ["-NoLogo", "-NoProfile", "-File"] }
```

### 2. `.chezmoidata.toml`

```toml
[brew]
prefix_darwin = "/opt/homebrew"
prefix_linux = "/home/linuxbrew/.linuxbrew"

[editor]
command = "code --wait"
diff = "nvim -d"

[git]
default_branch = "main"

[os]
config_dir = ".config"
```

### 3. `.chezmoitemplates/brew-path.tmpl`

```
{{- if eq .chezmoi.os "darwin" -}}
{{ .brew.prefix_darwin }}
{{- else if eq .chezmoi.os "linux" -}}
{{ .brew.prefix_linux }}
{{- end -}}
```

### 4. `.chezmoitemplates/git-identity.tmpl`

```
[user]
    name = {{ promptStringOnce . "git_user_name" "Your full name" | quote }}
    email = {{ promptStringOnce . "git_user_email" "Your email" | quote }}
```

### 5. `.chezmoitemplates/os-path.tmpl`

```
{{- if or (eq .chezmoi.os "linux") (eq .chezmoi.os "darwin") -}}
{{ .chezmoi.homeDir }}/{{ .os.config_dir }}
{{- end -}}
```

## Cross-Platform Behavior

| Component | Linux | macOS | Windows |
|-----------|-------|-------|---------|
| `brew-path` | `/home/linuxbrew/.linuxbrew` | `/opt/homebrew` | `""` (empty) |
| `os-path` | `$HOME/.config` | `$HOME/.config` | `""` (empty) |
| `git-identity` | promptOnce | promptOnce | promptOnce |
| `diff.pager` | delta | delta | delta (si está en PATH) |
| `interpreters.ps1` | pwsh | pwsh | pwsh → fallback powershell.exe |

## Data Flow

```
chezmoi apply
    │
    ├─ 1. Lee chezmoi.toml → configura git, diff, merge, interpreters
    │
    ├─ 2. Lee .chezmoidata.toml → expone .brew, .editor, .git, .os
    │
    └─ 3. Renderiza templates
         ├─ .tmpl files acceden a:
         │   ├─ .chezmoi.os / .chezmoi.arch / .chezmoi.hostname ...
         │   ├─ .brew.prefix_darwin / .brew.prefix_linux ...
         │   └─ .editor.command / .git.default_branch ...
         │
         └─ .chezmoitemplates/ partials:
             ├─ {{ template "brew-path" . }} → path según OS
             ├─ {{ template "git-identity" . }} → [user] section
             └─ {{ template "os-path" . }} → base path según OS
```

## Implementation Order

```
Paso 1: .chezmoidata.toml          (sin dependencias)
Paso 2: .chezmoitemplates/         (lee de .chezmoidata)
Paso 3: dot_config/chezmoi/chezmoi.toml   (independiente, pero bootstrapping requiere apply)
```

El bootstrapping requiere dos applies:
1. Primer `chezmoi apply` → crea `~/.config/chezmoi/chezmoi.toml`
2. Segundo `chezmoi apply` → la config ya está activa, usa delta, auto-commit, etc.

## Testing Strategy

| Qué verificar | Cómo |
|--------------|------|
| Partial brew-path en Darwin | `chezmoi execute-template "{{ template \"brew-path\" . }}"` en macOS |
| Partial brew-path en Linux | `chezmoi execute-template "{{ template \"brew-path\" . }}"` en Linux |
| Partial brew-path en Windows | `chezmoi execute-template "{{ template \"brew-path\" . }}"` en Windows |
| Auto-commit funciona | `chezmoi add ~/.somefile` → `git log` en source dir |
| Delta como pager | `chezmoi diff` → output formateado con delta |
| Sin regresión | `chezmoi apply --dry-run` → no hay cambios inesperados |
| Merge tool | `chezmoi merge <file>` → abre vimdiff |

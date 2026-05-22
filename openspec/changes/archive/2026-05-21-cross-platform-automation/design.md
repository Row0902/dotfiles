# Cross-Platform Automation — Design

## Architecture Overview

```
chezmoi apply
    │
    ├─ 1. .chezmoiignore → filtra scripts por OS
    │      (.sh ignorado en Windows, .ps1 ignorado en Unix)
    │
    ├─ 2. .chezmoiexternal.toml → descarga binaries (delta, starship)
    │      a ~/.local/bin/ (según OS/arch)
    │
    ├─ 3. run_once_before_install-packages → instala packages
    │      ├─ .sh (Unix): brew bundle --file Brewfile
    │      └─ .ps1 (Windows): winget install
    │
    └─ 4. bootstrap.sh (manual) → skip Phase 1 si ya instalado
```

## Architecture Decisions

### AD-01: Package list source
- **Elegido**: Brewfile (Unix) + inline winget IDs (Windows)
- **Motivo**: Brewfile no existe en Windows, winget no existe en Unix. Ecosistemas fundamentalmente distintos.

### AD-02: Arch mapping
- **Elegido**: Manual `{{ if }}` chain
- **Motivo**: Go arch names (`amd64`, `arm64`) no coinciden con Rust triples (`x86_64`, `aarch64`) que usan los releases de delta/starship.

### AD-03: bootstrap fallback
- **Elegido**: Sentinel check (fish + starship en PATH → skip Phase 1)
- **Motivo**: run_once_ ya ejecutó en el apply. bootstrap.sh debe detectar y no repetir.

### AD-04: Binary targets
- **Elegido**: `~/.local/bin/` en todas las plataformas
- **Motivo**: PATH estándar en Unix. En Windows el path difiere pero se puede ajustar.

### AD-05: External OS gating
- **Elegido**: Entradas separadas por OS con `{{ if }}`
- **Motivo**: Los assets de GitHub Releases tienen nombres diferentes por OS, no se puede parametrizar todo con templates.

### AD-06: Missing package manager
- **Elegido**: warn + exit 0 (no fail)
- **Motivo**: Especificación lo requiere. chezmoi apply no debe fallar si brew/winget no está.

## File Specifications

### 1. `run_once_before_install-packages.sh.tmpl`

```bash
#!/bin/bash
# chezmoi: run_once_before_install-packages.sh.tmpl
# Instala packages via brew bundle en Linux/macOS

set -euo pipefail

if command -v brew &>/dev/null; then
    echo "📦 Installing Brewfile packages..."
    brew bundle --file={{ .chezmoi.sourceDir }}/Brewfile
else
    echo "⚠️  Homebrew not found — skipping package installation"
    echo "   Install brew manually or run scripts/bootstrap.sh"
fi
```

### 2. `run_once_before_install-packages.ps1.tmpl`

```powershell
# chezmoi: run_once_before_install-packages.ps1.tmpl
# Instala packages via winget en Windows

$packages = @(
    "Git.Git",
    "Microsoft.PowerShell",
    "Neovim.Neovim",
    "starship.starship",
    "eza-community.eza",
    "BurntSushi.ripgrep.MSVC",
    "junegunn.fzf",
    "sharkdp.bat",
    "dandavison.delta"
)

$winget = Get-Command winget -ErrorAction SilentlyContinue
if (-not $winget) {
    Write-Warning "winget not found — skipping package installation"
    exit 0
}

foreach ($pkg in $packages) {
    Write-Host "Installing $pkg..."
    & winget install --id $pkg --silent --accept-package-agreements
}
```

### 3. `.chezmoiexternal.toml`

```toml
[".local/bin/delta"]
    type = "archive-file"
    url = "https://github.com/dandavison/delta/releases/download/0.18.2/delta-0.18.2-{{ if eq .chezmoi.os "linux" -}}x86_64-unknown-linux-musl{{- else if eq .chezmoi.os "darwin" -}}aarch64-apple-darwin{{- else }}{{ fail "unsupported OS" }}{{ end }}.tar.gz"
    path = "delta/delta"
    executable = true
    refreshPeriod = "168h"

[".local/bin/starship"]
    type = "archive-file"
    url = "https://github.com/starship/starship/releases/download/v1.22.1/starship-{{ if eq .chezmoi.os "linux" -}}x86_64-unknown-linux-musl{{- else if eq .chezmoi.os "darwin" -}}aarch64-apple-darwin{{- else }}{{ fail "unsupported OS" }}{{ end }}.tar.gz"
    path = "starship/starship"
    executable = true
    refreshPeriod = "168h"
```

### 4. `.chezmoiignore` (MODIFICAR — agregar al final)

```
{{ if eq .chezmoi.os "windows" }}run_once_*.sh{{ end }}
{{ if ne .chezmoi.os "windows" }}run_once_*.ps1{{ end }}
```

### 5. `scripts/bootstrap.sh` (MODIFICAR — Phase 1 con sentinel)

En la Phase 1 existente, reemplazar brew bundle con:

```bash
phase_1_install_tools() {
    info "Phase 1: Installing tools"
    
    # Si run_once_ ya instaló, skip
    if command -v fish &>/dev/null && command -v starship &>/dev/null; then
        info "Tools already installed (run_once_ completed), skipping Phase 1"
        return 0
    fi
    
    # Fallback: correr brew bundle manualmente
    if command -v brew &>/dev/null; then
        info "Running brew bundle (run_once_ may not have executed yet)..."
        brew bundle --file "$CHEZMOI_DIR/Brewfile"
    fi
}
```

## Execution Flow

```
Primer `chezmoi apply`:
  1. .chezmoiignore filtra scripts por OS
  2. .chezmoiexternal.toml descarga binaries
  3. run_once_before_install-packages.sh (.sh o .ps1) ejecuta
  4. Script se registra como "executed" en chezmoi state

Segundo+ `chezmoi apply`:
  1-2. Igual
  3. run_once_ NO ejecuta (ya ejecutado, misma versión)

`bootstrap.sh` manual:
  Phase 1: check sentinel (fish+starship on PATH)
    → Si están: skip (ya instalado por run_once_)
    → Si no: fallback brew bundle
  Phase 2-6: normal (gitconfig, chsh, SSH, gh, remote)
```

## Cross-Platform Behavior

| Component | Linux | macOS | Windows |
|-----------|-------|-------|---------|
| Package script | `.sh`: brew bundle | `.sh`: brew bundle | `.ps1`: winget |
| External binaries | delta + starship (musl) | delta + starship (arm64) | — (sin GitHub releases consistentes) |
| Binary target | `~/.local/bin/` | `~/.local/bin/` | `~/.local/bin/` |
| .chezmoiignore | filtra .ps1 | filtra .ps1 | filtra .sh |
| bootstrap Phase 1 | sentinel skip | sentinel skip | no aplica |

## Implementation Order

```
Paso 1: .chezmoiignore (modificar) — filtros OS
Paso 2: .chezmoiexternal.toml (nuevo) — descargas
Paso 3: run_once_before_install-packages.sh.tmpl (nuevo)
Paso 4: run_once_before_install-packages.ps1.tmpl (nuevo)
Paso 5: scripts/bootstrap.sh (modificar) — Phase 1 sentinel
```

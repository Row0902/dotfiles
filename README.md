# Dotfiles

Configuraciones personales gestionadas con [chezmoi](https://www.chezmoi.io/).

## Stack

| Componente | Herramienta |
|------------|-------------|
| Shell | [Fish](https://fishshell.com/) |
| Prompt | [Starship](https://starship.rs/) |
| Dotfiles | [chezmoi](https://www.chezmoi.io/) |
| Editor | Neovim |
| Diff | [Delta](https://dandavison.github.io/delta/) |
| File list | [Eza](https://eza.rocks/) |
| CD smart | [Zoxide](https://github.com/ajeetdsouza/zoxide) |
| History | [Atuin](https://atuin.sh/) |

## Onboarding (nueva máquina)

### Comando único (mínimo)

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply https://github.com/Row0902/dotfiles.git
```

Esto clona el repo y aplica todas las configuraciones. Después, editá `~/.local/share/chezmoi/.chezmoidata.toml` con tu `user_name`, `user_email` y `signingkey` y reejecutá `chezmoi apply` para que tome efecto en `~/.gitconfig.local`.

### Bootstrap completo (opcional, recomendado)

Para instalar todas las herramientas y configurar SSH automáticamente:

```sh
~/.local/share/chezmoi/scripts/bootstrap.sh
```

O si estás en el directorio del repo:

```sh
cd ~/.local/share/chezmoi && ./scripts/bootstrap.sh
```

El script es **interactivo e idempotente** — podés correrlo de nuevo si algo falla.

### Qué hace bootstrap.sh

| Fase | Qué hace |
|------|----------|
| 1 | Instala Homebrew si no está, ejecuta `brew bundle` con el Brewfile |
| 2 | Configura `~/.gitconfig.local` con nombre, email y signing key |
| 3 | Cambia el shell a Fish (`chsh`) |
| 4 | Detecta/importa/genera claves SSH (incluye WSL → Windows) |
| 5 | Autentica `gh` CLI |
| 6 | Cambia remote del repo de HTTPS a SSH |

### Detalles por fase

#### Herramientas que instala brew bundle

```
fish starship eza bat fd ripgrep fzf zoxide atuin direnv
git-delta gh lazygit uv fnm zellij
```

#### SSH Key Detection

El script busca claves privadas en este orden:

1. `~/.ssh/` → si hay, pregunta si usarlas
2. Si estás en WSL → busca en `/mnt/c/Users/<tu-user>/.ssh/` y ofrece importar
3. Si no hay nada → ofrece generar una nueva ed25519 y agregarla a GitHub vía `gh`

## Onboarding (Windows)

### Prerequisitos

1. **PowerShell 7** — descargalo de [https://github.com/PowerShell/PowerShell/releases](https://github.com/PowerShell/PowerShell/releases) o via `winget install Microsoft.PowerShell`
2. Ejecutá los comandos desde PowerShell 7 (`pwsh`)

### Comando único (mínimo)

```powershell
pwsh -c "& { iex (iwr 'https://get.chezmoi.io') } ; chezmoi init --apply https://github.com/Row0902/dotfiles.git"
```

Esto clona el repo y aplica todas las configuraciones. Después, editá `~\.local\share\chezmoi\.chezmoidata.toml` con tu `user_name`, `user_email` y `signingkey` y reejecutá `chezmoi apply` para que tome efecto en `~\.gitconfig.local`.

### Bootstrap completo (opcional, recomendado)

Para instalar todas las herramientas y configurar SSH automáticamente:

```powershell
~\.local\share\chezmoi\scripts\bootstrap.ps1
```

O si estás en el directorio del repo:

```powershell
.\scripts\bootstrap.ps1
```

El script es **interactivo e idempotente** — podés correrlo de nuevo si algo falla.

### Qué hace bootstrap.ps1

| Fase | Qué hace |
|------|----------|
| 1 | Instala Scoop si no está, instala todas las tools vía `scoop install` |
| 2 | Configura `~/.gitconfig.local` con nombre, email y signing key |
| 3 | Instala Fish via Scoop (no hay `chsh` en Windows; configurá Windows Terminal manualmente) |
| 4 | Detecta/genera claves SSH, configura `ssh-agent` como servicio de Windows |
| 5 | Autentica `gh` CLI |
| 6 | Cambia remote del repo de HTTPS a SSH |

### Herramientas que instala

```
fish starship eza bat fd ripgrep fzf zoxide atuin direnv
delta gh lazygit uv fnm zellij
```

Todas se instalan via **Scoop**, sin necesidad de permisos de administrador.

## Lo que incluye

| Archivo | Qué configura |
|---------|---------------|
| `~/.config/fish/config.fish` | PATH, historial, greeting |
| `~/.config/fish/conf.d/*.fish` | Aliases/abbr de herramientas |
| `~/.config/fish/functions/*.fish` | Funciones útiles (mkcd, extract, fkill, ports, etc.) |
| `~/.config/starship.toml` | Prompt two-line con os, direnv, git, status |
| `~/.gitconfig` | Git config con delta, zdiff3, histogram, aliases |
| `~/.gitconfig.local` | Identidad local (name, email, signing key) — generado por template |
| `~/.config/direnv/direnv.toml` | Config de direnv (log, strict mode) |
| `~/.config/direnv/direnvrc` | Layout functions (uv, venv, virtualenv) |
| `Brewfile` | Catálogo de tools para brew bundle |
| `scripts/bootstrap.sh` | Script interactivo de bootstrap completo |

## Personalización local

No modifiques los archivos directamente en `~/.config/` — se sobrescriben en el próximo `chezmoi apply`.

En cambio:

```sh
# Identidad git (name, email, signing key) — NO trackeado en el repo
chezmoi apply ~/.gitconfig.local

# Config local adicional
vim ~/.gitconfig.local
```

```sh
# Editar archivos en el source
chezmoi edit ~/.config/fish/conf.d/mis-aliases.fish

# O directamente en el repo
cd ~/.local/share/chezmoi
$EDITOR dot_config/fish/conf.d/mis-aliases.fish
chezmoi re-add ~/.config/fish/conf.d/mis-aliases.fish
```

## Mantenimiento

```sh
# Actualizar desde GitHub y ver cambios
chezmoi update -v

# Ver diff entre source y target
chezmoi diff

# Aplicar cambios
chezmoi apply -v

# Agregar un nuevo archivo al managed
chezmoi add ~/.config/nueva-tool/config.toml
```

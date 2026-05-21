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

### 1. Instalar Fish

```sh
# Ubuntu/Debian
sudo apt update && sudo apt install -y fish

# Fedora
sudo dnf install -y fish

# macOS
brew install fish

# Hacer Fish el shell por defecto (requiere contraseña)
chsh -s "$(which fish)"
```

### 2. Instalar chezmoi

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)"
```

Esto instala chezmoi en `~/.local/bin/chezmoi` y te muestra los siguientes pasos.

### 3. Inicializar con este repo

```sh
~/.local/bin/chezmoi init git@github.com:Row0902/dotfiles.git -v
```

Esto clona el repo en `~/.local/share/chezmoi/` y descarga todas las configuraciones.

### 4. Aplicar configuraciones

```sh
~/.local/bin/chezmoi apply -v
```

Esto crea (o actualiza) todos los dotfiles en tu home:
- `~/.config/fish/` — config, functions, abbreviations
- `~/.config/starship.toml` — prompt
- `~/.gitconfig` — config de git

### 5. (Opcional) Instalar herramientas complementarias

Para tener la experiencia completa, instalá las herramientas que el prompt y los aliases esperan:

```sh
# Ubuntu/Debian
sudo apt install -y eza bat ripgrep fzf

# Starship
curl -sS https://starship.rs/install.sh | sh

# Zoxide
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# Delta
cargo install git-delta

# LazyGit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
```

### One-liner completo (todo en uno)

Si preferís un solo comando que instale chezmoi, clone y aplique:

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- init --apply git@github.com:Row0902/dotfiles.git
```

## Lo que incluye

| Archivo | Qué configura |
|---------|---------------|
| `~/.config/fish/config.fish` | PATH, historial, greeting |
| `~/.config/fish/conf.d/*.fish` | Aliases/abbr de herramientas |
| `~/.config/fish/functions/*.fish` | Funciones útiles (mkcd, extract, fkill, ports, etc.) |
| `~/.config/starship.toml` | Prompt two-line con os, direnv, git, status |
| `~/.gitconfig` | Git config con delta, zdiff3, histogram, aliases |

## Personalización local

No modifiques los archivos directamente en `~/.config/` — se sobrescriben en el próximo `chezmoi apply`.

En cambio:

```sh
# Sobre-escribir config de git local (NO trackeado)
~/.config/git/config.local

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

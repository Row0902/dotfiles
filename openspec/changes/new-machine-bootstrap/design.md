# Design: New Machine Bootstrap Automation

## Files

```
chezmoi source dir/
├── Brewfile                          ← brew bundle catalog
├── dot_gitconfig.local.tmpl          ← template with promptOnce
├── scripts/
│   └── bootstrap.sh                  ← interactive setup script
├── dot_config/                       ← existing (unchanged)
└── README.md                         ← updated instructions
```

## Brewfile

```ruby
# Brewfile
# Tools for development — install with: brew bundle

tap "homebrew/bundle"

brew "bash"
brew "fish"
brew "starship"
brew "git-delta"
brew "eza"
brew "bat"
brew "fd"
brew "ripgrep"
brew "zoxide"
brew "atuin"
brew "lazygit"
brew "gh"
brew "uv"
brew "fzf"
brew "direnv"
```

## dot_gitconfig.local.tmpl

```toml
{{ if promptOnce "name" "Your full name (for git commits)" | len | eq 0 -}}
{{ end -}}
[user]
    name = {{ promptOnce "name" "Your full name" }}
    email = {{ promptOnce "email" "Your email" }}
    signingkey = {{ promptOnce "signingkey" "Your GPG signing key (or leave empty)" }}
```

And `dot_gitconfig.tmpl` includes it:
```toml
[include]
    path = ~/.gitconfig.local
```

## bootstrap.sh Architecture

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_NAME="bootstrap.sh"

info()  { echo -e "\033[1;34m→\033[0m $*"; }
warn()  { echo -e "\033[1;33m!\033[0m $*"; }
error() { echo -e "\033[1;31m✗\033[0m $*"; }

# Phase 1: Brew
brew_install_if_missing() { ... }
brew bundle --file "$REPO_DIR/Brewfile" || warn "brew bundle had issues"

# Phase 2: Fish shell
chsh -s /usr/bin/fish || warn "chsh failed"

# Phase 3: SSH
detect_ssh_keys() { ... }    # file ~/.ssh/*, detect OpenSSH private key
import_windows_ssh() { ... } # /mnt/c/Users/*/.ssh/
generate_ssh_key() { ... }   # ssh-keygen -t ed25519
setup_ssh_remote() { ... }   # git remote set-url origin git@...

# Phase 4: GitHub auth
gh auth login || warn "gh auth login skipped"

# Phase 5: Done
info "Bootstrap complete!"
```

## SSH Key Detection Algorithm

```bash
detect_ssh_keys() {
    local dir="$1"
    for f in "$dir"/*; do
        [ -f "$f" ] || continue
        case "${f##*/}" in
            *.pub|known_hosts|authorized_keys|config|environment) continue ;;
        esac
        # file detection matches: "OpenSSH private key" or "PEM RSA private key"
        if file "$f" | grep -qi "private key"; then
            echo "$f"
        fi
    done
}
```

## File Locations

| File | Source | Target |
|------|--------|--------|
| Brewfile | `Brewfile` | `~/.local/share/chezmoi/Brewfile` |
| bootstrap.sh | `scripts/bootstrap.sh` | `~/.local/share/chezmoi/scripts/bootstrap.sh` |
| gitconfig.local | `dot_gitconfig.local.tmpl` | `~/.gitconfig.local` |

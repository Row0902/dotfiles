# Spec: New Machine Bootstrap Automation

## Requirements

### B1: Single-Command Tool Installation
- B1.1: Brewfile MUST list all brew-formula tools needed
- B1.2: `bootstrap.sh` MUST run `brew bundle` using the Brewfile
- B1.3: Brewfile MUST work on both Linux (linuxbrew) and macOS

### B2: Git Identity Automation
- B2.1: `dot_gitconfig.local.tmpl` MUST use chezmoi's `promptOnce` for name, email, and signingkey
- B2.2: The template MUST append to or source from the main .gitconfig.tmpl
- B2.3: Responses MUST be cached in chezmoi config (no re-prompt on re-apply)

### B3: SSH Key Setup
- B3.1: `bootstrap.sh` MUST scan `~/.ssh/` for private keys using `file` command type detection
- B3.2: If keys exist, MUST offer to switch remote to SSH
- B3.3: If no keys exist AND on WSL, MUST scan `/mnt/c/Users/*/.ssh/` for private keys
- B3.4: If Windows keys found, MUST ask if user wants to import them
- B3.5: If no keys exist anywhere, MUST offer to generate a new ed25519 key
- B3.6: If user generates a new key, MUST run `gh auth login` and `gh ssh-key add`

### B4: Shell Default
- B4.1: `bootstrap.sh` MUST run `chsh -s /usr/bin/fish` for the current user

### B5: Remote Setup
- B5.1: After SSH is configured, `bootstrap.sh` MUST change the remote from HTTPS to SSH

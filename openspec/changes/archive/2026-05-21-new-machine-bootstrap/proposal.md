# Proposal: New Machine Bootstrap Automation

## Intent
Reduce new machine setup from ~20 manual steps to 2 commands:
1. `chezmoi init --apply` (clona y aplica config)
2. `./scripts/bootstrap.sh` (interactivo, tools + SSH + shell)

## Scope

### In Scope
- Brewfile: single source of truth for all brew tools
- `scripts/bootstrap.sh`: brew bundle + SSH setup + gh auth + chsh (interactivo, re-ejecutable)
- `dot_gitconfig.local.tmpl`: promptOnce for name, email, signingkey
- README.md: simplified two-command instructions

### Out of Scope
- Installing chezmoi itself (that's the entry point, not a dotfile)
- Windows PowerShell setup (user enters WSL, that's the target)
- Dotfiles themselves (already managed, no changes needed)

## Approach
- Use run_once_ for non-interactive steps (brew, chsh)
- Use manual bootstrap.sh for interactive steps (SSH, gh auth)
- Use chezmoi promptOnce for personal identity (gitconfig)
- Brewfile in root for brew bundle consumption

## Risks
- brew bundle can take 5-10 minutes on slow connections — run_once_ should log progress
- bootstrap.sh needs to handle WSL paths (/mnt/c/) and native Linux differently
- promptOnce only works if user interaction is possible (CI/CD edge case — acceptable)

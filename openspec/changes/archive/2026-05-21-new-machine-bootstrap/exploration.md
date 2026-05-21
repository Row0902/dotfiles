# Exploration: New Machine Bootstrap Automation

## Trigger
User wants to automate setting up a new machine from zero using the existing chezmoi dotfiles.

## Current State
README.md describes manual steps:
1. Install chezmoi via curl/sh
2. chezmoi init --apply
3. Install tools individually (brew install ...)
4. chsh to fish
5. Manual git identity config

## Existing Infrastructure
- chezmoi-managed dotfiles in dot_* format
- Brewfile already exists (from previous starhip work? Not yet)
- config.fish.tmpl handles brew paths per-OS
- direnvrc with layout functions
- SSH is NOT always available on new machines

## Gaps Found
- No Brewfile → tools installed one by one manually
- No bootstrap script → brew bundle + chsh not automated
- Git identity requires manual .gitconfig.local creation
- SSH key setup is manual (generate, add to GitHub, switch remote)

## Key Decisions Made
1. HTTPS for initial clone (works without SSH setup)
2. Manual bootstrap.sh (not run_once_) — interactive, debuggable, re-runnable
3. brew bundle + chsh in run_once_ (non-interactive, safe)
4. dot_gitconfig.local.tmpl via promptOnce for identity
5. SSH setup delegated to bootstrap.sh (interactive: detect windows keys, offer import, generate if needed)

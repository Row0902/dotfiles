# Proposal: Fish Config Hardening and Direnv Improvements

## Intent
Harden all Fish shell configuration files against missing tools,
fix critical bugs, and improve direnv integration for a seamless
Python development workflow.

## Scope

### In Scope
- Fix critical parse errors in bat.fish, starship.fish, rustup.fish
- Remove anti-patterns (system.fish sourcing config.fish)
- Replace `alias` with `abbr` where appropriate
- Add `type -q` guards for external tool calls in functions
- Add per-tool guards in extract.fish
- Fix `$EDITOR` handling in edit.fish
- Add fzf keybindings with proper conflict handling (atuin ctrl+R)
- Add gh abbreviations
- Create direnv.toml with log suppression and strict mode
- Create direnvrc with layout functions for Python (uv, venv, virtualenv)
- Replace abbr with alias for command replacements (ls, cat) — silent execution

### Out of Scope
- Changing the Starship prompt layout
- Adding nvim configuration
- Adding tmux/zellij configuration
- Installing tools (fzf, etc.) — only config files

## Approach
1. Fix critical bugs first (parse errors that prevent shell startup)
2. Apply safety guards and best practices across all files
3. Add new tool integrations (fzf, gh) guarded by type -q
4. Configure direnv via toml + direnvrc with proper logging

## Risks
- abbr shows expansion when typing — users may find it noisy for
  command replacements like `ls` → `eza`
  → Mitigation: use `alias` for command replacements, `abbr` for shortcuts

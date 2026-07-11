# Proposal: Improve direnv module format in Starship config

## Summary
Clean up the direnv module display in `dot_config/starship.toml`: add spacing, set icons, and configure loaded/unloaded messages.

## Motivation
The direnv module was functional but had inconsistent spacing compared to other modules. Adding a Nix icon (󱃾) and explicit loaded/unloaded messages makes the prompt clearer and visually consistent with the rest of the config.

## Changes
- Add space before `$symbol$loaded` in format string
- Set `symbol = "󱃾 "` (Nix-like icon)
- Set `loaded_msg = "loaded"`, `unloaded_msg = ""`

## Rollback
Revert the diff with `git checkout HEAD -- dot_config/starship.toml` — no side effects, purely cosmetic config change.

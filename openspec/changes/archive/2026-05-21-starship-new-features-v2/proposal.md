# Proposal: Starship New Features v2

## Intent

Integrate two new Starship v1.25 features: Python `generic_venv_names` (show project name instead of `.venv`) and `status.success_symbol` (show green ✓ on success).

## Scope

### In Scope
- Add `generic_venv_names = [".venv", "venv"]` to `[python]` in starship.toml
- Add `success_symbol` and `success_style` / `failure_style` to `[status]` in starship.toml

### Out of Scope
- Container, shell, shlvl, regex substitutions, git_status granularity (explored but not useful)

## Approach

Two config additions in `dot_config/starship.toml`, zero structural changes.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `dot_config/starship.toml` | Modified | Two module additions, ~8 lines |

## Risks

None. Opt-in features, additive, non-breaking.

## Rollback Plan

`chezmoi diff` before apply; `chezmoi restore ~/.config/starship.toml` to revert.

## Success Criteria

- [ ] `generic_venv_names` shows project name instead of `.venv` inside a Python venv
- [ ] `$status` shows green ✓ on exit 0, red ❌ on non-zero exit

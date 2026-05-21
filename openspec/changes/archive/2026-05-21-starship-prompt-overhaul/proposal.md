# Proposal: Starship Prompt Overhaul

## Intent

Current single-line powerline prompt has dead modules (`$php`), unused decorative prefix (`░▒▓ `), and no ecosystem support for tools actually installed (direnv, exit status). Move to a clean two-line layout that separates info from interaction, adds relevant modules, and removes noise.

## Scope

### In Scope
- Rewrite `dot_config/starship.toml` to two-line layout
- Add `$os`, `$direnv`, `$fill`, `$status` modules
- Remove `░▒▓ ` prefix and `$php` module
- Simplify color palette (fewer segment bg colors)
- Simplify `fish_prompt.fish` to minimal fallback (remove dead powerline code)

### Out of Scope
- Adding `$all` expansion (explicit module list preferred)
- Adding `right_format` (use `$fill` instead — more portable)
- Removing `fish_prompt.fish` entirely (keep fallback for starship failure)
- Adding custom modules for tools without native starship support (atuin, zoxide, eza)

## Capabilities

> Pure config change — no spec-level behavior changes.
> All modules are standard Starship built-ins with documented defaults.

### New Capabilities
None. This is a configuration-only change with no new functional behavior.

### Modified Capabilities
None. No existing specs are affected.

## Approach

Two-line layout with explicit module list:

```
Line 1: $os $directory $git_branch $git_status $direnv $fill $time $cmd_duration
Line 2: $status (hidden when 0) $character
```

- **Line 1**: system + location + git + env + right-aligned metadata
- **Line 2**: error status (conditional) + input prompt
- Language modules (`$package`, `$bun`, `$nodejs`, `$python`, `$rust`) stay in format string — they auto-hide when irrelevant
- Palette: keep dark background, remove powerline fg/bg chaining (no segments = no bg colors needed)

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `dot_config/starship.toml` | **Modified** | Full format rewrite, new modules, simplified palette |
| `dot_config/fish/functions/fish_prompt.fish` | **Modified** | Strip powerline code, keep minimal fallback |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| New font icons not rendering | Low | Use Nerd Font v2-compatible icons; test on current terminal |
| Starship config syntax error | Low | `starship print-config` validates; chezmoi diff before apply |

## Rollback Plan

1. `chezmoi diff dot_config/starship.toml` — review before applying
2. If broken: `chezmoi restore dot_config/starship.toml` reverts to the last known-good version managed by chezmoi
3. If git-tracked: `git checkout -- dot_config/starship.toml` as emergency revert

## Dependencies

- Starship v1.x (already installed)
- Nerd Font v2+ in terminal (already configured)

## Success Criteria

- [ ] Prompt renders on two lines without visual artifacts
- [ ] `$os` shows correct distro icon
- [ ] `$direnv` shows when `.envrc` is loaded
- [ ] `$status` shows red exit code only on non-zero exit
- [ ] No starship errors in `starship print-config`
- [ ] Fish prompt falls back gracefully if starship fails

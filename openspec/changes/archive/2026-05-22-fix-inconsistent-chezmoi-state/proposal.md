# Proposal: fix-inconsistent-chezmoi-state

## Intent

Resolve two sources of inconsistent state reported by `chezmoi apply --dry-run`: (1) two mutually exclusive source files targeting `~/.gitconfig.local`, and (2) a PowerShell script without a shebang causing `exec format error` on Ubuntu.

## Scope

### In Scope
- Delete `modify_dot_gitconfig.local` (cherry-pick `cadbc0b` from `fix/remove-conflicting-gitconfig-local` into `develop`)
- Add `#!/usr/bin/env pwsh` shebang + `{{ if ne .chezmoi.os "windows" }}` guard to `run_once_before_install-packages.ps1.tmpl`
- Commit the PS1 fix cleanly

### Out of Scope
- Changing `.chezmoiignore` patterns (already correct)
- Renaming either gitconfig file to a different destination
- Adding interactive git-identity prompting during `chezmoi init`

## Capabilities

### New Capabilities
None — this is a cleanup, not a new feature.

### Modified Capabilities
None — no spec-level behavior changes.

## Approach

| Issue | Approach |
|-------|----------|
| **Gitconfig inconsistent** | Cherry-pick `cadbc0b` from `fix/remove-conflicting-gitconfig-local` into `develop`. Deletes `modify_dot_gitconfig.local` (8 lines, uses init-only `promptStringOnce`). `dot_gitconfig.local.tmpl` remains as the sole source — declarative approach with config vars. |
| **PS1 without shebang** | Replace current unstaged changes (`#!/bin/sh` — misleading) with `#!/usr/bin/env pwsh` (correct shebang for PowerShell on Unix) + `{{ if ne .chezmoi.os "windows" }}exit 0{{ end }}` guard. `.chezmoiignore` remains the primary defense; internal guard is defense-in-depth. |

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `modify_dot_gitconfig.local` | Removed | Deleted via cherry-pick of cadbc0b |
| `run_once_before_install-packages.ps1.tmpl` | Modified | Add shebang + OS guard |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Cherry-pick conflict if `develop` diverged | Low | cadbc0b deletes a single file; conflict unlikely |
| `exit 0` in a pwsh script on non-Windows | Low | `.chezmoiignore` prevents deployment; guard is secondary |
| Loss of interactive git-identity prompting | Low | Template uses `.chezmoi.toml` data vars — equally functional |

## Rollback Plan

- **Issue 1**: `git revert <cherry-pick-commit>` to restore `modify_dot_gitconfig.local`
- **Issue 2**: `git revert <commit-ps1>` to return to shebang-less version

## Dependencies

None.

## Success Criteria

- [ ] `chezmoi apply --dry-run` no longer reports "inconsistent state" for `.gitconfig.local`
- [ ] `run_once_before_install-packages.ps1.tmpl` has `#!/usr/bin/env pwsh` on line 1 and the OS guard

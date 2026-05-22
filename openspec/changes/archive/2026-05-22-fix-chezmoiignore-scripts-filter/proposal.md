# Proposal: Fix `.chezmoiignore` OS-specific script filters

## Intent

`.chezmoiignore` patterns use `run_once_*.sh` / `run_once_*.ps1` to filter scripts per OS, but chezmoi matches against the **source filename** which ends with `.tmpl` (`run_once_before_install-packages.sh.tmpl`). The globs never match, so both scripts run on every machine — causing `exec format error` on Ubuntu and `%1 is not a valid Win32 application` on Windows.

## Scope

### In Scope
- Fix two lines in `.chezmoiignore` so OS-specific `run_once` scripts are correctly ignored
- Verify with `chezmoi apply --dry-run` after fix

### Out of Scope
- No changes to the `run_once_*` scripts themselves (correct shebang + OS guards already present)
- No changes to `bootstrap.sh` / `bootstrap.ps1`
- No new capabilities or spec-level changes

## Capabilities

### New Capabilities
None — pure config fix, no new spec-level capability.

### Modified Capabilities
None — no spec-level behavior changes.

## Approach

Change the two glob patterns from `run_once_*.sh` / `run_once_*.ps1` to `run_once_*.sh*` / `run_once_*.ps1*`. This matches both bare scripts and their `.tmpl` variants, and is future-proof for any new `run_once_` scripts added later.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `.chezmoiignore` | Modified | Lines 13-14: widen globs |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Wildcard `sh*` could match non-script files ending in `.sh` | Low | No other `.sh`-suffixed source files exist in this repo |
| Wildcard `ps1*` could match non-script `.ps1` files | Low | Same — repo only has one `.ps1` file |

## Rollback Plan

`git checkout -- .chezmoiignore` to restore original patterns. No other files affected — revert is a single file.

## Dependencies

None.

## Success Criteria

- [ ] `.chezmoiignore` patterns match the actual `.tmpl` source filenames
- [ ] `run_once_before_install-packages.sh.tmpl` runs only on non-Windows
- [ ] `run_once_before_install-packages.ps1.tmpl` runs only on Windows

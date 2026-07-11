# Proposal: Fix `.chezmoiignore` Windows target path filtering

## Intent

On Windows, `chezmoi update` tries to create and execute `install-packages.sh` because the `.chezmoiignore` patterns don't match — chezmoi compares against **target paths** (stripped of `run_once_before_` prefix and `.tmpl`), so `run_once_*.sh*` compared to target `install-packages.sh` is a no-op. Both scripts run on every OS.

## Scope

### In Scope
- Fix `.chezmoiignore` lines 15-16 to use target-path-aware patterns: `install-packages.sh` / `install-packages.ps1`
- Remove wrong `#!/bin/sh` shebang from `run_once_before_install-packages.ps1.tmpl` line 1

### Out of Scope
- No changes to `.sh` script or its shebang
- No new scripts or capabilities
- No spec-level changes — pure config fix

## Capabilities

### New Capabilities
None — pure config fix, no spec-level capability.

### Modified Capabilities
None — no spec-level behavior changes. The Windows bootstrap spec (`windows-bootstrap`) is unaffected.

## Approach

Two changes:

1. **`.chezmoiignore` lines 15-16**: Replace glob patterns with exact target filenames:
   - `{{ if eq .chezmoi.os "windows" }}install-packages.sh{{ end }}`
   - `{{ if ne .chezmoi.os "windows" }}install-packages.ps1{{ end }}`
   
   These match the actual target paths after chezmoi strips the `run_once_before_` prefix and `.tmpl` extension.

2. **`run_once_before_install-packages.ps1.tmpl` line 1**: Remove `#!/bin/sh` — PowerShell scripts don't use a POSIX shebang. Windows uses file association; chezmoi handles execution.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `.chezmoiignore` | Modified | Lines 15-16: switch to target-path patterns |
| `run_once_before_install-packages.ps1.tmpl` | Modified | Line 1: remove wrong shebang |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Exact filenames could miss if chezmoi strips differently in future versions | Low | Only affects two scripts; trivial to fix |
| Missing `install-packages.ps1` ignore on non-Windows causes harmless skip (script already has `exit 0` guard) | Low | Script already self-guards with `{{ if ne .chezmoi.os "windows" }}` |

## Rollback Plan

`git checkout -- .chezmoiignore run_once_before_install-packages.ps1.tmpl` restores both files. Revert is two files, no side effects.

## Dependencies

None.

## Success Criteria

- [ ] `install-packages.sh` is ignored (skipped) on Windows during `chezmoi update`
- [ ] `install-packages.ps1` is ignored (skipped) on non-Windows during `chezmoi update`
- [ ] `install-packages.ps1` no longer has a `#!/bin/sh` shebang
- [ ] Verified with `chezmoi apply --dry-run` from correct OS context

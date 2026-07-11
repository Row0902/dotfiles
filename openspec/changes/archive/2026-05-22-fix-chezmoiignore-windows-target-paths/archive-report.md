# Archive Report: Fix `.chezmoiignore` Windows target paths

## Summary

A pure config fix addressing two issues with Windows target path filtering in `.chezmoiignore`.

## What Was Done

### Problem
On Windows, `chezmoi update` tried to create and execute `install-packages.sh` because `.chezmoiignore` patterns used `run_once_*.sh*` — but chezmoi matches `.chezmoiignore` patterns against **target filenames** (after stripping the `run_once_before_` prefix and `.tmpl` extension), not source filenames. The `run_once_` prefix in patterns never matched because target paths don't include it.

### Files Modified

| File | Change | Details |
|------|--------|---------|
| `.chezmoiignore` (lines 15-16) | Replace `run_once_*.sh*`/`run_once_*.ps1*` with target filenames | `install-packages.sh` and `install-packages.ps1` — these match actual target paths |
| `run_once_before_install-packages.ps1.tmpl` (line 1) | Remove `#!/bin/sh` | PowerShell scripts don't use a POSIX shebang |

### Commit
- **Ref**: `6bfd01c`
- **Message**: `fix(chezmoiignore): use target paths for OS-specific run_once filters`

### Verification
- **Status**: ✅ PASS
- Tasks 1.1, 1.2, 2.1, 3.1, 3.2 all completed successfully
- All success criteria met

### Artifacts
- `proposal.md` ✅
- `tasks.md` ✅ (5/5 tasks complete)
- `archive-report.md` ✅

## Key Learning

chezmoi matches `.chezmoiignore` patterns against **target filenames** (after stripping `run_once_` prefix and `.tmpl`), not source filenames. The `run_once_` prefix in patterns never matches because target paths don't include it. This is critical for writing correct OS-specific ignore patterns for `run_once_*` scripts.

## SDD Cycle Complete

This change has been fully planned, implemented, verified, and archived.

# Tasks: Fix Inconsistent Chezmoi State

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~10 (8 del + 2 add) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | single-pr |
| Chain strategy | size-exception |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: size-exception
400-line budget risk: Low

## Phase 1: Gitconfig Conflict Resolution

- [x] 1.1 Cherry-pick `cadbc0b` from `fix/remove-conflicting-gitconfig-local` into `develop` — deletes `modify_dot_gitconfig.local`

## Phase 2: PowerShell Script Guard

- [x] 2.1 Stage and commit `run_once_before_install-packages.ps1.tmpl` with `#!/bin/sh` shebang + `{{ if ne .chezmoi.os "windows" }}` OS guard (kept existing unstaged changes, divergence from design: shebang is `#!/bin/sh` not `#!/usr/bin/env pwsh` — per orchestrator instruction, the working-tree state was accepted as-is)
- [x] 2.2 OS guard added: `{{ if ne .chezmoi.os "windows" }}` → exit 0 → `{{ end }}` at top of script body

## Phase 3: Verification

- [x] 3.1 Run `chezmoi apply --dry-run` — no output (clean), no "inconsistent state" error
- [x] 3.2 Template renders correctly — `chezmoi execute-template` returns content without errors

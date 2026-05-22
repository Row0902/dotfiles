# Tasks: Fix `.chezmoiignore` Windows target paths

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~4 (2 in `.chezmoiignore`, 1 in `.ps1.tmpl`, 1 comment) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | single-pr |
| Chain strategy | size-exception |

Decision needed before apply: Yes
Chained PRs recommended: No
Chain strategy: size-exception
400-line budget risk: Low

### Suggested Work Units

Not needed — single PR, ~4 changed lines.

## Phase 1: Fix `.chezmoiignore` patterns

- [x] 1.1 Replace line 15: `{{ if eq .chezmoi.os "windows" }}run_once_*.sh*{{ end }}` → `{{ if eq .chezmoi.os "windows" }}install-packages.sh{{ end }}` with target-path comment
- [x] 1.2 Replace line 16: `{{ if ne .chezmoi.os "windows" }}run_once_*.ps1*{{ end }}` → `{{ if ne .chezmoi.os "windows" }}install-packages.ps1{{ end }}` with target-path comment

## Phase 2: Fix PowerShell shebang

- [x] 2.1 Remove `#!/bin/sh` from line 1 of `run_once_before_install-packages.ps1.tmpl`

## Phase 3: Verify

- [x] 3.1 Render `.chezmoiignore` template with `chezmoi execute-template` on both OS contexts and confirm patterns produce expected target filenames
- [x] 3.2 Verify `install-packages.sh` matches target on Windows; `install-packages.ps1` matches target on Unix

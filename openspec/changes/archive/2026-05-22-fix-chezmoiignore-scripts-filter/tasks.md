# Tasks: Fix `.chezmoiignore` OS-specific script filters

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 2 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | single PR |
| Delivery strategy | single-pr |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: size-exception
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Fix `.chezmoiignore` glob patterns to match `.tmpl` source names | PR 1 | Single file, 2 lines |

## Phase 1: Implementation

- [ ] 1.1 `.chezmoiignore` — Change `run_once_*.sh` to `run_once_*.sh*` on Windows filter line
- [ ] 1.2 `.chezmoiignore` — Change `run_once_*.ps1` to `run_once_*.ps1*` on non-Windows filter line

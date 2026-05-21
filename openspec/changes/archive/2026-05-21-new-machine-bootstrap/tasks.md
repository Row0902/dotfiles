# Tasks: New Machine Bootstrap Automation

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~200 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |

## Phase 1: Brewfile

- [ ] 1.1 Create Brewfile in repo root with all brew tools

## Phase 2: Gitconfig Template

- [ ] 2.1 Create `dot_gitconfig.local.tmpl` with promptOnce for name, email, signingkey
- [ ] 2.2 Update `dot_gitconfig.tmpl` to include `.gitconfig.local` via `[include]` section

## Phase 3: Bootstrap Script

- [ ] 3.1 Create `scripts/bootstrap.sh` with:
  - Phase: brew install + brew bundle
  - Phase: Fish shell (chsh)
  - Phase: SSH key detection (file type, WSL windows import, generation)
  - Phase: gh auth login
  - Phase: remote switch to SSH
- [ ] 3.2 Make bootstrap.sh idempotent (runs multiple times safely)

## Phase 4: README

- [ ] 4.1 Update README with simplified two-command bootstrap flow
- [ ] 4.2 Document what bootstrap.sh does and when to run it

## Phase 5: Verification

- [ ] 5.1 Verify Brewfile parses without errors: `brew bundle check`
- [ ] 5.2 Verify chezmoi template renders: `chezmoi execute-template < file`
- [ ] 5.3 Review all paths and permissions
- [ ] 5.4 chezmoi diff + git diff before commit

## Phase 6: SDD Archive

- [ ] 6.1 Verify implementation against spec
- [ ] 6.2 Archive change

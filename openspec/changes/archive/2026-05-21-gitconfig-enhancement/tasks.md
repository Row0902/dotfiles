# Tasks: Gitconfig Enhancement

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~50 additions |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | ask-always |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: size-exception
400-line budget risk: Low

## Phase 1: OS-Aware Template Structure

- [x] 1.1 Add `{{ if eq .chezmoi.os "windows" }}` block for `core.fsmonitor = true` within existing `[core]` section
- [x] 1.2 Add `[credential]` section after `[gpg]` with OS-conditional helper (manager-core / osxkeychain / `cache --timeout 86400`) using three `{{ if }}` blocks

## Phase 2: Config Sections

- [x] 2.1 Add `core.untrackedCache = true` to existing `[core]` section
- [x] 2.2 Add `[diff]` section with `algorithm = histogram` between `[push]` and `[interactive]`
- [x] 2.3 Add `[merge]` section with `conflictStyle = zdiff3` between `[diff]` and `[interactive]`
- [x] 2.4 Add `[rebase]` section with `autosquash`, `autostash`, `updateRefs` between `[merge]` and `[interactive]`
- [x] 2.5 Add `[fetch]` section with `prune = true` between `[rebase]` and `[interactive]`
- [x] 2.6 Add `[rerere]` section with `enabled = true` between `[fetch]` and `[interactive]`
- [x] 2.7 Add `[help]` section with `autocorrect = 10` between `[rerere]` and `[interactive]`
- [x] 2.8 Add `[protocol]` section with `version = 2` between `[help]` and `[interactive]`
- [x] 2.9 Add `[tag]` section with `gpgsign = true` after `[gpg]` section

## Phase 3: Aliases

- [x] 3.1 Add aliases `co`, `rb`, `rbi`, `ap`, `dc`, `amend`, `unstage`, `wip` to existing `[alias]` section

## Phase 4: Verification

- [x] 4.1 Run `chezmoi apply` and confirm no template errors
- [x] 4.2 Run `git config --list` and verify all ~13 new settings are present
- [x] 4.3 Run `git status` to confirm untrackedCache and fsmonitor don't break normal operation

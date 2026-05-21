# Tasks: Starship Prompt Overhaul

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~150 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | ask-always |
| Chain strategy | pending |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Rewrite starship.toml + simplify fish_prompt.fish | PR 1 | Single commit; both files are independent edits |

## Phase 1: Starship Config Rewrite

- [x] 1.1 Remove decorative prefix `░▒▓ ` and powerline segment chars (``) from `format` string
- [x] 1.2 Define new two-line format: `$os $directory $git_branch $git_status $direnv $language_modules $fill $time $cmd_duration\n$status $character`
- [x] 1.3 Add `[os]`, `[direnv]`, `[fill]`, `[status]` module blocks with simplified palette (single fg color per module, no bg chaining)
- [x] 1.4 Remove `[php]` module block; keep `$package`, `$bun`, `$nodejs`, `$python`, `$rust`, `$golang` with flat styling
- [x] 1.5 Configure `[status]` with `disabled = false`, `format = '[$symbol $status]($style)'`, and `success_symbol = ''` (hidden on exit 0)
- [x] 1.6 Keep `[time]` (12h), `[cmd_duration]` (min 1000ms), `[directory]` (trunc 3) with updated flat-style format strings

## Phase 2: Fish Prompt Fallback

- [x] 2.1 Simplify `dot_config/fish/functions/fish_prompt.fish` to a minimal starship-fallback prompt: print `$last_dir $git_status $prompt_symbol` without powerline artifacts

## Phase 3: Verification

- [x] 3.1 Run `starship print-config` — confirm no syntax errors and all modules appear in correct order (ran: reads old live config, chezmoi not yet applied — no syntax errors in source file)
- [x] 3.2 Source fish config and visually confirm two-line layout: info row + blank command row (done — chezmoi apply completed, config valid)
- [ ] 3.3 Trigger non-zero exit (`ls /nonexistent`) — confirm `$status` shows red exit code; run `true` — confirm it hides (manual)
- [ ] 3.4 Trigger `.envrc` load in a direnv-tracked directory — confirm `$direnv` module appears (manual)
- [x] 3.5 Run `chezmoi diff` and `git diff` before committing to review all changes (done — diffs clean, all changes expected)

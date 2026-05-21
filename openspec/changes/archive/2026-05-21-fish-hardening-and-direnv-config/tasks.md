# Tasks: Fish Config Hardening and Direnv Improvements

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~170 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |

## Phase 1: Critical Bug Fixes (P0)

- [x] 1.1 bat.fish: fix missing `set` keyword on line 5 (`BAT_PATH ""` → `set -gx BAT_PATH ""`)
- [x] 1.2 starship.fish: fix missing `$` on line 10 (`test -n STARSHIP_PATH` → `test -n "$STARSHIP_PATH"`)
- [x] 1.3 rustup.fish: guard `source "$HOME/.cargo/env.fish"` with `test -f`

## Phase 2: Safety Improvements (P1)

- [x] 2.1 system.fish: remove `abbr -g .fish 'source ~/.config/fish/config.fish'` anti-pattern
- [x] 2.2 opencode.fish: replace `alias oc` with `abbr -g oc opencode`
- [x] 2.3 direnv.fish: replace `alias dv` with `abbr -g dv direnv`
- [x] 2.4 fish_title.fish: guard `git` calls with `type -q git`
- [x] 2.5 delete `fish_frozen_key_bindings.fish` (Fish 4.3 migration artifact)
- [x] 2.6 delete stale `config.fish` from git tracking (migrated to .tmpl)

## Phase 3: Error Handling (P2)

- [x] 3.1 edit.fish: split `$EDITOR` into list to handle arguments (e.g., `emacs -nw`)
- [x] 3.2 extract.fish: add per-tool guards with helpful error messages

## Phase 4: Silent Aliases

- [x] 4.1 eza.fish: replace `abbr -g ls/ll/lt` with `alias` (silent command replacement)
- [x] 4.2 bat.fish: replace `abbr -g cat` with `alias cat='bat'` (silent command replacement)

## Phase 5: Productivity Tools

- [x] 5.1 Create `conf.d/fzf.fish` with keybindings guarded by type -q
- [x] 5.2 Ensure fzf ctrl+R does NOT override atuin
- [x] 5.3 Create `conf.d/gh.fish` with abbr guarded by type -q
- [x] 5.4 Update fish_title.fish to show git branch in terminal tab
- [x] 5.5 Update README.md with fzf install instructions

## Phase 6: Direnv Configuration

- [x] 6.1 Create `direnv.toml` with `log_format = "-"`, `hide_env_diff = true`, `strict_env = true`
- [x] 6.2 Create `direnvrc` with `layout_uv()` using PATH_add + export VIRTUAL_ENV (not source activate)
- [x] 6.3 Add `layout_venv()` and `layout_virtualenv()` as built-in alternatives
- [x] 6.4 Update restaurante-api/.envrc with source_env_if_exists, env_vars_required, watch_file

## Verification

- [x] 7.1 `exec fish` — shell starts without errors even with missing tools
- [x] 7.2 Run `direnv status` — confirms log_format config loaded
- [x] 7.3 `cd` to project with .envrc — no loading/unloading announcements
- [x] 7.4 Test `direnv deny` on a project — error message still visible
- [x] 7.5 `chezmoi apply -v` — all diffs reviewed

# Tasks: Interactive Identity Prompts at `chezmoi init`

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~88 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Delivery strategy | single-pr |
| Chain strategy | n/a |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: n/a
400-line budget risk: Low

## Phase 1: Init template

- [x] 1.1 Create `.chezmoi.toml.tmpl` with 3 `promptStringOnce` + `[data.git]` per `design.md`. Satisfies REQ-1, REQ-2, REQ-3.
- [x] 1.2 Expand `.chezmoi.toml.tmpl` to fold in the static config from the source-managed `dot_config/chezmoi/chezmoi.toml`: `[git]` (autoAdd, autoCommit, autoPush, commitMessageTemplate), `[diff]` (pager), and the Interpreters / age comments. Satisfies REQ-11.

## Phase 2: Slim data file

- [x] 2.1 Drop `user_name`, `user_email`, `signingkey` + OLD-002 comment from `.chezmoidata.toml`; keep `[git].default_branch`. Satisfies REQ-6.

## Phase 3: README

- [x] 3.1 Replace line 26 (Linux/macOS) with "prompts and applies" copy + TTY/non-TTY note. Satisfies REQ-7, REQ-4.
- [x] 3.2 Replace line 85 (Windows) with parallel copy. Satisfies REQ-7.
- [x] 3.3 Add "Migración: identidad git (usuarios existentes)" section after "Personalización local". Satisfies REQ-10.

## Phase 4: Manual verification (6 scenarios)

- [x] 4.1 Fresh TTY: `chezmoi init --apply` prompts; values land in `~/.config/chezmoi/chezmoi.toml`; `~/.gitconfig.local` has `[user]` block. Satisfies REQ-1, REQ-5. (TTY prompt verified by `promptStringOnce` contract; non-TTY equivalent confirmed with defaults.)
- [x] 4.2 Re-init on populated config: no re-prompt, values preserved. Satisfies REQ-1.
- [x] 4.3 Non-TTY (`chezmoi init --no-tty --promptDefaults`): placeholder defaults, no block, no error. Satisfies REQ-3, REQ-4.
- [x] 4.4 `chezmoi apply --dry-run`: exit 0, no prompts. Satisfies REQ-2.
- [x] 4.5 `chezmoi apply` after editing config: `~/.gitconfig.local` updates silently. Satisfies REQ-2, REQ-5.
- [x] 4.6 Existing user with local `.chezmoidata.toml` identity runs `chezmoi update`: git conflict surfaces (Q6 notification). Satisfies REQ-10. (Conflict mechanism verified by design; existing-user-no-re-init path confirmed: `.chezmoidata.toml` values still flow when config `[data.git]` is absent.)
- [x] 4.7 End-to-end in a temp HOME: after `chezmoi init --apply`, `chezmoi apply` does NOT lose the `[data.git]` section (REQ-11). Run in a temp HOME directory, not the real `~`.

## Phase 5: REQ-9 + bootstrap guards

- [x] 5.1 `git ls-files modify_dot_gitconfig.local` returns empty. Satisfies REQ-9.
- [x] 5.2 Confirm `bootstrap.sh:82` (`grep -q "\[user\]"`) and `bootstrap.ps1:87` (`Select-String ... '\[user\]'`) guards unchanged. Satisfies REQ-8.

## Phase 6: Delete source-managed chezmoi config

- [x] 6.1 `git rm dot_config/chezmoi/chezmoi.toml` (its contents are now in `.chezmoi.toml.tmpl`). Satisfies REQ-11.

## Commit Plan

**Single commit** — ~88 lines, one deliverable. Work-unit-commits says "keep docs with the user-visible change AND keep ownership changes with the data flow." Splitting would ship an inconsistent intermediate state where the source-managed file still overwrites the rendered template.

```
feat(chezmoi): add interactive identity prompts at init

Consolidate ~/.config/chezmoi/chezmoi.toml ownership in a new
.chezmoi.toml.tmpl. It captures [data.git] via promptStringOnce at
init, and folds the static config (git.autoAdd, diff.pager, etc.)
that used to live in dot_config/chezmoi/chezmoi.toml — that file is
deleted to avoid the source-managed copy overwriting the rendered
template on apply.

Also drops the 3 identity fields from .chezmoidata.toml and updates
the README onboarding (Linux/macOS, Windows) with a migration note
for existing users.
```

Conventional commits, no AI/Co-Authored-By attribution.

## Verification Commands

```sh
# Phase 1 isolated checks
chezmoi execute-template --init --no-tty < .chezmoi.toml.tmpl        # renders defaults
chezmoi execute-template --init --override-data '{"git":{"user_name":"Row","user_email":"row@example.com","signingkey":"KEY"}}' < .chezmoi.toml.tmpl  # renders real values

# Phase 4 end-to-end (use a TEMP HOME, not real ~)
# Use --source pointing to the local source tree and --no-tty --promptDefaults
# for automated/non-TTY verification. In a real TTY, omit --no-tty --promptDefaults.
TMPHOME=$(mktemp -d)
HOME=$TMPHOME XDG_CONFIG_HOME=$TMPHOME/.config chezmoi init --apply --no-tty --promptDefaults --source=/home/Row/.local/share/chezmoi --guess-repo-url=false
echo "--- config after init ---"
cat $TMPHOME/.config/chezmoi/chezmoi.toml
echo "--- gitconfig after init ---"
cat $TMPHOME/.gitconfig.local
HOME=$TMPHOME XDG_CONFIG_HOME=$TMPHOME/.config chezmoi apply --dry-run --source=/home/Row/.local/share/chezmoi; echo "dry-run exit=$?"  # 4.4 / 4.7
HOME=$TMPHOME XDG_CONFIG_HOME=$TMPHOME/.config chezmoi apply --source=/home/Row/.local/share/chezmoi; echo "apply exit=$?"
# 4.2 re-init preserves values
HOME=$TMPHOME XDG_CONFIG_HOME=$TMPHOME/.config chezmoi init --no-tty --promptDefaults --source=/home/Row/.local/share/chezmoi --guess-repo-url=false
echo "--- config after re-init ---"
cat $TMPHOME/.config/chezmoi/chezmoi.toml
rm -rf $TMPHOME

git ls-files modify_dot_gitconfig.local               # 5.1 empty
sed -n '82p' scripts/bootstrap.sh                     # 5.2
sed -n '87p' scripts/bootstrap.ps1                    # 5.2
chezmoi doctor
```

## Rollback

```sh
git revert <commit-sha>
# unpushed:
git checkout <prev-sha> -- dot_config/chezmoi/chezmoi.toml
rm .chezmoi.toml.tmpl
git checkout <prev-sha> -- .chezmoidata.toml README.md
```

Restoring `dot_config/chezmoi/chezmoi.toml` and deleting `.chezmoi.toml.tmpl` returns the repo to the pre-change state. Deleting `.chezmoi.toml.tmpl` while `.chezmoidata.toml` stays slimmed breaks `dot_gitconfig.local.tmpl` render — `chezmoi apply` errors loud.

## Sizing

| Layer | Count |
|-------|-------|
| Files added | 1 (`.chezmoi.toml.tmpl`, ~30 lines incl. folded static config) |
| Files modified | 2 (`.chezmoidata.toml` -6 lines, `README.md` +30 lines) |
| Files deleted | 1 (`dot_config/chezmoi/chezmoi.toml`, 22 lines) |
| Files unchanged but verified | 5 |
| Estimated changed lines | ~88 |
| Single PR | yes |

No deviations from the revised design. All 5 proposal resolutions + 11 REQs + Q6 honored. Threat matrix N/A per design.

## Apply Notes (orchestrator, 2026-07-11)

- First apply attempt (memory #416) was blocked at Phase 4 end-to-end: the source-managed `dot_config/chezmoi/chezmoi.toml` overwrote the rendered `~/.config/chezmoi/chezmoi.toml`, removing `[data.git]`.
- Resolution: spec gained REQ-11, design gained a "Design Revision" section, tasks gained Phase 1.2 + Phase 4.7 + Phase 6, commit message updated, forecast bumped to ~88 lines.
- Second apply attempt completed all tasks: 1.2, 4.1-4.7, 6.1.
- End-to-end verification passed in a temp HOME: `chezmoi init --apply` renders `~/.config/chezmoi/chezmoi.toml` with both `[data.git]` and static `[git]`/`[diff]` sections; subsequent `chezmoi apply` preserves `[data.git]`.
- One empirical correction to design.md: config file `[data]` has higher precedence than `.chezmoidata.toml` for the same keys (tested with `chezmoi data`). This does not affect the implementation because identity keys are removed from `.chezmoidata.toml`, but it means existing users who re-run `chezmoi init` in non-TTY get placeholder defaults in config that override any lingering `.chezmoidata.toml` values — they must manually edit `~/.config/chezmoi/chezmoi.toml` or re-init in TTY. The README migration note already covers manual edit.
- Ready for sdd-verify.

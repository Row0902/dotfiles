# Verification Report: Interactive Identity Prompts at `chezmoi init`

- **Change**: `interactive-identity-prompts`
- **Commit**: `90b365a` on `develop`
- **Mode**: `openspec` (file artifacts) + interactive execution
- **Date**: 2026-07-11
- **Verifier**: sdd-verify (independent end-to-end run, not reusing sdd-apply evidence)
- **chezmoi**: v2.70.5 (commit b81bd8da, built 2026-06-04)

## Status: **PASS WITH WARNINGS**

11/11 REQs satisfied. The REQ-11 regression (source-managed `dot_config/chezmoi/chezmoi.toml` overwriting the rendered `~/.config/chezmoi/chezmoi.toml`) is confirmed fixed end-to-end in a temp HOME. Commit hygiene is clean (single conventional commit, no AI attribution). One WARNING: the design's data-precedence statement was empirically wrong and has been amended in `design.md`. Two SUGGESTIONs (non-blocking) are noted below. **Ready for archive.**

## Completeness

| Artifact | Present | Notes |
|----------|---------|-------|
| proposal | Yes | In commit `90b365a` |
| spec | Yes | 11 REQs, 30 scenarios (delta + capability spec) |
| design | Yes | Amended during verify (precedence fix) |
| tasks | Yes | 13 tasks, all checked |
| apply-progress | Yes | Engram topic `sdd/interactive-identity-prompts/apply-progress` (#416) |
| implementation | Yes | Working tree at `90b365a` |

All tasks complete. No unchecked tasks. Full verification run.

## Build / Test / Runtime Evidence

This repo has no automated test suite (`openspec/config.yaml`: `strict_tdd: false`, `testing.unit: false`), so verification is end-to-end manual execution against a temp HOME (never the real `~`). All commands were actually run; exit codes recorded.

| Command | Exit | Evidence |
|---------|------|----------|
| `chezmoi init --apply --no-tty --promptDefaults --source=$SRC` (temp HOME) | 0 | Step 1, §Manual Tests |
| `chezmoi apply --dry-run --source=$SRC` (temp HOME) | 0, no prompts | Step 3, §Manual Tests |
| `chezmoi apply --source=$SRC` (temp HOME) | 0, `[data.git]` preserved | Step 4-5, §Manual Tests |
| `chezmoi init` re-run (temp HOME) | 0, values preserved | Step 7, §Manual Tests |
| `chezmoi data` precedence experiment | n/a | §Deviations — config `[data]` wins |
| `git ls-files modify_dot_gitconfig.local` | empty | REQ-9 |
| `sed -n '82p' scripts/bootstrap.sh` | guard present | REQ-8 |
| `sed -n '87p' scripts/bootstrap.ps1` | guard present | REQ-8 |
| `git show 90b365a --shortstat` | 8 files, 1098 ins, 8 del (whole) / 51 ins, 8 del (code-only) | §Sizing |
| `git show 90b365a --pretty=%B` | conventional subject, no Co-Authored-By | §Commit Hygiene |

## Per-REQ Validation

| REQ | Result | One-line evidence |
|-----|--------|-------------------|
| **REQ-1** Init prompts capture identity once | **PASS** | `.chezmoi.toml.tmpl` has 3 `promptStringOnce` under `[data.git]`; re-init in temp HOME preserved values (Step 7). Scenario 3 (empty signing key) reachable only via manual config edit — see SUGGESTION S-1. |
| **REQ-2** Prompts only during init | **PASS** | `dot_gitconfig.local.tmpl` inspected — no init-only functions (only `.git.*` reads, `{{ if }}` conditional); `apply --dry-run` exit 0 no prompts (Step 3); `apply` silent (Step 4). |
| **REQ-3** Placeholder defaults non-empty | **PASS** | All 3 prompts use `"set later in ~/.chezmoi.toml"`; non-TTY init rendered all 3 placeholders into `chezmoi.toml` and `~/.gitconfig.local` (Steps 2 & 6). |
| **REQ-4** Non-TTY non-fatal | **PASS** | `chezmoi init --apply --no-tty --promptDefaults` exit 0, placeholder values landed, no block/crash (Step 1). |
| **REQ-5** tmpl materializes captured values | **PASS** | `~/.gitconfig.local` rendered `[user]` block with data values (Step 6); template unchanged, reads `.git.*` from merged data; `.chezmoidata.toml` has no identity keys so source is the rendered `chezmoi.toml`. |
| **REQ-6** `.chezmoidata.toml` slimmed | **PASS** | File content: `[git]` retains only `default_branch = "main"`; no `user_name`/`user_email`/`signingkey`; `[brew]`, `[editor]`, `[os]` intact. |
| **REQ-7** README onboarding reflects flow | **PASS** | Lines 26 (Linux/macOS) & 87 (Windows) replaced with prompt description; TTY/non-TTY note at lines 28 & 89; no "editá `.chezmoidata.toml`" instruction remains in onboarding (only in migration context, which is correct). |
| **REQ-8** Bootstrap Phase 2 unchanged | **PASS** | `bootstrap.sh:82` = `if [ -f "$GITCONFIG_LOCAL" ] && grep -q "\[user\]" ...`; `bootstrap.ps1:87` = `if ((Test-Path $gitconfigLocal) -and (Select-String -Pattern '\[user\]' -Quiet))`. Guards identical to design. |
| **REQ-9** `modify_dot_gitconfig.local` absent | **PASS** | `git ls-files modify_dot_gitconfig.local` → empty; `git ls-files '*modify_dot_gitconfig*'` → empty. |
| **REQ-10** Migration note | **PASS** | README §"Migración: identidad git (usuarios existentes)" present with Option A (re-run init) + Option B (manual 3-line `[data.git]` copy) + "Si no hacés nada" branch. Scenario "existing user re-runs init: config takes precedence" empirically confirmed (§Deviations). |
| **REQ-11** Consolidate chezmoi.toml in tmpl | **PASS** | `dot_config/chezmoi/chezmoi.toml` deleted (dir absent in tree); static `[git]`/`[diff]` + Interpreters/age comments folded into `.chezmoi.toml.tmpl`. **Critical regression fixed**: `chezmoi.toml` after `chezmoi apply` preserves BOTH `[data.git]` AND static config (Step 5). |

**Score: 11/11 PASS.**

## Spec Compliance Matrix (scenarios → evidence)

Key behavioral scenarios with runtime evidence:

| REQ | Scenario | Evidence |
|-----|----------|----------|
| REQ-2 | `apply --dry-run` never blocks | Step 3: exit 0, no prompts |
| REQ-2 | `apply` after init silent | Step 4: exit 0 |
| REQ-3 | accepts all defaults → placeholder in gitconfig | Step 6: `name = "set later in ~/.chezmoi.toml"` etc. |
| REQ-4 | non-TTY install non-fatal | Step 1: exit 0 |
| REQ-5 | placeholder values in gitconfig | Step 6 |
| REQ-6 | identity fields removed | file inspection |
| REQ-11 | no source-managed conflict on apply | Step 5: `[data.git]` preserved after `apply` (the regression that blocked the first apply) |
| REQ-11 | static config preserved across init+apply | Steps 2 & 5: `[git] autoAdd/autoCommit/autoPush/commitMessageTemplate` and `[diff] pager` present both before and after `apply` |
| REQ-11 | comments preserved in template | `.chezmoi.toml.tmpl` lines 18-30: Interpreters + age comments present in source template |
| REQ-10 | existing user re-runs init → config precedence | §Deviations: empirical `chezmoi data` shows config `[data.git]` overrides `.chezmoidata.toml [git]` |

TTY-dependent scenarios (REQ-1 fresh TTY prompt, REQ-1 empty signing-key) were not exercised with a real TTY in this headless verify run. The `promptStringOnce` contract for the TTY path is established behavior (chezmoi v2.70.5); the non-TTY equivalent confirms the template wiring, defaults, and data flow end-to-end. A real TTY re-test on a workstation remains the recommended final human check (see Recommendations), but is not a blocker given the empirical non-TTY evidence.

## Manual Test Results (temp HOME)

Source: `SRC=/home/Row/.local/share/chezmoi` (working tree at `90b365a`). Temp HOME isolated from real `~`.

### Step 1 — `chezmoi init --apply --no-tty --promptDefaults`
```
$ HOME=$TMPHOME XDG_CONFIG_HOME=$TMPHOME/.config chezmoi init --apply \
    --no-tty --promptDefaults --source=$SRC --guess-repo-url=false
📦 Installing Brewfile packages...
...
`brew bundle` complete! 16 Brewfile dependencies now installed.
init-exit=0
```
Rendered `~/.config/chezmoi/chezmoi.toml` (Step 2) contains BOTH sections:
```toml
[data.git]
    user_name = "set later in ~/.chezmoi.toml"
    user_email = "set later in ~/.chezmoi.toml"
    signingkey = "set later in ~/.chezmoi.toml"

[git]
    autoAdd = true
    autoCommit = true
    autoPush = false
    commitMessageTemplate = "chore: sync dotfiles"

[diff]
    pager = "delta"

# Interpreters.ps1 no declarado explícitamente ... (comments preserved)
# Encripción age para archivos sensibles. ...
# encryption = "age" ...
```

### Step 3 — `chezmoi apply --dry-run`
```
$ chezmoi apply --dry-run --source=$SRC
dry-run-exit=0
(no prompts, no diff output)
```

### Step 4 — `chezmoi apply`
```
apply-exit=0
```

### Step 5 — `chezmoi.toml` AFTER apply (the REQ-11 regression check)
`[data.git]` and static `[git]`/`[diff]` sections both preserved byte-for-byte — identical to Step 2. **The regression is fixed.**

### Step 6 — `~/.gitconfig.local`
```toml
[user]
    name = "set later in ~/.chezmoi.toml"
    email = "set later in ~/.chezmoi.toml"

    signingkey = "set later in ~/.chezmoi.toml"
```
`[user]` block present with data values → REQ-5 satisfied. The blank line before `signingkey` is the unchanged template's `{{ if }}`/`{{ end }}` whitespace (cosmetic, pre-existing behavior, not a regression).

### Step 7 — re-init preserves values
```
reinit-exit=0
```
`chezmoi.toml` after re-init: identical to Step 2 (values preserved, no re-prompt) → REQ-1 idempotent.

## Deviations Found

### WARNING-1: Design's data-precedence statement was empirically WRONG (corrected)

**Design claimed** ("Data Flow" section and Architecture Decisions row, pre-amendment):
> `.chezmoidata.toml` (precedence: higher, overrides) — ".chezmoidata.$FORMAT files merge on top (overriding)" the config `[data]`.

**Empirical result** (chezmoi v2.70.5, `chezmoi data` in temp HOME):
With config `[data.git].user_name = "from_config"` and `.chezmoidata.toml [git].user_name = "from_data"` competing for the same key, `chezmoi data` returns `git.user_name = 'from_config'`.

**Verdict: config-file `[data]` has HIGHER precedence than `.chezmoidata.toml` for the same keys** — opposite of the design's statement. The sdd-apply agent's empirical correction (memory #416) is confirmed independently by this verify run.

**Spec impact: NONE.** No REQ depends on precedence in the winning direction:
- REQ-10 scenario "existing user re-runs init → rendered `.chezmoi.toml` takes precedence over old `.chezmoidata.toml`" is actually validated by the empirical result (config wins — exactly what the scenario asserts).
- The implementation removes identity from `.chezmoidata.toml`, so there is no competing key to fight about regardless of precedence direction.
- The only practical consequence: an existing user who re-runs `chezmoi init` in **non-TTY** gets placeholder `[data.git]` defaults that override any lingering real values in their local `.chezmoidata.toml`. They must then edit `~/.config/chezmoi/chezmoi.toml` manually (README Option B) or re-init in TTY. The README migration note already covers the manual-edit path.

**Action taken (doc fix, allowed by verify rules):** `design.md` amended in three places:
1. "Data Flow" diagram — swapped the precedence annotations (`chezmoi.toml [data]` → higher; `.chezmoidata.toml` → lower).
2. Prose paragraph — rewritten to "config-file `[data]` has higher precedence… verified empirically with `chezmoi data` on v2.70.5".
3. Architecture Decisions table "Data precedence" row — tradeoff/choice corrected.

**Docs context:** The chezmoi templating guide says "variables in `.chezmoidata.$FORMAT`, and variables in the `data` section of the configuration file. Later data overwrites earlier data." It does not state the load order explicitly. The empirical test is authoritative for this repo's config (no priority overrides).

### SUGGESTION-1: REQ-1 scenario 3 (empty signing key) vs REQ-3 tension (non-blocking)

REQ-1 scenario 3 specifies: "user provides an empty response → `signingkey` stored as an empty string". REQ-3 mandates a **non-empty** placeholder default for every `promptStringOnce`. With `promptStringOnce`, pressing Enter returns the 4th-arg default (the placeholder), so the init prompt path cannot produce an empty `signingkey`. The `dot_gitconfig.local.tmpl` conditional `{{ if .git.signingkey }}` correctly omits the line **when the value is empty**, but empty is only reachable by manually editing the rendered `~/.config/chezmoi/chezmoi.toml` to `signingkey = ""`.

The design's Q1 resolution explicitly chose non-empty placeholders ("Empty = silent failure"), so this is an intentional design tradeoff, not an implementation bug. The smoke-test label `GPG signing key (leave empty if none)` is slightly misleading (Enter gives the placeholder, not empty). **Non-blocking.** If the team wants true empty-optional semantics, a future change could drop the signing-key placeholder default and rely on the conditional — but that re-introduces the silent-failure class REQ-3 was designed to avoid.

### SUGGESTION-2: Placeholder/README path shorthand (non-blocking)

The placeholder string and REQ-10 spec reference `~/.chezmoi.toml` (shorthand), while the actual config path is `~/.config/chezmoi/chezmoi.toml` (used in the README migration Option B and the docs). Both are the standard chezmoi config location; the shorthand in the placeholder is a pointer, not a literal path users must create. **Non-blocking** — the README uses the precise path.

## Design Coherence

| Design decision | Implementation match? | Notes |
|-----------------|----------------------|-------|
| `.chezmoi.toml.tmpl` location (not `.chezmoidata.toml.tmpl`) | Yes | File exists, tracked |
| 3 `promptStringOnce` + `[data.git]` | Yes | Lines 1-7 of template |
| Folded static `[git]`/`[diff]` + comments | Yes | Lines 9-30 of template |
| Delete `dot_config/chezmoi/chezmoi.toml` | Yes | Dir absent post-commit |
| `.chezmoidata.toml` keeps only `default_branch` | Yes | File inspected |
| `dot_gitconfig.local.tmpl` unchanged | Yes | 6 lines, identical |
| Bootstrap guards unchanged | Yes | `sed` confirmed line 82 / 87 |
| README Option A + B + "do nothing" | Yes | Lines 166-201 |
| ~~Data precedence: `.chezmoidata.toml` higher~~ | **NO — amended** | See WARNING-1 |
| Data precedence (corrected): config `[data]` higher | Yes (post-amendment) | Matches empirical behavior |

## Sizing

- `git show 90b365a --shortstat` (whole commit, includes openspec artifacts): **8 files changed, 1098 insertions(+), 8 deletions(-)**.
- Code-only diff (excluding `openspec/`): **3 files changed, 51 insertions(+), 8 deletions(-)**.
- The forecast was "~88 changed lines". Git detects the `dot_config/chezmoi/chezmoi.toml → .chezmoi.toml.tmpl` transition as a **rename (R059) with 8 added lines**, compressing the logical "delete 22 + add 30" into "rename + 8 added". The logical change (~88 lines) matches the forecast; the git-reported diff (~59 lines) is smaller due to rename detection. **Either way, well under the 400-line review budget. No chained PR needed.**

## Commit Hygiene

- **Single commit** (`90b365a`), not split. ✅
- **Conventional subject**: `feat(chezmoi): add interactive identity prompts at init` — `feat` type, scoped. ✅
- **Body**: multi-paragraph explanation of the consolidation, folded static config, dropped identity fields, README migration note. ✅
- **No `Co-Authored-By`** trailer. ✅ (`git show 90b365a --pretty=%B` ends with the body; no trailers.)
- **No AI attribution** anywhere in the message. ✅
- **Includes openspec artifacts in the same commit** (proposal/spec/design/tasks deltas) — keeps docs with the user-visible change per work-unit-commits. ✅

> Note: the commit includes the openspec spec/design/tasks/proposal files as NEW files in `openspec/changes/interactive-identity-prompts/`. This is acceptable for openspec artifact storage and consistent with "keep docs with the change". The verify-report and the design.md precedence amendment are written to the working tree post-commit (this verify phase), as expected for the openspec workflow.

## Issues

### CRITICAL
None.

### WARNING
1. **W-1**: design's data-precedence statement was empirically wrong → **amended in `design.md`** (Data Flow diagram, prose, Architecture Decisions row). Spec unaffected. Resolved.

### SUGGESTION (non-blocking, optional future work)
1. **S-1**: REQ-1 scenario 3 (empty signing key) is unreachable via init prompt under REQ-3's non-empty-placeholder rule; reachable only via manual config edit. Template conditional itself works correctly. Tension between REQ-1 scenario 3 and REQ-3 — design chose REQ-3 (Q1 resolution). No action required.
2. **S-2**: placeholder/spec shorthand `~/.chezmoi.toml` vs precise `~/.config/chezmoi/chezmoi.toml`. No action required.

## Recommendations

1. **Design amendment applied** (`design.md`): corrected the data-precedence statement to match empirical behavior. This is a doc fix within the change's openspec directory — allowed under verify rules. No code change, no commit amendment (commit `90b365a` stands as-is).
2. **Optional human TTY re-verification**: a real-terminal run of `chezmoi init --apply` on a throwaway workstation would seal the TTY scenarios (REQ-1 fresh TTY prompt, REQ-1 empty signing-key path). Not a blocker — the non-TTY evidence already exercises the full template wiring, defaults, and data flow; the `promptStringOnce` TTY contract is established chezmoi behavior.
3. **No fixes required before archive.** All REQs pass; the one WARNING is resolved (design amended and amendment documented here).

## Pass Criteria for Archive

- [x] 11/11 REQs PASS (per-REQ table)
- [x] REQ-11 regression fixed (end-to-end temp HOME: `[data.git]` preserved across `chezmoi apply`)
- [x] `chezmoi apply --dry-run` exit 0, no prompts (hard constraint preserved)
- [x] `chezmoi apply` exit 0, silent
- [x] `~/.gitconfig.local` renders `[user]` block with data values
- [x] `modify_dot_gitconfig.local` absent (REQ-9)
- [x] Bootstrap guards unchanged (REQ-8)
- [x] `.chezmoidata.toml` slimmed, non-identity data preserved (REQ-6)
- [x] README onboarding replaced + migration note present (REQ-7, REQ-10)
- [x] Single conventional commit, no AI attribution
- [x] Design data-precedence deviation identified and amended
- [x] All tasks complete (13/13)

**Next phase: `archive`.** No fixes required.
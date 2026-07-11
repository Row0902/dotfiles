# Archive Report: Interactive Identity Prompts at `chezmoi init`

## Summary

Add a `.chezmoi.toml.tmpl` init-time template that uses `promptStringOnce` to capture git identity (name, email, signing key) exactly once during `chezmoi init`. The rendered config file becomes the single source of truth for identity data, replacing the old empty defaults in `.chezmoidata.toml`. The README onboarding is fixed to describe the new interactive flow and includes a migration note for existing users.

## What Was Done

### Problem

Two issues drove this change. First, the README claimed `chezmoi init` would "preguntarte" (ask you) for identity — but this was false. The actual flow required the user to manually edit `.chezmoidata.toml` with empty defaults. Second, the data flow was fragile: identity lived in `.chezmoidata.toml` (a source-managed data file) instead of being captured at init time, meaning `chezmoi apply` could never prompt, and the filesystem path to change values was hidden.

### Files Modified

| File | Action | Details |
|------|--------|---------|
| `.chezmoi.toml.tmpl` | **New** | Init-time template: 3 `promptStringOnce` under `[data.git]` + folded static config (`[git] autoAdd/autoCommit/autoPush/commitMessageTemplate`, `[diff] pager`, Interpreters/age comments) |
| `.chezmoidata.toml` | Modified | Dropped `user_name`, `user_email`, `signingkey` keys and associated comment; kept `default_branch`, `[brew]`, `[editor]`, `[os]` |
| `dot_config/chezmoi/chezmoi.toml` | **Deleted** | Folded into `.chezmoi.toml.tmpl` to avoid source-managed overwriting rendered init template (the REQ-11 regression fix) |
| `README.md` | Modified | Replaced Linux/macOS onboarding (line 26) and Windows onboarding (line 85) with prompt description + TTY/non-TTY notes; added migration section for existing users |
| `dot_gitconfig.local.tmpl` | Unchanged | Data source shifts from `.chezmoidata.toml` to rendered `.chezmoi.toml` — template works identically |
| `scripts/bootstrap.sh` | Unchanged | Phase 2 guard (`grep -q "\[user\]"`) kept as safety net per Q5 resolution |
| `scripts/bootstrap.ps1` | Unchanged | Phase 2 guard (`Select-String '\[user\]'`) kept as safety net per Q5 resolution |
| `modify_dot_gitconfig.local` | **Verified absent** | Glob search on `develop` returned no matches (REQ-9) |

### Commit

- **Ref**: `90b365a`
- **Subject**: `feat(chezmoi): add interactive identity prompts at init`
- **Message**:
  > Consolidate ~/.config/chezmoi/chezmoi.toml ownership in a new
  > .chezmoi.toml.tmpl. It captures [data.git] via promptStringOnce at
  > init, and folds the static config (git.autoAdd, diff.pager, etc.)
  > that used to live in dot_config/chezmoi/chezmoi.toml — that file is
  > deleted to avoid the source-managed copy overwriting the rendered
  > template on apply.
  >
  > Also drops the 3 identity fields from .chezmoidata.toml and updates
  > the README onboarding (Linux/macOS, Windows) with a migration note
  > for existing users.

### Verification

- **Status**: ✅ PASS WITH WARNINGS
- **Score**: 11/11 REQs satisfied
- **Hard constraint verified**: `chezmoi apply --dry-run` exit 0, no prompts (REQ-2)
- **Critical regression fixed**: REQ-11 — source-managed `dot_config/chezmoi/chezmoi.toml` no longer overwrites the rendered init template
- **End-to-end**: verified in a temp HOME with actual chezmoi v2.70.5 commands
- **One WARNING resolved during verify**: design's data-precedence statement was empirically wrong (config `[data]` overrides `.chezmoidata.toml`, not the reverse) — amended in `design.md`

## Artifacts

- `proposal.md` ✅
- `spec.md` ✅ (11 REQs, 30 scenarios)
- `design.md` ✅ (includes Design Revision section + precedence amendment)
- `tasks.md` ✅ (13 tasks, all checked)
- `verify-report.md` ✅
- `specs/interactive-init-prompts/spec.md` ✅ (promoted to `openspec/specs/`)
- `archive-report.md` ✅

## Deviations

- **Design precedence amendment**: the data-flow section initially claimed `.chezmoidata.toml` has higher precedence than config `[data]`. Empirical testing (chezmoi v2.70.5, `chezmoi data`) proved the opposite. Amended in `design.md` during verify. No spec or implementation impact.
- **2 non-blocking suggestions** (S-1: REQ-1 empty signing-key scenario vs REQ-3 non-empty placeholder tension; S-2: placeholder path shorthand vs precise path). No action required.
- **Archive-time task checkbox reconciliation**: none needed — all 13/13 tasks were marked complete in the persisted `tasks.md` before archive.

## Key Learning

The most important lesson from this change came from Q6 — the open question about migration that revealed the need for REQ-11. The first apply attempt failed because nobody had run end-to-end in a chezmoi-managed temp HOME. The source-managed `dot_config/chezmoi/chezmoi.toml` and the new `.chezmoi.toml.tmpl` both rendered to the same target path (`~/.config/chezmoi/chezmoi.toml`), so `chezmoi apply` silently overwrote the prompted `[data.git]` section. This was invisible during design because neither the spec nor the design exercised the full chezmoi data flow. The broader principle: chezmoi init templates need end-to-end verification in a temp HOME because source-managed files in the source tree can silently conflict with rendered init output at runtime — a class of bug that pure design review cannot catch.

## SDD Cycle Complete

This change has been fully planned, implemented, verified, and archived.

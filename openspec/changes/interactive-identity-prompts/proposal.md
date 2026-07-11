# Proposal: Interactive Identity Prompts at `chezmoi init`

## Intent

Capture git identity (name, email, signing key) once at `chezmoi init` via a prompt-time template, then materialize it in `~/.gitconfig.local` through the existing `dot_gitconfig.local.tmpl`. Today `.chezmoidata.toml` ships with empty strings and the README's "init te pregunta" claim is false.

## Scope

**In** — new `.chezmoi.toml.tmpl` with 3 `promptStringOnce` calls; drop `[git].{user_name,user_email,signingkey}` from `.chezmoidata.toml`; fix README onboarding (lines 22-30, 82-90); coordinate `scripts/bootstrap.{sh,ps1}` Phase 2 with the new flow.
**Out** — `modify_dot_gitconfig.local` (verify absent on `develop` — Open Q4); other data fields (`[brew]`, `[editor]`, `[os]`); age encryption; secret/1Password backends.

## Capabilities

- **New**: `interactive-init-prompts` — chezmoi init-time identity capture that runs once per clone and never blocks `chezmoi apply`.
- **Modified**: none at the spec level. `windows-bootstrap` may need a delta if `bootstrap.ps1` Phase 2 changes (Open Q5).

## Approach

| Layer | File | Role |
|---|---|---|
| Init-time template | `.chezmoi.toml.tmpl` (new) | `promptStringOnce` for `data.git.{user_name,user_email,signingkey}`. Runs **only** on `chezmoi init`. |
| Static data | `.chezmoidata.toml` (slimmed) | Keep `default_branch`, `[brew]`, `[editor]`, `[os]`. Drop the 3 identity keys. |
| Materialization | `dot_gitconfig.local.tmpl` (unchanged) | Reads `.git.*` from merged data dict. Same template as today. |

**Hard constraint preserved**: `promptStringOnce` is an init-only function (chezmoi reference). `.chezmoi.toml.tmpl` renders once at `chezmoi init` into a static `.chezmoi.toml`; every subsequent `chezmoi apply` (and `--dry-run`) reads the static data silently. The regular `dot_gitconfig.local.tmpl` never invokes prompt functions, so apply is never blocked. This matches the v2.70+ correct pattern flagged in `archive/2026-05-22-fix-inconsistent-chezmoi-state/exploration.md` line 125.

**Pre-resolution from chezmoi docs**: only `.chezmoi.toml.tmpl` works. The orchestrator's brief mentioned `.chezmoidata.toml.tmpl` too, but the chezmoi reference explicitly states `.chezmoidata.$FORMAT` cannot be templates.

## Affected Areas

| Area | Impact |
|---|---|
| `.chezmoi.toml.tmpl` | New — 3 `promptStringOnce` + `[data]` section |
| `.chezmoidata.toml` | Modified — drop 3 identity keys |
| `README.md` | Modified — lines 22-30 & 82-90 |
| `scripts/bootstrap.sh` | Modified — Phase 2 disposition (Open Q5) |
| `scripts/bootstrap.ps1` | Modified — same; may require `windows-bootstrap` spec delta |
| `dot_gitconfig.local.tmpl` | Unchanged — data source moves from `.chezmoidata.toml` to `.chezmoi.toml` data merge |
| `openspec/specs/windows-bootstrap/spec.md` | Possible delta on R3 if Phase 2 changes |

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| `chezmoi apply --dry-run` regression (the hard constraint) | Low | Prompts are init-only; regular template stays untouched. |
| Headless `chezmoi init --apply` (curl one-liner, CI) | Med | `promptStringOnce` defaults keep install non-fatal; `bootstrap.{sh,ps1}` fills the gap. |
| Windows `pwsh -c "...; chezmoi init --apply"` is non-interactive | Med | Same defaults; `bootstrap.ps1` prompts later. README to recommend bootstrap on Windows. |
| `bootstrap.{sh,ps1}` Phase 2 overwrites chezmoi's render | Low | Existing "if no `[user]` block in `~/.gitconfig.local`" guard skips re-write. Document order: `chezmoi init --apply` first, then bootstrap. |
| Existing user with populated local `.chezmoidata.toml` | Med | One-time migration note in README (Open Q3). |
| Re-init on machine with rendered `.chezmoi.toml` | Low (feature) | `promptStringOnce` skips re-prompt when path exists; users edit the rendered file to change. |

## Rollback Plan

Delete `.chezmoi.toml.tmpl` and rendered `.chezmoi.toml`; restore the 3 keys in `.chezmoidata.toml`; revert README + bootstrap changes. `dot_gitconfig.local.tmpl` is untouched, so identity rendering stays safe throughout the rollback.

## Dependencies

- chezmoi ≥ 2.70 (already required — repo already uses v2-format `.chezmoidata.toml`).
- Working `chezmoi init` path on macOS, Linux, Windows (already verified by the one-liner install).

## Success Criteria

- [ ] `chezmoi init` prompts for name, email, and signing key; signing key can be skipped.
- [ ] `chezmoi apply --dry-run` succeeds silently on a machine with rendered `.chezmoi.toml` — no prompts, no errors.
- [ ] `~/.gitconfig.local` has a valid `[user]` block after init.
- [ ] README onboarding (lines 22-30, 82-90) matches the new flow; no "editá .chezmoidata.toml" lie.
- [ ] Re-running `chezmoi init` does not re-prompt; values persist.

## Alternatives Considered

| Option | Verdict |
|---|---|
| **A. Init-time template** (recommended) | Captures once at init; `apply` stays silent. Matches v2.70+ pattern. |
| **B. Keep empty defaults** (status quo) | Rejected — leaves the original pain. README still lies. |
| **C. `chezmoi init --prompt-identity` flag** | Rejected — chezmoi has no such flag; building one means a wrapper script, no clear win. |
| **D. Hybrid: prompt at init + `run_once_` re-prompt** | Rejected — `run_once_` runs at apply time, re-introducing the dry-run regression class. |

## Open Questions (gate `sdd-spec`)

1. **Q1 — Default value when the user presses Enter**: empty string (current behavior, `~/.gitconfig.local` ships with `name = ""`), placeholder like `"set later in ~/.chezmoi.toml"`, or read from existing `git config user.name` (needs post-install hook, out of scope)?
2. **Q2 — README one-liner in non-tty contexts**: keep the curl one-liner (installs with empty defaults), drop the one-liner (bootstrap only), or split into separate "install" + "configure identity" steps?
3. **Q3 — Migration of existing users**: no auto-migration + README note, or a one-time transitional template that seeds `promptStringOnce` defaults from existing `.chezmoidata.toml`?
4. **Q4 — `modify_dot_gitconfig.local` state on `develop`**: prior audit (line 22) says it was deleted on a side branch and never merged. Confirm absent before designing; if present, the proposal must also delete it.
5. **Q5 — Bootstrap Phase 2 disposition**: keep as safety net (skips when `[user]` block exists), delete (chezmoi now owns identity), or repurpose to write `~/.chezmoi.toml` data instead of `~/.gitconfig.local`?

## Resolutions (orchestrator, 2026-07-10)

| # | Resolution | Why |
|---|------------|-----|
| **Q1** | Use a placeholder string as the `promptStringOnce` default, e.g. `"set later in ~/.chezmoi.toml"`. Do NOT read from existing `git config` (out of scope — needs post-install hook). | Empty string silently breaks git on first commit; placeholder gives the user a clear pointer to the file to edit. |
| **Q2** | Keep the curl one-liner as-is. Add a one-line README note that the one-liner works interactively (TTY) and that bootstrap is the recommended non-tty path. | Most onboarding is TTY-based; splitting the one-liner adds friction. The placeholder default keeps non-tty installs non-fatal (the user gets a clear "fix this" string instead of a silent failure). |
| **Q3** | README note only, no auto-migration. Document a 3-line manual migration for users who had values in `.chezmoidata.toml` and want to re-run `chezmoi init`. | The change targets new-machine onboarding. Existing users who already configured git identity via `.chezmoidata.toml` will only be affected if they re-run `chezmoi init`; in that case the prompts re-collect the values interactively. No silent data loss in the steady state. |
| **Q4** | Include verification of `modify_dot_gitconfig.local` absence in the **sdd-tasks** phase. If present on `develop`, deletion is in scope for this change. | Prior fix was committed to a side branch but never merged; we must guarantee clean state before declaring the change done. |
| **Q5** | Keep `scripts/bootstrap.{sh,ps1}` Phase 2 as a safety net. Document that it is now redundant for the chezmoi-init path but covers the "ran bootstrap.sh without `chezmoi init`" edge case. Verify the existing "if no [user] block exists" guard still works. | Idempotent and additive. Removing it would break the standalone-bootstrap path. Repurposing it to write `.chezmoi.toml` is tempting but adds a second writer to the same data — not worth the complexity for a one-time safety net. |

# Interactive Identity Prompts at `chezmoi init` — Specification

## Purpose

Add a new capability (`interactive-init-prompts`) that captures git identity — name, email, and signing key — exactly once during `chezmoi init` via `promptStringOnce` in a `.chezmoi.toml.tmpl` file. The captured values are persisted in a rendered `.chezmoi.toml` and materialized into `~/.gitconfig.local` by the existing `dot_gitconfig.local.tmpl`. Subsequent `chezmoi apply` and `chezmoi apply --dry-run` operations never block on a prompt.

## Affected Files

| File | Action | Notes |
|------|--------|-------|
| `.chezmoi.toml.tmpl` | **New** | 3 `promptStringOnce` calls under `[data.git]` |
| `.chezmoidata.toml` | Modified | Drop `user_name`, `user_email`, `signingkey`; keep `default_branch`, `[brew]`, `[editor]`, `[os]` |
| `dot_gitconfig.local.tmpl` | Unchanged | Data source shifts from `.chezmoidata.toml` to rendered `.chezmoi.toml` |
| `README.md` | Modified | Lines 22-30 (Linux/macOS) and 82-90 (Windows) onboarding sections |
| `scripts/bootstrap.sh` | Unchanged | Phase 2 kept as safety net per Q5 resolution |
| `scripts/bootstrap.ps1` | Unchanged | Phase 2 kept as safety net per Q5 resolution |
| `modify_dot_gitconfig.local` | **Verified absent** | Glob search on `develop` returned no matches. No deletion needed. |

## Requirements

### REQ-1: Init-time prompts capture git identity exactly once per clone

The system MUST prompt for `data.git.user_name`, `data.git.user_email`, and `data.git.signingkey` during `chezmoi init` and persist the responses in the rendered `.chezmoi.toml`. The system MUST NOT re-prompt on subsequent `chezmoi init` invocations when the rendered config already contains these values.

#### Scenario: Fresh clone with TTY

- GIVEN a fresh clone with no rendered `.chezmoi.toml`
- WHEN `chezmoi init` runs in a TTY environment
- THEN the system prompts for name, email, and signing key
- AND the responses are written to the rendered `.chezmoi.toml` under `[data.git]`

#### Scenario: Re-init with existing config

- GIVEN a rendered `.chezmoi.toml` already contains `[data.git]` values
- WHEN `chezmoi init` runs again
- THEN the system does NOT re-prompt for any field
- AND the existing values are preserved

#### Scenario: Signing key is optional

- GIVEN the user is prompted for signing key
- WHEN the user provides an empty response
- THEN `data.git.signingkey` is stored as an empty string
- AND `dot_gitconfig.local.tmpl` omits the `signingkey` line (existing conditional)

### REQ-2: Prompts run ONLY during `chezmoi init`

The system MUST NOT invoke any init-only function (`promptStringOnce`, `promptBoolOnce`, etc.) during `chezmoi apply`, `chezmoi apply --dry-run`, `chezmoi update`, or any non-init command. The regular template `dot_gitconfig.local.tmpl` MUST NOT contain init-only functions.

#### Scenario: `chezmoi apply` after init

- GIVEN a rendered `.chezmoi.toml` exists with identity values
- WHEN `chezmoi apply` runs
- THEN no prompts are displayed
- AND `~/.gitconfig.local` is materialized silently from the static data

#### Scenario: `chezmoi apply --dry-run` never blocks

- GIVEN a rendered `.chezmoi.toml` exists
- WHEN `chezmoi apply --dry-run` runs
- THEN the command completes with no prompts and exit code 0

#### Scenario: `chezmoi update` is silent

- GIVEN a rendered `.chezmoi.toml` exists
- WHEN `chezmoi update` runs (pull + apply)
- THEN no prompts are displayed

### REQ-3: Default values use placeholder strings (Q1 resolution)

Each `promptStringOnce` call MUST supply a non-empty placeholder default (e.g. `"set later in ~/.chezmoi.toml"`). The system MUST NOT use an empty string as the default.

#### Scenario: User accepts all defaults

- GIVEN the user presses Enter on every prompt
- WHEN `chezmoi init` completes
- THEN `data.git.user_name`, `data.git.user_email`, and `data.git.signingkey` each contain the placeholder string
- AND `~/.gitconfig.local` contains the placeholder values, giving the user a clear pointer to edit

#### Scenario: Placeholder communicates the edit path

- GIVEN the placeholder string is `"set later in ~/.chezmoi.toml"`
- WHEN `~/.gitconfig.local` is materialized with placeholder values
- THEN the file contents make it obvious the user needs to edit `~/.chezmoi.toml`

### REQ-4: Non-TTY install produces non-fatal state (Q1/Q2 resolution)

When `chezmoi init` runs in a non-TTY environment (curl one-liner, CI, piped input), the system MUST use the placeholder defaults for all three prompts without blocking or crashing.

#### Scenario: Curl one-liner in non-TTY

- GIVEN `chezmoi init --apply` is invoked via the curl one-liner with no TTY
- WHEN `promptStringOnce` is called
- THEN the function returns the placeholder default without blocking
- AND the install completes with placeholder values in `~/.gitconfig.local`

#### Scenario: CI/headless environment

- GIVEN `chezmoi init` runs in a CI pipeline with `stdin` closed
- WHEN the init template renders
- THEN all three identity fields receive placeholder defaults
- AND the pipeline does not fail due to a prompt

### REQ-5: `dot_gitconfig.local.tmpl` materializes captured values

The existing `dot_gitconfig.local.tmpl` MUST read `.git.user_name`, `.git.user_email`, and `.git.signingkey` from the merged chezmoi data dictionary. After this change, the data source is the rendered `.chezmoi.toml` (not `.chezmoidata.toml`).

#### Scenario: Real values after interactive init

- GIVEN the user provided real name, email, and signing key during init
- WHEN `chezmoi apply` materializes `~/.gitconfig.local`
- THEN the file contains a valid `[user]` block with the provided values

#### Scenario: Placeholder values after non-interactive init

- GIVEN the user accepted placeholder defaults
- WHEN `chezmoi apply` materializes `~/.gitconfig.local`
- THEN the file contains the placeholder strings in the `[user]` block

#### Scenario: Data source is `.chezmoi.toml`

- GIVEN `.chezmoidata.toml` no longer contains identity fields
- WHEN `dot_gitconfig.local.tmpl` renders
- THEN it reads `.git.*` values from the rendered `.chezmoi.toml` data

### REQ-6: `.chezmoidata.toml` no longer contains identity fields

After this change, `.chezmoidata.toml` MUST NOT contain `user_name`, `user_email`, or `signingkey` keys. It MUST retain `default_branch`, `[brew]`, `[editor]`, and `[os]` sections unchanged.

#### Scenario: Identity fields removed

- GIVEN the change is applied
- WHEN `.chezmoidata.toml` is inspected
- THEN no `user_name`, `user_email`, or `signingkey` keys exist under `[git]`

#### Scenario: Non-identity data preserved

- GIVEN the change is applied
- WHEN `.chezmoidata.toml` is inspected
- THEN `default_branch`, `[brew]`, `[editor]`, and `[os]` sections are intact

### REQ-7: README onboarding reflects the new flow

The README MUST accurately describe the init-time prompt behavior. The current "editá `.chezmoidata.toml`" instruction (lines 22-30 and 82-90) MUST be replaced with a description of the interactive prompts at `chezmoi init`. The README MUST NOT claim that `chezmoi init` prompts if the one-liner is non-interactive (Q2 resolution: note that the one-liner works interactively in TTY, recommend bootstrap for non-TTY).

#### Scenario: Linux/macOS onboarding section updated

- GIVEN the README onboarding section for Linux/macOS
- WHEN a new user reads lines 22-30
- THEN the text describes `chezmoi init` prompting for identity
- AND no instruction to "edit `.chezmoidata.toml`" remains

#### Scenario: Windows onboarding section updated

- GIVEN the README onboarding section for Windows
- WHEN a new user reads lines 82-90
- THEN the text describes `chezmoi init` prompting for identity
- AND no instruction to "edit `.chezmoidata.toml`" remains

#### Scenario: Non-TTY guidance present

- GIVEN the README one-liner section
- WHEN a user reads the install instructions
- THEN a note states the one-liner works interactively (TTY)
- AND bootstrap is recommended for non-TTY/headless installs

### REQ-8: Bootstrap Phase 2 remains idempotent safety net (Q5 resolution)

`scripts/bootstrap.sh` and `scripts/bootstrap.ps1` Phase 2 MUST remain unchanged. The existing guard ("if no `[user]` block in `~/.gitconfig.local`") MUST continue to skip re-write when chezmoi has already materialized identity. Phase 2 covers the "ran bootstrap without `chezmoi init`" edge case.

#### Scenario: Bootstrap after chezmoi init

- GIVEN `chezmoi init` already materialized `~/.gitconfig.local` with a `[user]` block
- WHEN `bootstrap.sh` Phase 2 runs
- THEN the guard detects the `[user]` block and skips prompting

#### Scenario: Bootstrap without chezmoi init

- GIVEN `~/.gitconfig.local` does not exist or has no `[user]` block
- WHEN `bootstrap.sh` Phase 2 runs
- THEN the script prompts for name, email, and signing key
- AND writes `~/.gitconfig.local`

#### Scenario: Bootstrap re-run is idempotent

- GIVEN `bootstrap.sh` has already run and `~/.gitconfig.local` has `[user]`
- WHEN `bootstrap.sh` runs again
- THEN Phase 2 skips without modifying the file

### REQ-9: `modify_dot_gitconfig.local` absent on develop

After this change, no file named `modify_dot_gitconfig.local` MUST exist in the repository root on the `develop` branch. This prevents the inconsistent-state error documented in `archive/2026-05-22-fix-inconsistent-chezmoi-state`.

#### Scenario: File does not exist

- GIVEN the change is applied on `develop`
- WHEN the repository is searched for `modify_dot_gitconfig.local`
- THEN no matching file is found

#### Scenario: Pre-change verification (design phase input)

- GIVEN the current `develop` branch before the change
- WHEN glob `**/modify_dot_gitconfig*` is evaluated
- THEN no matches are returned (verified: file is already absent)

### REQ-10: Migration note for existing users (Q3 resolution)

The README MUST include a migration section for users who previously stored identity values in `.chezmoidata.toml`. The migration MUST be manual (no auto-migration). It MUST document a 3-line process: copy values from old `.chezmoidata.toml` to `~/.chezmoi.toml` or re-run `chezmoi init`.

#### Scenario: Migration note present in README

- GIVEN the README personalization or maintenance section
- WHEN an existing user reads it
- THEN a migration note explains how to move identity values from `.chezmoidata.toml` to the new flow

#### Scenario: Existing user re-runs init

- GIVEN an existing user with identity values in their local `.chezmoidata.toml`
- WHEN they re-run `chezmoi init`
- THEN the prompts collect new values (interactive)
- AND the rendered `.chezmoi.toml` takes precedence over the old `.chezmoidata.toml` values

#### Scenario: Existing user does not re-init

- GIVEN an existing user with identity values in `.chezmoidata.toml` who does NOT re-run `chezmoi init`
- WHEN `chezmoi apply` runs
- THEN `dot_gitconfig.local.tmpl` reads from `.chezmoidata.toml` (still valid data source)
- AND `~/.gitconfig.local` continues to work until the user migrates

## Migration Notes

For users who already configured identity via `.chezmoidata.toml`:

1. No automatic migration — the change is additive for new clones.
2. Existing users who do NOT re-run `chezmoi init` are unaffected; `.chezmoidata.toml` values still flow through `dot_gitconfig.local.tmpl` until the user removes them.
3. Users who want the new prompt flow: re-run `chezmoi init` and answer the prompts, then remove the 3 identity keys from their local `.chezmoidata.toml`.

## Out of Scope

- Reading existing `git config user.name` / `user.email` as prompt defaults (needs post-install hook).
- Changes to `[brew]`, `[editor]`, `[os]`, or other non-identity data fields.
- Age encryption, secret backends, or 1Password integration.
- Modifying `dot_gitconfig.local.tmpl` template logic (unchanged).
- Modifying `scripts/bootstrap.{sh,ps1}` Phase 2 logic (kept as safety net).
- `windows-bootstrap` spec delta (Phase 2 unchanged per Q5).
- Auto-migration of existing users' `.chezmoidata.toml` values.

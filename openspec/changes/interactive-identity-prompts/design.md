# Design: Interactive Identity Prompts at `chezmoi init`

## Technical Approach

Add a `.chezmoi.toml.tmpl` init-time template that uses `promptStringOnce` to capture git identity (name, email, signing key) exactly once during `chezmoi init`. The rendered config file (`~/.config/chezmoi/chezmoi.toml`) stores the responses under `[data.git]`. The existing `dot_gitconfig.local.tmpl` reads `.git.*` from the merged data dictionary — no changes needed there. Remove the 3 identity keys from `.chezmoidata.toml` so the config file becomes the single source of truth for identity. Fix the README to describe the new interactive flow and add a migration note for existing users.

## Architecture Decisions

| Decision | Options | Tradeoff | Choice |
|----------|---------|----------|--------|
| Template location | `.chezmoi.toml.tmpl` vs `.chezmoidata.toml.tmpl` | `.chezmoidata.$FORMAT` cannot be templates (chezmoi docs explicit) | `.chezmoi.toml.tmpl` |
| Prompt defaults (Q1) | Empty string / placeholder / read from git config | Empty = silent failure; git config = out of scope | Placeholder `"set later in ~/.chezmoi.toml"` |
| Migration strategy (Q3/Q6) | Auto-migration template / README note only / transitional template | Auto-migration adds complexity for a small user base; git conflict IS the notification | README note only |
| Bootstrap Phase 2 (Q5) | Keep / delete / repurpose | Delete breaks standalone-bootstrap path; repurpose adds second writer | Keep as safety net |
| Data precedence | Config `[data]` vs `.chezmoidata.toml` | `.chezmoidata.toml` overrides config `[data]` (chezmoi merge order) | Remove identity from `.chezmoidata.toml` so config values take effect |

## Data Flow

```
chezmoi init
    │
    ├─ renders .chezmoi.toml.tmpl (source state, tracked in git)
    │   ├─ promptStringOnce → prompts user (TTY) or uses defaults (non-TTY)
    │   └─ writes → ~/.config/chezmoi/chezmoi.toml (local, NOT tracked)
    │       └─ [data.git] user_name, user_email, signingkey
    │
chezmoi apply (any subsequent command)
    │
    ├─ reads ~/.config/chezmoi/chezmoi.toml [data] section  (precedence: lower)
    ├─ reads .chezmoidata.toml                               (precedence: higher, overrides)
    ├─ merges data dictionaries
    │   └─ .git.user_name etc. come from config file (no longer in .chezmoidata.toml)
    │
    └─ renders dot_gitconfig.local.tmpl → ~/.gitconfig.local
        └─ {{ .git.user_name }}, {{ .git.user_email }}, {{ if .git.signingkey }}
```

**Chezmoi data merge order** (confirmed from docs): config file `[data]` is loaded first, then `.chezmoidata.$FORMAT` files merge on top (overriding). By removing identity keys from `.chezmoidata.toml`, the config file's `[data.git]` values flow through unchallenged.

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `.chezmoi.toml.tmpl` | **Create** | Init-time template: 3 `promptStringOnce` under `[data.git]` + folded static config (see REQ-11) |
| `.chezmoidata.toml` | Modify | Remove `user_name`, `user_email`, `signingkey` keys and comment (lines 11-16) |
| `dot_config/chezmoi/chezmoi.toml` | **Delete** | Folded into `.chezmoi.toml.tmpl` to avoid source-managed overwriting rendered init template |
| `README.md` | Modify | Replace onboarding text (lines 26, 85); add migration note |
| `dot_gitconfig.local.tmpl` | Unchanged | Verified: reads `.git.*` from merged data, works with new source |
| `scripts/bootstrap.sh` | Unchanged | Phase 2 guard (`grep -q "\[user\]"`) still works |
| `scripts/bootstrap.ps1` | Unchanged | Phase 2 guard (`Select-String '\[user\]'`) still works |
| `modify_dot_gitconfig.local` | Verified absent | Glob `**/modify_dot_gitconfig*` returned no matches on `develop` |

## Concrete File Designs

### `.chezmoi.toml.tmpl` (new — full content)

```toml
{{- $name := promptStringOnce . "git.user_name" "Git user name" "set later in ~/.chezmoi.toml" -}}
{{- $email := promptStringOnce . "git.user_email" "Git user email" "set later in ~/.chezmoi.toml" -}}
{{- $key := promptStringOnce . "git.signingkey" "GPG signing key (leave empty if none)" "set later in ~/.chezmoi.toml" -}}
[data.git]
    user_name = {{ $name | quote }}
    user_email = {{ $email | quote }}
    signingkey = {{ $key | quote }}

[git]
    autoAdd = true
    autoCommit = true
    autoPush = false
    commitMessageTemplate = "chore: sync dotfiles"

[diff]
    pager = "delta"

# Interpreters.ps1 no declarado explícitamente para que chezmoi maneje
# el auto-fallback: pwsh → powershell.exe en Windows, pwsh en Unix.
# Ver https://chezmoi.io/reference/configuration-file/interpreters/

# Encripción age para archivos sensibles.
# Descomentar después de generar la clave:
#   chezmoi age-keygen --output=~/.config/chezmoi/key.txt
# y copiar la public key como recipient.
#
# encryption = "age"
# [age]
#     identity = "~/.config/chezmoi/key.txt"
#     recipient = "age1..."
```

**Why the static config lives here, not in the source-managed file**: both `.chezmoi.toml.tmpl` and the source-managed `dot_config/chezmoi/chezmoi.toml` would render to the same target (`~/.config/chezmoi/chezmoi.toml`). The source-managed version would overwrite the prompted `[data.git]` section on every `chezmoi apply`. Folding the static config into the init-time template makes the rendered config the single source of truth. See "Design Revision" below.

**Syntax notes**: `promptStringOnce map path prompt [default]` — `.` is the config data map (empty on fresh install, populated on re-init); `"git.user_name"` is a dot-path into the map; 4th arg is the default returned on non-TTY or when the user presses Enter. The `quote` function wraps values in double quotes for valid TOML.

### Rendered `~/.config/chezmoi/chezmoi.toml` (example output)

```toml
[data.git]
    user_name = "Row"
    user_email = "row@example.com"
    signingkey = "ABCDEF1234567890"
```

On re-init, `promptStringOnce` finds `.git.user_name` in the existing config and returns it without prompting — idempotent.

### `.chezmoidata.toml` diff

```diff
 [brew]
 prefix_darwin = "/opt/homebrew"
 prefix_linux = "/home/linuxbrew/.linuxbrew"

 [editor]
 command = "code --wait"
 diff = "nvim -d"

 [git]
 default_branch = "main"
-# Editar localmente: user_name, user_email, signingkey.
-# Para prompts interactivos en init, mover a .chezmoidata.toml.tmpl
-# con promptStringOnce (ver archive 2026-05-22-fix-inconsistent-chezmoi-state).
-user_name = ""
-user_email = ""
-signingkey = ""

 [os]
 config_dir = ".config"
```

Result: `[git]` section retains only `default_branch = "main"`.

## README Changes

### Linux/macOS onboarding (replace line 26)

**Current** (the lie):
> Esto clona el repo y aplica todas las configuraciones. Después, editá `~/.local/share/chezmoi/.chezmoidata.toml` con tu `user_name`, `user_email` y `signingkey` y reejecutá `chezmoi apply` para que tome efecto en `~/.gitconfig.local`.

**Replacement**:
> Esto clona el repo, te pregunta tu nombre, email y signing key de git, y aplica todas las configuraciones. `~/.gitconfig.local` se genera automáticamente con tus respuestas. Para cambiar los valores, editá `~/.config/chezmoi/chezmoi.toml`.
>
> > **Nota**: el comando único funciona en terminales interactivas (TTY). Para entornos no-interactivos (CI, pipes), usá el bootstrap completo.

### Windows onboarding (replace line 85)

**Replacement**:
> Esto clona el repo, te pregunta tu nombre, email y signing key de git, y aplica todas las configuraciones. `~\.gitconfig.local` se genera automáticamente con tus respuestas. Para cambiar los valores, editá `~\.config\chezmoi\chezmoi.toml`.
>
> > **Nota**: el comando único funciona en terminales interactivas (TTY). Para entornos no-interactivos, usá el bootstrap completo (`bootstrap.ps1`).

### Migration note (new section, after "Personalización local")

```markdown
## Migración: identidad git (usuarios existentes)

Si antes configuraste tu identidad editando `.chezmoidata.toml`, tenés dos opciones:

### Opción A: Re-ejecutar `chezmoi init` (recomendado)

```sh
chezmoi init
```

Te va a preguntar tu nombre, email y signing key. Los valores se guardan en `~/.config/chezmoi/chezmoi.toml` y toman precedencia sobre `.chezmoidata.toml`.

Después, eliminá las 3 líneas de identidad de tu `.chezmoidata.toml` local:

```sh
# Verificar qué valores tenés
chezmoi data | grep -A3 git

# Aplicar cambios
chezmoi apply
```

### Opción B: Copiar valores manualmente

Editá `~/.config/chezmoi/chezmoi.toml` (crealo si no existe):

```toml
[data.git]
    user_name = "Tu nombre"
    user_email = "tu@email.com"
    signingkey = "TU_KEY"
```

### Si no hacés nada

Tu próximo `chezmoi update` va a traer un `.chezmoidata.toml` sin las 3 líneas de identidad. Si tenías valores locales, git te va a pedir que resuelvas el conflicto. Aceptá la versión upstream (sin las líneas) y seguí la Opción A o B.
```

## Q6 Resolution

**Choice**: README note only (option b from the spec's Q3 resolution).

**Justification**:
- **Affected users**: Only users who (a) cloned this repo before this change AND (b) manually edited `.chezmoidata.toml` with real identity values. For a personal dotfiles repo, this is likely 1-3 users (the owner + any early adopters).
- **What happens on `chezmoi update`**: Git detects the conflict between the user's local edits (filled-in values) and the upstream change (removed lines). The user gets a standard merge conflict — this IS the notification mechanism. They cannot silently lose data.
- **Worst-case UX**: User sees a git conflict in `.chezmoidata.toml`, resolves it (accept upstream), then follows the README migration note to set up identity via `chezmoi init` or manual config.
- **Recovery**: The migration note provides two paths (re-init or manual copy) plus a `chezmoi data | grep` verification command.
- **Why not a transitional template**: A one-time template that seeds defaults from `.chezmoidata.toml` would require reading `.chezmoidata.toml` from within `.chezmoi.toml.tmpl` — but the chezmoi docs explicitly state that `.chezmoidata.$FORMAT` data is NOT available in init-time templates. The only alternative would be a `run_once_` script, which violates the hard constraint (no apply-time prompts).

## Bootstrap Interaction

### `scripts/bootstrap.sh` Phase 2

The existing guard (line 82):
```bash
if [ -f "$GITCONFIG_LOCAL" ] && grep -q "\[user\]" "$GITCONFIG_LOCAL" 2>/dev/null; then
    ok "~/.gitconfig.local ya existe con identidad configurada"
```

**Contract**: In the normal flow (`chezmoi init --apply` → `bootstrap.sh`), chezmoi has already materialized `~/.gitconfig.local` with a `[user]` block. Phase 2 detects it and skips — **no-op**. In the edge case (user runs `bootstrap.sh` without `chezmoi init`), `~/.gitconfig.local` doesn't exist, Phase 2 prompts and creates it — **safety net works**.

### `scripts/bootstrap.ps1` Phase 2

Same pattern (line 87):
```powershell
if ((Test-Path $gitconfigLocal) -and (Select-String -Path $gitconfigLocal -Pattern '\[user\]' -Quiet)) {
```

**Contract**: Identical to bash. Guard detects chezmoi-created `[user]` block → skips. No `[user]` → prompts.

**Both scripts are unchanged.** No spec delta needed for `windows-bootstrap`.

## Sequence Diagram

```
Fresh clone (TTY)                    Fresh clone (non-TTY)         Bootstrap without init
─────────────────                    ─────────────────────         ──────────────────────
git clone → chezmoi init             git clone → chezmoi init      git clone → bootstrap.sh
    │                                    │                              │
    ├─ .chezmoi.toml.tmpl renders        ├─ .chezmoi.toml.tmpl renders  ├─ Phase 1: brew bundle
    ├─ promptStringOnce × 3              ├─ promptStringOnce × 3        ├─ Phase 2: no [user] block
    │   └─ user types real values        │   └─ non-TTY → defaults      │   └─ prompts for identity
    ├─ writes ~/.config/chezmoi/         ├─ writes ~/.config/chezmoi/   │   └─ writes ~/.gitconfig.local
    │   chezmoi.toml [data.git]          │   chezmoi.toml [data.git]    ├─ Phases 3-6: SSH, gh, etc.
    ├─ chezmoi apply (if --apply)        │   (placeholder values)       └─ Done
    │   ├─ reads config [data.git]       ├─ chezmoi apply (if --apply)
    │   ├─ reads .chezmoidata.toml       │   ├─ reads config [data.git]
    │   │   (no identity keys)           │   ├─ reads .chezmoidata.toml
    │   ├─ merges → .git.* from config   │   │   (no identity keys)
    │   └─ renders ~/.gitconfig.local    │   ├─ merges → .git.* from config
    │       (real values)                │   └─ renders ~/.gitconfig.local
    └─ Done                              │       (placeholder values)
                                         └─ User edits ~/.config/chezmoi/
                                             chezmoi.toml → chezmoi apply
```

## Risks and Trade-offs

| Gain | Cost |
|------|------|
| Real prompts at init — no README lie | Existing users with `.chezmoidata.toml` values need a manual migration step |
| Single source of truth for identity (config file) | Non-TTY installs get placeholder values (loud failure, not silent) |
| `chezmoi apply --dry-run` stays silent (hard constraint preserved) | 1 new file to maintain |
| Bootstrap Phase 2 remains as safety net (no regression) | — |

**Net change**: +1 file (~7 lines), -6 lines from `.chezmoidata.toml`, ~30 lines README modification. Total ~43 changed lines.

## Threat Matrix

N/A — no routing, shell commands, subprocesses, VCS/PR automation, executable-file classification, or process-integration boundary. The change is purely declarative (chezmoi templates and data files).

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Manual | Fresh clone + `chezmoi init` prompts correctly | Run on a test machine or container |
| Manual | `chezmoi apply --dry-run` is silent after init | Verify no prompts, exit 0 |
| Manual | Non-TTY `chezmoi init` uses defaults | Pipe stdin: `echo "" \| chezmoi init` |
| Manual | Re-init doesn't re-prompt | Run `chezmoi init` twice |
| Manual | Bootstrap Phase 2 skips after chezmoi init | Run init then bootstrap |
| Manual | Migration: existing user git conflict | Simulate: edit `.chezmoidata.toml`, then pull change |

No automated tests (per `openspec/config.yaml`: `strict_tdd: false`, `testing.unit: false`).

## Open Questions

- [ ] None — all 5 proposal questions (Q1-Q5) resolved; Q6 resolved in this design.

## Design Revision: Consolidate `~/.config/chezmoi/chezmoi.toml` (added by orchestrator, 2026-07-11)

**Issue caught by sdd-apply end-to-end verification (memory #416)**: the proposed change created `.chezmoi.toml.tmpl` (which renders `~/.config/chezmoi/chezmoi.toml` with `[data.git]`), but the existing source-managed `dot_config/chezmoi/chezmoi.toml` ALSO deploys to `~/.config/chezmoi/chezmoi.toml` on every `chezmoi apply`. The source-managed file overwrote the rendered init template, removing `[data.git]`, and the next `chezmoi apply` failed with `map has no entry for key "user_name"`. Neither the spec nor the design caught this because neither ran end-to-end in a chezmoi-managed environment.

**Resolution (REQs-11, see spec)**: fold the contents of the source-managed file into the new init-time template, and delete the source-managed file. The rendered `~/.config/chezmoi/chezmoi.toml` becomes the single source of truth for both prompted data and static config.

**Implications**:
- File count goes from "1 added, 2 modified" to "1 added, 2 modified, 1 deleted".
- Estimated changed lines go from ~43 to ~88 (template is larger because it absorbs the static config; deletion of the source-managed file accounts for ~22 lines of net change).
- Sizing update: still well under 400-line review budget.
- Comment preservation: the Interpreters and age comments from the source-managed file live in the new template (TOML output cannot carry comments, but the source template can).
- User editability: any local edits to `~/.config/chezmoi/chezmoi.toml` are still preserved after the first init; subsequent inits do not overwrite (the file is only rendered when absent).

## Sizing

- **Files added**: 1 (`.chezmoi.toml.tmpl`, ~30 lines incl. folded static config)
- **Files modified**: 2 (`.chezmoidata.toml` -6 lines, `README.md` +30 lines)
- **Files deleted**: 1 (`dot_config/chezmoi/chezmoi.toml`, 22 lines)
- **Files unchanged but verified**: 5 (`dot_gitconfig.local.tmpl`, `bootstrap.sh`, `bootstrap.ps1`, `openspec/config.yaml`, `modify_dot_gitconfig.local` absence)
- **Estimated changed lines**: ~88
- **PR strategy**: Single PR (well under 400-line review budget)

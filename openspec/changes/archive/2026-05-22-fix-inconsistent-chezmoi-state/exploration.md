## Exploration: fix-inconsistent-chezmoi-state

### Current State

Two issues in the chezmoi dotfiles repo, both discovered through runtime behavior.

---

#### Issue 1: Inconsistent gitconfig state

chezmoi reports `chezmoi: .gitconfig.local: inconsistent state` because two source files target the same destination:

1. **`dot_gitconfig.local.tmpl`** — Full template that creates `~/.gitconfig.local` from chezmoi config variables (`.git.user_name`, `.git.user_email`, `.git.signingkey`). Non-interactive, declarative approach.

2. **`modify_dot_gitconfig.local`** — Modify template (via `chezmoi:modify-template` comment) that reads existing `~/.gitconfig.local`, runs `promptStringOnce` for name/email/signingkey, and writes back. WAS meant for `chezmoi init` prompts.

These two approaches are **mutually exclusive** in chezmoi — you cannot have both a template AND a modify script writing to the same destination.

**History**:
- `dot_gitconfig.local.tmpl` was created in early bootstrap/config-foundation phase (declarative template approach)
- `modify_dot_gitconfig.local` was added in commit `32b2ece` ("feat: security layer — age encryption setup + modify gitconfig template") as part of the Security Layer change
- A fix was committed in `cadbc0b` on branch `fix/remove-conflicting-gitconfig-local` which deleted `modify_dot_gitconfig.local`, but this branch was **never merged** into `develop`
- The `develop` branch (HEAD) still has both files

**Additional issue**: `modify_dot_gitconfig.local` uses `promptStringOnce`, which is an **init-only** chezmoi function — it only works during `chezmoi init`, not during `chezmoi apply`. The commit `79483a0` ("fix: remove init-only prompt functions from templates") removed `promptStringOnce` from other templates but did NOT touch this modify script.

---

#### Issue 2: PowerShell script runs on Ubuntu

`run_once_before_install-packages.ps1.tmpl` is a PowerShell script (winget install) that:
- Has no `#!` shebang (it's PowerShell, not a shell script)
- Uses PowerShell syntax (`$packages = @(...)`, `Write-Host`, `Get-Command`, etc.)
- Tries to install Windows-only `winget` packages

The companion `run_once_before_install-packages.sh.tmpl` installs via `brew bundle` for Linux/macOS.

**Protection layers (already in place)**:
1. **`.chezmoiignore`** (lines 13-14) uses template-conditioned glob patterns:
   ```
   {{ if eq .chezmoi.os "windows" }}run_once_*.sh{{ end }}
   {{ if ne .chezmoi.os "windows" }}run_once_*.ps1{{ end }}
   ```
   This prevents the `.ps1` from being deployed on non-Windows (and `.sh` on Windows). chezmoi strips `.tmpl` before pattern matching, so the glob matches correctly.

2. **Unstaged working-tree changes** (not committed) added:
   - `#!/bin/sh` shebang on line 1 — incorrect for a PowerShell script, but harmless (PowerShell treats `#` as comment)
   - `{{ if ne .chezmoi.os "windows" }}...exit 0...{{ end }}` guard — **redundant** given `.chezmoiignore` already prevents execution on non-Windows

**The internal guard vs `.chezmoiignore` debate**:
- `.chezmoiignore` controls **whether the file is deployed** (written to destination). If the file never reaches the filesystem, it can't execute. This is the primary, correct defense.
- An internal guard adds defense-in-depth, but the current implementation is messy: `#!/bin/sh` on a PowerShell script is confusing and signals wrong intent.
- The `.chezmoiignore` pattern is robust — it uses `{{ if ne .chezmoi.os "windows" }}` which covers ALL non-Windows platforms (Linux, macOS, WSL2, BSD).

---

### Affected Areas

- **`dot_gitconfig.local.tmpl`** — Declarative template for `~/.gitconfig.local`. The winner in the conflict.
- **`modify_dot_gitconfig.local`** — Modify template conflicting with the above. Should be deleted.
- **`run_once_before_install-packages.ps1.tmpl`** — PS1 script with unstaged modifications (`#!/bin/sh` + redundant OS guard).
- **`.chezmoiignore`** — Already has correct OS-level script filtering. Not affected.
- **`dot_gitconfig.tmpl`** — Main gitconfig; may need review if modify template was fixing fields here vs the `.local` file.

### Approaches

#### Issue 1: Gitconfig inconsistency

1. **Delete `modify_dot_gitconfig.local`** — The fix already committed on `fix/remove-conflicting-gitconfig-local` but never merged. `dot_gitconfig.local.tmpl` is the preferred approach: non-interactive, declarative, works with chezmoi config variables.
   - Pros: Simple, already implemented in a branch, removes the conflict entirely
   - Cons: Lose the init-time prompting for git identity
   - Effort: **Low**

2. **Delete `dot_gitconfig.local.tmpl`, keep modify template** — Switch to the modify approach entirely.
   - Pros: Interactive prompting during init
   - Cons: `promptStringOnce` is init-only; modify templates run during `chezmoi apply`, where prompts don't work. Would need to migrate to `promptOnce` or a different strategy. And the template has been working fine.
   - Effort: **Medium**

3. **Reconcile: different destination names** — Rename one to target a different file.
   - Pros: Both can coexist
   - Cons: Adds complexity, unclear which the user should edit. Not meaningful.
   - Effort: **Low**

**Recommendation**: Approach 1 — merge the existing fix from `fix/remove-conflicting-gitconfig-local`.

#### Issue 2: PowerShell script

1. **Accept unstaged changes as-is** — commit the `#!/bin/sh` + internal guard.
   - Pros: Nothing to do
   - Cons: `#!/bin/sh` on a PowerShell script is semantically wrong; internal guard is redundant with `.chezmoiignore`
   - Effort: **Low**

2. **Clean up: remove shebang + internal guard** — The `.chezmoiignore` already provides correct OS filtering. Remove the unstaged changes and rely on the ignore patterns.
   - Pros: Clean, correct, no confusing artifacts
   - Cons: Less defense-in-depth (if `.chezmoiignore` breaks, the PS1 would run on Linux)
   - Effort: **Low**

3. **Clean up: keep internal guard, fix shebang** — Remove `#!/bin/sh`, keep `#!/usr/bin/env pwsh` (proper PowerShell shebang for platforms that support it) and the `{{ if }}` guard.
   - Pros: Defense-in-depth + correct shebang
   - Cons: Shebang is unnecessary on Windows (the primary target); slightly more complex
   - Effort: **Low**

4. **Delete the PS1 script entirely** — If the user doesn't use Windows.
   - Pros: Simplest
   - Cons: Destructive; Windows users lose winget automation
   - Effort: **Low**

**Recommendation**: Approach 3 (defense-in-depth with correct shebang). Keep the `.chezmoiignore` as primary defense, but the internal guard doesn't hurt if done properly. The `#!/bin/sh` must go — it's misleading.

### Recommendation

**Fix both issues in one change:**

1. **Gitconfig**: Cherry-pick/merge `cadbc0b` from `fix/remove-conflicting-gitconfig-local` into `develop` to delete `modify_dot_gitconfig.local`. This resolves the inconsistent state error and removes the broken `promptStringOnce` calls.

2. **PS1 script**: Replace the working-tree changes with a clean fix:
   - Remove `#!/bin/sh` (line 1)
   - Keep the `{{ if ne .chezmoi.os "windows" }}` guard but use proper syntax
   - Optionally add `#!/usr/bin/env pwsh` for correctness on Unix systems with pwsh installed

3. **Verify**: Run `chezmoi apply --dry-run` (or `chezmoi execute-template`) to confirm no more inconsistent state errors.

### Risks

- **Rolling back the modify template removes git-identity prompting during `chezmoi init`**. Mitigation: the template approach works with `chezmoi.toml` data (`[data] git.user_name`, etc.), which can be set during init via `.chezmoi.toml.tmpl` if desired.
- **The PS1 internal guard check could have edge cases** if `.chezmoi.os` returns unexpected values. Mitigation: `.chezmoiignore` is the primary defense; the internal guard is secondary.
- **The PS1 `exit 0` inside the template guard must end the PowerShell script**, not the shell. Since the outer template renders the `exit 0` only when `.chezmoi.os != "windows"` evaluates to true, and the shebang is `#!/bin/sh`, on non-Windows it would actually run under `sh` and exit correctly. On Windows, the guard renders nothing and the PowerShell code executes. This is fragile and confusing — which is why the proper fix matters.

### Ready for Proposal

**Yes** — both issues are well-understood, fixes are straightforward, and there's no ambiguity about what needs to change. The orchestrator should propose:
1. Delete `modify_dot_gitconfig.local` (merge the existing fix branch or re-apply the deletion)
2. Fix `run_once_before_install-packages.ps1.tmpl` (replace the working-tree changes with a clean internal guard)

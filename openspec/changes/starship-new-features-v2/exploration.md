## Exploration: Starship New Features v2

### Current State

The prompt is a two-line layout with these modules on line 1:
`$os $directory $git_branch $git_status $direnv $package $bun $nodejs $python $rust $golang $fill $time $cmd_duration`

And line 2: `$status $character`

Starship is at **v1.25.1** (installed via Homebrew on Fedora 44 WSL2).

### Affected Areas

- `dot_config/starship.toml` — The only file that needs changes. Sections affected:
  - `[python]` — add `generic_venv_names`
  - `[status]` — add `success_symbol` and `success_style`
  - `[container]` — optionally add subtle container indicator
  - `[git_status]` — optionally add worktree/index variable granularity
  - `[directory.substitutions]` — optionally convert to regex array format
  - `[shlvl]` — optionally add shell level indicator

### Feature Analysis

#### 1. Python `generic_venv_names` ⭐ RECOMMENDED

| Aspect | Detail |
|--------|--------|
| Config key | `generic_venv_names` (NOT `replace_venv_name` — that was the discussion name) |
| Default | `[]` (disabled) |
| What it does | List of venv names (e.g. `".venv"`, `"venv"`) that get replaced with the parent directory name in the `$venv` variable |
| uv interaction | `uv venv` creates `.venv` by default. With `generic_venv_names = [".venv", "venv"]`, instead of showing `(.venv)` it shows the project name (parent directory). Works perfectly — no special uv support needed, Starship just reads `VIRTUAL_ENV` env var and checks the basename |
| Current format | `'[ $symbol($version)(\($venv\))]($style)'` — currently would show `.venv`, unhelpful |
| Verdict | **Pure win.** Zero risk, clean improvement. Current behavior shows raw `.venv` which is noise. |

Suggested config:
```toml
[python]
# ...
generic_venv_names = [".venv", "venv"]
```

#### 2. `status` — `success_symbol` + `success_style` ⭐ RECOMMENDED

| Aspect | Detail |
|--------|--------|
| Options | `success_symbol` (already exists, currently `""`), `success_style` (new in v1.24.0) |
| What it does | Shows a green checkmark on command success instead of hiding the module entirely |
| Current config | `success_symbol = ""` — module is invisible on success |
| Verdict | **Small visual polish.** A subtle `✓` in green gives immediate visual feedback that the command succeeded. Zero risk. |

Suggested config:
```toml
[status]
disabled = false
format = "[$symbol]($style)"
style = "fg:red"
success_symbol = "[✓](fg:green)"
success_style = "fg:green"
failure_style = "fg:red"
```

#### 3. `git_status` — worktree/index granularity ⚠️ NICE-TO-HAVE

| Aspect | Detail |
|--------|--------|
| What's new | `worktree_added`, `worktree_deleted`, `worktree_modified`, `worktree_typechanged`, and corresponding `index_*` variables. Each supports `$count`. |
| Current setup | `format = "[($all_status$ahead_behind)]($style)"` which is shortcut for `$conflicted$stashed$deleted$renamed$modified$typechanged$staged$untracked` |
| Value add | The new vars let you distinguish "unstaged modified" from "staged modified", and "worktree added" from "index added". Useful for power users who frequently use `git add -p` |
| Risk | All new options default to `""` (hidden), so no breaking change. Opt-in only. |
| Verdict | **Useful but incremental.** Only meaningful if the user frequently works with partial staging. Default `$all_status` already shows a consolidated view. Sugar, not necessary. |

#### 4. `directory.substitutions` — regex support ⚠️ NICE-TO-HAVE

| Aspect | Detail |
|--------|--------|
| New format | Array of `{from, to, regex}` objects instead of the old table `{key = value}` |
| Current config | Old table format with `Documents`, `Downloads`, `Music`, `Pictures` substitutions |
| What regex enables | Pattern matching e.g. `{from = "^rust-", to = "⚙️ ", regex = true}` to replace `rust-something` dirs, or `{from = "-api$", to = " 🖥", regex = true}` for backend dirs |
| Compat | Old syntax still works alongside new. No Nerd Font dependency — it's pure string manipulation. |
| Verdict | **Only if the user has a need.** The current substitutions are for standard dirs. Regex is powerful but the use case is niche. Don't add without a clear pattern need. Font question irrelevant. |

#### 5. `container` module ⚠️ USEFUL WITH CAVEAT

| Aspect | Detail |
|--------|--------|
| What it shows | Symbol + container name when inside a Docker/Podman/toolbox container |
| WSL behavior | WSL2 is **NOT** detected as a container (it's a lightweight VM, not a container runtime). Module stays hidden during normal WSL use. |
| When it would fire | Only when the user runs `docker exec`, `podman exec`, or enters a toolbox/distrobox |
| Risk | None — it only shows when inside an actual container runtime. Subtle by default. |
| Verdict | **Useful for container work.** Add as minimal format like `format = "[$symbol]($style)"` with a low-visibility style. Shows you're "inside" vs "outside". |

#### 6. `shell` module ❌ SKIP

| Aspect | Detail |
|--------|--------|
| What it shows | `fsh`, `bsh`, `zsh` indicators |
| Verdict | User runs fish 100% of the time. Always showing `fsh` is noise. Zero value. |

#### 7. `shlvl` module ❌ SKIP

| Aspect | Detail |
|--------|--------|
| What it shows | Current `SHLVL` value when ≥ threshold (default: 2) |
| Verdict | Only useful if the user frequently nests shells (e.g., `exec fish`, `tmux`). In Fish + tmux, SHLVL increments. The user uses tmux (via lazyvim), so it could fire. But it's niche and adds clutter. Skip unless the user explicitly requests it. |

### Approaches

#### Approach A: "Status Enhancement Pack" (RECOMMENDED)

Focus on the two highest-value, zero-risk changes that make the prompt smarter without adding visual noise.

**Includes:**
1. `python.generic_venv_names = [".venv", "venv"]` — replace `.venv` with project name
2. `status.success_style` + `status.success_symbol` — green ✓ on success

**Effort:** Low (5 minutes, 2 config changes)
**Impact:** Medium — visible improvement in Python projects and command feedback
**Risk:** None

#### Approach B: "Full v2 Enhancement Pack"

All useful features in one batch.

**Includes:**
1. Everything from Approach A
2. `container` module — subtle WSL indicator (format: `[$symbol]($style)`)
3. `git_status` worktree/index variables — if the user wants granular git status
4. `directory.substitutions` regex — if the user has specific patterns
5. `shlvl` — only if requested

**Effort:** Low-Medium (10-15 minutes, 4-5 config changes)
**Impact:** Medium — adds more context but risks clutter
**Risk:** Low — all opt-in, no breaking changes

#### Approach C: "Python-only fix"

Just the `generic_venv_names` change.

**Effort:** Trivial (2 minutes)
**Impact:** Small but meaningful for Python devs
**Risk:** None

### Recommendation

**Approach A: "Status Enhancement Pack"**

1. Add `generic_venv_names = [".venv", "venv"]` to `[python]` — **essential**. Current behavior shows the literal `.venv` name which is useless noise. uv creates `.venv` by default, so this directly benefits the user's workflow.

2. Add `success_symbol = "[✓](fg:green)"` and `success_style = "fg:green"` to `[status]` — **polish**. The current prompt hides status on success entirely. A subtle green checkmark adds immediate visual confirmation that the command passed.

Skip `container`, `shlvl`, `shell` for now. They add visual mass with marginal benefit. The two-line prompt has limited real estate — don't fill it with always-on indicators.

Skip `git_status` granularity and regex substitutions unless the user has specific use cases. They're valid features but should be "pull" (requested) not "push" (proactive).

### Key Config Name Correction

The exploration brief mentioned `replace_venv_name`. The actual config option in Starship 1.25 is **`generic_venv_names`** (a list of strings, not a single boolean). This was renamed from early discussions.

### Font Compatibility

None of the recommended features require Nerd Font v3. The ✓ symbol is widely supported. The directory substitutions are purely string-based. No font concerns.

### Risks

- **None for recommended changes.** All are opt-in, additive, and don't break existing behavior.
- `generic_venv_names` only affects display, not functionality. Dropping it or changing it later is trivial.
- The `status` module already works. Adding `success_symbol` just changes what success looks like — no breaking change.

### Ready for Proposal

**Yes.** The analysis is complete. Recommend proceeding with **Approach A ("Status Enhancement Pack")** — two config changes, zero risk, visible improvement.

- `[python]` → `generic_venv_names`
- `[status]` → `success_symbol` + `success_style`

Proposal should also note that `container`, `shlvl`, `git_status` granularity, and regex substitutions are available if the user wants them, but are not recommended for the initial pass.

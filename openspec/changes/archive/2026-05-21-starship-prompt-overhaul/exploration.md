## Exploration: starship-prompt-overhaul

### Current State

**Prompt layout (single-line, powerline-style)**:
The current `dot_config/starship.toml` builds a segmented prompt using Unicode powerline triangles () with a monochromatic blue-purple palette:

```
░▒▓   ~ Dir …/subdir  main  📦 v1.0.0  (v20.0.0)  (v3.12) ...  02:30 PM
$
```

Format chain: `[decorative] → $directory → $git_branch → $git_status → $package → $bun → $nodejs → $python → $rust → $golang → $php → $cmd_duration → $time → \n → $character`

**Color palette** (5 shades, dark→light):
- `#090c0c` (near-black text on decorative)
- `#1d2230` (darkest bg)
- `#212736` (dark bg)
- `#394260` (mid bg)
- `#769ff0` (accent blue)
- `#a3aed2` (lightest bg/accent)
- Text: `#e3e5e5`, `#a0a9cb`

**fish_prompt.fish interaction**:
The file `dot_config/fish/functions/fish_prompt.fish` defines a simple `last_dir (git_branch) $` prompt — but `starship init fish | source` (in `conf.d/starship.fish`) **overrides** it. The custom `fish_prompt.fish` is effectively dead code when Starship is active. It serves only as a fallback if starship is not installed or fails.

**Tool ecosystem detected** (confirmed in conf.d/ or PATH):
| Tool | Config Found | Starship Module Available |
|------|-------------|--------------------------|
| Atuin (shell history) | conf.d/atuin.fish | ❌ No native module |
| Zoxide (smart cd) | conf.d/zoxide.fish | ❌ No native module |
| Eza (ls replacement) | conf.d/eza.fish | ❌ No native module |
| Bat (cat) | conf.d/bat.fish | ❌ No native module |
| Direnv (env mgmt) | conf.d/direnv.fish | ✅ `$direnv` |
| Docker | conf.d/docker.fish | ✅ `$docker_context` |
| FNM (Node) | conf.d/fnm.fish | ✅ (uses `$nodejs`, already shown) |
| LazyGit | conf.d/lazygit.fish | ❌ No native module |
| Rust/Cargo | conf.d/rustup.fish | ✅ `$rust`, already shown |
| Bun | ~/.bun/bin in PATH | ✅ `$bun`, already shown |
| Go | ~/go/bin in PATH | ✅ `$golang`, already shown |
| Neovim | conf.d/nvim.fish | ❌ Not relevant for prompt |
| OpenCode | conf.d/opencode.fish | ❌ Not relevant for prompt |

**Modules shown but possibly unused**:
- `$php` — no PHP extensions, no PHP conf.d, no PHP version manager found. Likely never triggers, but adds scan overhead.
- `$package` — depends on finding package.json/Cargo.toml etc. Useful but should only show when relevant.
- `$golang` — `~/go/bin` is in PATH, but no Go version manager. Shows only when Go files are detected.

### Affected Areas

- `dot_config/starship.toml` — **primary file**, the entire prompt config
- `dot_config/fish/functions/fish_prompt.fish` — **potential removal or simplification** (if starship remains the only prompt, this becomes dead code)
- `dot_config/fish/conf.d/starship.fish` — **minor**: may need adjustment if we change how starship is initialized

### Approaches

#### 1. Clean Two-Line (Recommended)

A two-line prompt with info on top and input on bottom. Removes unused modules, adds missing ones based on actual tool usage.

```
 ~/Dev/project  main    v1.0.0  v20.0.0  v1.75                     02:30 PM 祥 2s
$ _
```

**Format**: `$os $directory $git_branch $git_status $fill $time $cmd_duration $line_break $character`

**Key changes**:
- Add `$os` (shows OS/distro icon like  for Nix/NixOS)
- Add `$direnv` (user has direnv installed)
- Add `$line_break` (two-line layout)
- Add `$fill` (pushes time/duration to right)
- Remove `░▒▓ ` decorative segment (reduces noise)
- Remove `$php`, `$golang` (unused — let `$all`-like approach handle them or remove entirely)
- Optionally keep `$package`, `$bun`, `$nodejs`, `$python`, `$rust` — they only show when relevant
- Refine color palette (fewer segments = simpler palette)
- Add `$status` module (show exit code on error, hidden on success)

**Pros**: Cleaner, faster (fewer modules scanned), modern two-line layout, adds relevant modules (direnv, os, status), removes unused modules
**Cons**: Loses the decorative powerline style (if user likes it), two lines takes more vertical space
**Effort**: Low (one file change, minor)

---

#### 2. Info-Rich Powerline (Preserve & Extend)

Keep the current powerline segmented style but modernize: add missing modules, introduce `$fill` and `$line_break`, refine colors, use `right_format`.

```
░▒▓    ~/Dev/project · main·    v1.0.0  v20.0.0  v1.75 ···祥 2s
                                                                       02:30 PM
$ _
```

**Format** (left): `[decorative]$os$directory$git_branch$git_status$fill[duration]`
**Right format**: `$time`
**Or**: `format = "decorative line_break $os $directory $git_branch $git_status $direnv $fill $cmd_duration\n$character"`

**Key changes**:
- Add `$os`, `$direnv`, `$status`, `$shell` modules
- Add `$fill` for right-alignment
- Use `right_format` for time or duration
- Remove `$golang`, `$php` (or keep disabled by default)
- Polish the color palette (fewer segments? or gradient refinement)
- Keep the decorative `░▒▓ ` intro
- Add `$line_break` between info and prompt character
- Include `$status` module (shows red exit code on failure)

**Pros**: Preserves existing aesthetic, more information-dense, adds modern Starship patterns
**Cons**: Can become noisy with too many modules, more complex format string, more scanning overhead
**Effort**: Medium (single file, but complex format restructuring)

---

#### 3. Minimal Functional

The sparsest possible prompt — just what you need, nothing more. Single-line, no decorations.

```
~/Dev/project  main                                          02:30 PM
$ _
```

**Format**: `$directory$git_branch$git_status$fill$time$line_break$character`

**Key changes**:
- Remove ALL language version modules (they show on demand when you open a file anyway)
- Remove decorative segment
- Remove cmd_duration (noise for fast commands)
- Single-line info with right-aligned time
- `$status` only on error (disabled by default, shows when non-zero)
- Clean dark/light palette, no powerline segments
- Remove `fish_prompt.fish` entirely (pure starship)

**Pros**: Fastest prompt (minimal scan overhead), cleanest visual, timeless
**Cons**: No language version visibility until you're in the file, no command duration, less personality
**Effort**: Low (simple format string change)

### Recommendation

**Approach 1: Clean Two-Line** is recommended.

Rationale:
- Two-line layout is the modern Starship standard (used in presets and the default `$all` expansion) — it separates _information_ from _interaction_
- A clean left-aligned info line with `$fill` pushing metadata right is both functional and visually balanced
- The current `░▒▓ ` decorative prefix is unique but adds noise — replacing it with `$os` is more functional (shows what system you're on) while retaining personality
- Language version modules should stay but only show when relevant (they already do — Starship is smart about that)
- `$php` and `$golang` are worth retaining silently (they only trigger when you `cd` into a PHP or Go project, which future-proofs you)
- The current color palette is cohesive — worth keeping but can be simplified (fewer segments = fewer bg colors needed)
- The `fish_prompt.fish` dead code should be cleaned up: either remove it and rely entirely on starship, or leave it as a minimal fallback

### Risks

- **Powerline segment removal**: The current prompt uses `` (powerline right-triangle) to create the segmented look. Removing segments means restructuring the color handling completely — each module no longer needs a `bg:` color that matches the previous module's `fg:`.
- **`fish_prompt.fish` removal**: If we remove or simplify the custom `fish_prompt.fish`, there's a brief window where a starship failure (e.g., broken config) produces no prompt. Keep a minimal fallback.
- **`$all` vs explicit format**: Switching from explicit module listing to `$all`-based approach could pull in unwanted modules (battery, aws, etc.) that add noise.
- **Nerd Font version**: Some newer icons require Nerd Font v3+. The current `` (git branch), `` (distro icon), `` (clock) are all v2-compatible. Adding `$os` modules uses more modern icons — verify terminal font supports them.
- **`right_format` support**: `right_format` is supported in Fish, but behavior varies across terminals. Test before committing.

### Ready for Proposal

**Yes**. The exploration is comprehensive. The orchestrator should move to `sdd-propose` with Approach 1 as the recommended direction, and let the user decide on:
1. Two-line vs single-line
2. Whether to keep the powerline segmented aesthetic
3. Whether to remove the `░▒▓ ` decorative start
4. Which language modules to keep
5. What to do with the dead `fish_prompt.fish`

## Exploration: windows-bootstrap-script

### Current State

The repo has a comprehensive interactive bootstrap script (`scripts/bootstrap.sh`) for Linux/macOS that handles 6 phases:
1. **Package install** via `brew bundle` (Brewfile)
2. **Git identity** via interactive prompts to `~/.gitconfig.local`
3. **Fish shell** via `chsh`
4. **SSH keys** — detect in `~/.ssh/`, cross-import from WSL (`/mnt/c/Users/`), or generate
5. **GitHub CLI** — `gh auth login`
6. **Remote** — change git remote from HTTPS to SSH

For Windows, the repo has:
- `run_once_before_install-packages.ps1.tmpl` — installs a subset of tools via winget
- `run_once_*.ps1` targets on Windows (`.chezmoiignore` filters the `.sh` variants)
- `.chezmoiignore` already configures OS filtering for fish configs (Linux-only), PowerShell configs (Windows-only), and run_once scripts

No interactive Windows bootstrap script exists yet. After `chezmoi init --apply` on Windows, the user has their config applied but no interactive setup analogous to `bootstrap.sh`.

### Affected Areas

- `scripts/bootstrap.ps1` — **new file**, the PowerShell 7 interactive bootstrap (this change's output)
- `run_once_before_install-packages.ps1.tmpl` — reference for current winget package list; identifies which Brewfile tools lack winget equivalents
- `Brewfile` — reference for the complete tool list; some tools have no winget equivalent and will be flagged in Phase 1
- `scripts/bootstrap.sh` — reference for all 6 phases; the PS1 script mirrors its structure
- `.chezmoiignore` — already correct, no changes needed; the `.ps1` variant in `scripts/` is not template-filtered (outside `.chezmoiignore` scope)
- `dot_gitconfig.local.tmpl` — reference for git identity path (`~/.gitconfig.local`); same target path on Windows
- `dot_config/starship.toml` — already used cross-platform (has Windows symbol configured)

### Package Inventory: Brewfile vs winget

| Tool | Brewfile | winget (current PS1) | Notes |
|------|----------|---------------------|-------|
| fish | ✅ | ❌ | WinGet ID: `JesseWeber.Fish` or manual install |
| starship | ✅ | ✅ `starship.starship` | |
| eza | ✅ | ✅ `eza-community.eza` | |
| bat | ✅ | ✅ `sharkdp.bat` | |
| fd | ✅ | ❌ | WinGet: `sharkdp.fd` |
| ripgrep | ✅ | ✅ `BurntSushi.ripgrep.MSVC` | |
| fzf | ✅ | ✅ `junegunn.fzf` | |
| zoxide | ✅ | ❌ | WinGet: `ajeetdsouza.zoxide` |
| atuin | ✅ | ❌ | WinGet: `atuin.atuin` |
| direnv | ✅ | ❌ | WinGet: not available; use `cargo install` or scoop |
| git-delta | ✅ | ✅ `dandavison.delta` | Brewfile name differs from winget |
| gh | ✅ | ❌ | WinGet: `GitHub.cli` |
| lazygit | ✅ | ❌ | WinGet: `JesseDuffield.lazygit` |
| uv | ✅ | ❌ | WinGet: `astral.uv` |
| fnm | ✅ | ❌ | WinGet: `Schniz.fnm` |
| zellij | ✅ | ❌ | WinGet: not available |

### Approaches

1. **Standalone `scripts/bootstrap.ps1` mirroring bootstrap.sh's structure**
   - Create a single PowerShell 7 script that mirrors all 6 phases with Windows-native equivalents
   - Pros: Clear one-to-one mapping, easy to maintain alongside the bash version, well-understood pattern
   - Cons: Some Brewfile tools have no winget equivalent (direnv, zellij) — script must warn about these
   - Effort: Medium

2. **Extend `run_once_before_install-packages.ps1.tmpl` and add a minimal bootstrap**
   - Pros: Uses existing chezmoi run_once mechanism for package install
   - Cons: run_once cannot be interactive (SSH, gh auth, git identity prompts); would need a separate script anyway for interactive phases
   - Effort: Low for package extension, but incomplete

3. **Single hybrid script that works both as run_once (non-interactive mode) and interactive bootstrap**
   - Pros: DRY, single PowerShell entry point
   - Cons: Overengineered; the bash version doesn't do this either; run_once_ files and bootstrap.sh are intentionally separate
   - Effort: High

**Recommendation**: Approach 1 — standalone `scripts/bootstrap.ps1` mirroring `bootstrap.sh`'s 6 phases. It keeps the architecture consistent (one entry point per platform, separate from run_once hooks) and is the lowest-risk path.

### Phase-by-Phase Porting Plan

#### Phase 1: Package Install (winget)
- Detect script directory via `$PSScriptRoot` (parent = repo root)
- Check if tools already installed (idempotency): `Get-Command fish, starship -ErrorAction SilentlyContinue`
- If missing, check `Get-Command winget -ErrorAction SilentlyContinue`
- Install via `winget install --id <id> --silent --accept-package-agreements` for each tool
- Winget requires **admin elevation** (`winget install` works without admin for per-user installs on Windows 10 1809+, but many packages still need admin). Script should detect with `.NET` check: `[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)` and warn if not elevated.
- **Tools missing from winget** (direnv, zellij): warn user and suggest alternatives (scoop, cargo install, manual download)

#### Phase 2: Git Identity
- Target: `$env:USERPROFILE\.gitconfig.local` (same path as bash version on Windows)
- Check with `Test-Path` and `Select-String` for `[user]` section
- Prompt with `Read-Host` for name, email, signing key
- Write via `Set-Content -Encoding UTF8` (or heredoc-style with `@"..."@`)

#### Phase 3: Fish Shell
- Check installed: `Get-Command fish -ErrorAction SilentlyContinue`
- If not found, offer to install via winget: `winget install --id JesseWeber.Fish --silent`
- On Windows, there's **no `chsh` equivalent**. Fish runs inside Windows Terminal, VS Code terminal, etc. Script should:
  - Detect if Windows Terminal is installed (`Get-Command wt -ErrorAction SilentlyContinue`)
  - Offer to add Fish as a Windows Terminal profile
  - Inform user how to set Fish as default in Windows Terminal settings
  - **Key decision**: Windows Terminal can have Fish as default profile; this is a GUI setting or can be done via `settings.json` modification, but that's fragile. Recommend just informing the user.

#### Phase 4: SSH Keys
- On Windows 10+ (build 1809+), OpenSSH Client is an optional feature. Check: `Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*'`
- If not installed, attempt to install: `Add-WindowsCapability -Online -Name 'OpenSSH.Client~~~~0.0.1.0'` (requires admin)
- Keys live in `$env:USERPROFILE\.ssh\`
- Detect private keys: `Get-ChildItem "$env:USERPROFILE\.ssh\*" | Where-Object { $_.Name -notmatch '\.pub$|known_hosts|authorized_keys|config|environment' }`
- On Windows, the `ssh-keygen` command is from the Windows OpenSSH port — same syntax: `ssh-keygen -t ed25519 -C "$email"`
- `ssh-agent` on Windows is a Windows Service (`Get-Service ssh-agent`), not typically started manually via `eval $(ssh-agent -s)`. Script should `Set-Service ssh-agent -StartupType Automatic; Start-Service ssh-agent`
- `ssh-add` works the same
- **No WSL cross-import needed** — we ARE on Windows natively. Remove that entire branch.
- `gh ssh-key add` works the same

#### Phase 5: GitHub CLI
- Install via winget if missing (add to Phase 1 list)
- `gh auth login` works identically on Windows (opens browser-based device auth flow)
- Check with `gh auth status`

#### Phase 6: Remote HTTPS → SSH
- Same as bash: `git remote set-url origin git@github.com:Row0902/dotfiles.git`
- `git` is installed via winget in Phase 1 (Git.Git)
- `Get-Location` pattern to find repo root (or use `$PSScriptRoot/..`)

### Windows/PowerShell 7 Specifics

| Feature | Bash (bootstrap.sh) | PowerShell (bootstrap.ps1) |
|---------|---------------------|---------------------------|
| Directory detection | `dirname "${BASH_SOURCE[0]}"` | `$PSScriptRoot` (built-in) |
| Color output | ANSI escape codes | `$PSStyle` (PS7.2+) or `Write-Host -ForegroundColor` |
| Command existence | `command -v` | `Get-Command ... -ErrorAction SilentlyContinue` |
| File existence | `-f` / `test -f` | `Test-Path` |
| File read/check | `grep -q` | `Select-String -Quiet` |
| Path separator | `/` | `\` (use `Join-Path`) |
| Home directory | `$HOME` | `$env:USERPROFILE` (`$HOME` also works) |
| User prompt | `read -rp` | `Read-Host` |
| Admin check | `[ -w / ]` (crude) | `[Security.Principal.WindowsPrincipal]::new(...)` |
| Shell change | `chsh -s` | Not available — inform user for Windows Terminal config |
| SSH agent | `eval $(ssh-agent -s)` | `Start-Service ssh-agent` (Windows service) |
| Package manager | `brew` | `winget` |
| heredoc write | `cat > file <<-EOF` | `@"..."@` or `Set-Content` |

### PS7 Features Worth Using

- **`$PSStyle`** (PS7.2+): `$PSStyle.Foreground.BrightCyan` for info, BrightGreen for OK, BrightYellow for warn, BrightRed for error
- **`Write-Progress`**: Progress bar for each phase: `Write-Progress -Activity "Bootstrap" -CurrentOperation "Phase 1: Installing packages" -PercentComplete 16`
- **`Get-Command`** for idempotency checks instead of testing file paths
- **`Test-Path`** with `-PathType Leaf` for file checks
- **`Join-Path`** for safe cross-platform path building
- **`Select-String -Quiet`** for content matching (like `grep -q`)
- **`@"..."@`** here-strings for multi-line file writes

### Risks

1. **Admin elevation**: `winget install` and `Add-WindowsCapability` (OpenSSH client) may need admin rights. The script cannot self-elevate reliably in all terminal configurations. Should check and warn, not require.
2. **Missing winget equivalents**: `direnv`, `zellij` have no winget packages. `fnm`, `lazygit`, `uv`, `fd`, `zoxide`, `atuin`, `gh` need winget IDs added to the install list. The current PS1 template is missing many Brewfile entries.
3. **Fish shell on Windows**: Fish on Windows has some quirks (path handling, symlinks). `chsh` doesn't exist — the script can't automatically set Fish as default shell. Windows Terminal profile configuration is the right approach but fragile to automate via `settings.json` manipulation.
4. **$PSStyle availability**: `$PSStyle` is PS7.2+. PS5.1 is still the default on many Windows installs. The script targets PS7 (which is in the winget package list), but need graceful fallback if run on PS5.1.
5. **ssh-agent service**: The Windows OpenSSH service may not be installed or running. Must check and offer to configure it.
6. **No test coverage**: No tests in this repo. Manual testing on a Windows machine is required.

### Ready for Proposal

**Yes** — the exploration is thorough enough to proceed. The change is well-scoped: a single new file (`scripts/bootstrap.ps1`) that mirrors the existing 6-phase bash bootstrap with Windows-native equivalents. The key decisions to resolve in the proposal:

1. Complete winget package list — which Brewfile tools to include vs warn about
2. Admin elevation strategy — require, warn, or attempt self-elevation
3. Fish shell setup approach — just inform or attempt Windows Terminal profile config
4. PS5.1 vs PS7 — minimum PowerShell version requirement
5. SSH agent service handling — auto-configure or inform

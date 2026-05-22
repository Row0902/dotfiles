# Design: Windows Bootstrap Script

## Technical Approach

Single `scripts/bootstrap.ps1` (PowerShell 7) mirroring `bootstrap.sh`'s 6-phase structure with Windows-native equivalents. Uses Scoop for package management (covers all tools including atuin, direnv, zellij), `Get-Command` for idempotency checks, and `Read-Host` for interactive prompts. Per-user, no admin required — Scoop installs to `$env:USERPROFILE\scoop\`.

Phases: (1) Scoop + tools, (2) Git identity, (3) Fish shell, (4) SSH keys + agent, (5) gh auth, (6) remote HTTPS→SSH.

## Architecture Decisions

| Decision | Option A | Option B | Tradeoff | Choice | Rationale |
|----------|----------|----------|----------|--------|-----------|
| Package manager | winget (built-in) | Scoop (manual bootstrap) | winget: no bootstrap but gaps (direnv, zellij). Scoop: needs install step but covers all 16 tools | **Scoop** | Complete tool coverage per proposal; per-user, no admin |
| Color output | `$PSStyle` (PS7.2+) | `Write-Host -ForegroundColor` | `$PSStyle` is elegant but PS5.1-incompatible. `Write-Host` works on PS5.1+ | **Write-Host -ForegroundColor** | PS5.1 compatibility; graceful for users who haven't upgraded yet |
| Admin elevation | Require admin | Warn and continue | Requiring admin adds friction. Scoop is per-user, no elevation needed | **Warn and continue** | Scoop = per-user; ssh-agent service config may need admin but script can warn |
| Path building | String interpolation (`"$HOME/.ssh"`) | `Join-Path` | Interpolation fragile with Windows backslashes | **Join-Path** | Platform-safe, handles separators correctly |
| SSH agent | `eval $(ssh-agent -s)` (Linux) | `Set-Service` / `Start-Service` (Windows) | eval pattern is Linux-only; Windows OpenSSH runs as OS service | **Set-Service + Start-Service** | Windows-native; `Get-Service ssh-agent`, `Set-Service -StartupType Automatic`, `Start-Service ssh-agent` |
| Script location | `$MyInvocation` | `$PSScriptRoot` | `$MyInvocation` is verbose and source-dependent | **$PSScriptRoot** | Built-in, works in all PS versions, returns script's directory |

## Function Structure

```
bootstrap.ps1
├── Output Helpers
│   ├── Write-BootstrapInfo    (cyan arrow, no newline to match bash info())
│   ├── Write-BootstrapOk      (green checkmark)
│   ├── Write-BootstrapWarn    (yellow warning)
│   └── Write-BootstrapError   (red cross)
├── Phase Functions (one per phase)
│   ├── Install-ScoopAndTools  (scoop bootstrap + bucket + loop-install 16 packages)
│   ├── Set-GitIdentity        (Read-Host → $env:USERPROFILE\.gitconfig.local)
│   ├── Install-FishShell      (scoop install fish → inform re: Windows Terminal)
│   ├── Setup-SSHKeys          (detect/generate → enable ssh-agent service)
│   ├── Setup-GitHubAuth       (gh auth login if not authed)
│   └── Convert-ToSshRemote    (git remote set-url)
└── Main (banner → call each phase sequentially)
```

## Idiom Mapping: bash → PowerShell

| bash | PowerShell | Notes |
|------|------------|-------|
| `command -v scoop` | `Get-Command "scoop" -ErrorAction SilentlyContinue` | Returns `$null` if missing |
| `test -f "$FILE"` | `Test-Path $file -PathType Leaf` | Explicit type check |
| `grep -q "\[user\]"` | `Select-String -Path $file -Pattern '\[user\]' -Quiet` | `$true`/`$false` |
| `cat > file <<-EOF` | `@"... "@ \| Set-Content` or `Set-Content` | Here-string for multi-line |
| `$HOME` | `$env:USERPROFILE` | More Windows-native; `$HOME` also works but `USERPROFILE` is the canonical env var |
| `eval $(ssh-agent -s)` | `Start-Service ssh-agent` | Windows OpenSSH agent is an OS service |
| `read -rp "prompt" var` | `Read-Host "prompt"` | Simpler — single prompt, returns string |
| `chsh -s fish` | N/A | Windows has no `chsh`; inform user to configure Windows Terminal |

## Data Flow

```
User Input (Read-Host)
  │
  ├── Phase 2 → name, email, gpg_key → [user] section → $env:USERPROFILE\.gitconfig.local
  ├── Phase 4 → email → ssh-keygen -t ed25519 → $env:USERPROFILE\.ssh\id_ed25519
  │           → Start-Service ssh-agent → ssh-add
  └── Phases 5-6 → authenticated by gh, used by git remote set-url

Package State (Get-Command checks)
  │
  ├── Phase 1 → scoop → buckets (extras) → 16 packages loop
  │           → Get-Command each tool → skip if present
  ├── Phase 3 → Get-Command fish → skip or scoop install
  └── Phase 5 → Get-Command gh → skip or scoop install

Git Remote
  │
  └── Phase 6 → git remote get-url origin → if https:// → set-url git@github.com:Row0902/dotfiles.git
```

## Error Handling Strategy

- **Non-critical phases**: Continue on failure with warning (`Write-BootstrapWarn`). Applies to: Fish install (Phase 3), gh auth (Phase 5), remote conversion (Phase 6).
- **Critical phases**: Exit with error on failure (`exit 1`). Applies to: Scoop install (Phase 1 bootstrap), ssh-agent service start (Phase 4).
- **Idempotency**: Every phase checks preconditions with `Get-Command` or `Test-Path` before acting. Safe to re-run entire script.
- **Admin elevation**: `Test-AdminElevation` function at script start. If not admin, warn about ssh-agent service config (Phase 4) but continue — user can configure manually later.
- **Scoop bootstrap failure**: If PowerShell execution policy blocks `Invoke-RestMethod`, inform user to run `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` first.

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `scripts/bootstrap.ps1` | **Create** | 6-phase interactive Windows bootstrap (this change's output) |
| `README.md` | Modify | Add Windows bootstrap instructions (note: `pwsh scripts/bootstrap.ps1`) |

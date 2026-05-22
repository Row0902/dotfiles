# Tasks: Windows Bootstrap Script

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 280–340 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | single-pr |
| Chain strategy | size-exception |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: size-exception
400-line budget risk: Low

## Phase 1: Script Foundation — Output Helpers & Main Skeleton

- [x] 1.1 Create `scripts/bootstrap.ps1` with banner, `Test-AdminElevation`, and 4 output helpers: `Write-BootstrapInfo`, `Write-BootstrapOk`, `Write-BootstrapWarn`, `Write-BootstrapError`
- [x] 1.2 Add main function skeleton calling all 6 phases sequentially with error handling (non-critical phases continue on warn, critical phases exit)

## Phase 2: Script Core — Six Phase Functions

- [x] 2.1 Add `Install-ScoopAndTools`: bootstrap Scoop if missing, add `extras` bucket, loop-install all 16 tools (`Get-Command` check per tool, skip if present)
- [x] 2.2 Add `Set-GitIdentity`: `Test-Path` + `Select-String` check on `$env:USERPROFILE\.gitconfig.local`, `Read-Host` prompts for name/email/signingkey, write `[user]` section with `Set-Content`
- [x] 2.3 Add `Install-FishShell`: `Get-Command` check, scoop install fish if missing, write `Write-BootstrapInfo` about Windows Terminal config
- [x] 2.4 Add `Setup-SSHKeys`: detect existing keys in `.ssh\`, offer reuse; if none, prompt to generate ed25519; `Set-Service` + `Start-Service` for ssh-agent; `ssh-add` the key
- [x] 2.5 Add `Setup-GitHubAuth`: `Get-Command gh` → scoop install if missing; `gh auth status` → `gh auth login` if not authed
- [x] 2.6 Add `Convert-ToSshRemote`: `git remote get-url origin` → if HTTPS, `git remote set-url` to `git@github.com:Row0902/dotfiles.git`

## Phase 3: Config & Documentation

- [x] 3.1 Update `.chezmoiignore` — ensure `run_once_*.ps1` and `scripts/bootstrap.ps1` are not excluded on Windows (verified: already correct — no changes needed)
- [x] 3.2 Update `README.md` — add Windows prerequisites (PowerShell 7 install), Windows bootstrap command (`pwsh scripts/bootstrap.ps1`), and Windows-specific notes table

## Dependencies

```
Phase 1 (helpers + skeleton) → Phase 2 (6 functions) → Phase 3 (config/docs)
```

All Phase 2 tasks are independent of each other — each function is self-contained. Phase 3 tasks are independent of each other but depend on the script existing.

## Acceptance Criteria

| Task | Acceptance |
|------|------------|
| 1.1–1.2 | Script runs without errors and shows banner + admin warning |
| 2.1 | Scoop installs on first run, skips on re-run; all 16 tools installed |
| 2.2 | `.gitconfig.local` created with user input; skips if `[user]` section exists |
| 2.3 | Fish skipped if present, installed if missing; user sees Windows Terminal info |
| 2.4 | Existing keys detected; new keys generated on request; ssh-agent service enabled + started |
| 2.5 | `gh` installed if missing; auth skipped if already authed |
| 2.6 | Remote URL changed from HTTPS→SSH if applicable; skipped if already SSH |
| 3.1 | `chezmoi apply` on Windows includes `scripts/bootstrap.ps1` |
| 3.2 | Windows user can follow README to bootstrap from scratch |

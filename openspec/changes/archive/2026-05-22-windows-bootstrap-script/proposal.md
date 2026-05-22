# Proposal: Windows Bootstrap Script

## Intent

Port `scripts/bootstrap.sh` to Windows PowerShell 7 as `scripts/bootstrap.ps1` using Scoop as package manager. Provides Windows users the same interactive onboarding (tool install, git identity, SSH, gh auth) as the existing Linux/macOS bootstrap.

## Scope

### In Scope
- `scripts/bootstrap.ps1` — 6-phase PS7 script mirroring `bootstrap.sh`
- Scoop-based package install — covers all Brewfile tools (direnv, zellij, atuin — no winget gaps)
- Git identity prompt → `$env:USERPROFILE\.gitconfig.local`
- Fish install via Scoop + inform user re: Windows Terminal config
- SSH key detect, enable ssh-agent Windows service, generate if missing
- `gh auth login` + remote HTTPS→SSH conversion
- Idempotent — safe to rerun

### Out of Scope
- Setting Fish as default shell (no `chsh` on Windows)
- WSL SSH key import (running natively)
- Windows Terminal `settings.json` automation
- Admin elevation enforcement (Scoop is per-user)
- Full PS5.1 support — target PS7, only `Write-Host -ForegroundColor` for color compat

## Capabilities

### New Capabilities
- `windows-bootstrap`: Interactive Windows bootstrap covering package install, git identity, shell setup, SSH config, gh auth, remote URL conversion.

### Modified Capabilities
None — no existing specs in `openspec/specs/`.

## Approach

Single `scripts/bootstrap.ps1` mapping the 6 bash phases to Windows-native equivalents. Scoop installs per-user to `$env:USERPROFILE\scoop\` — no admin, covers all tools. Uses `$PSScriptRoot` for repo path, `Get-Command` for idempotency, `Read-Host` for prompts, `Write-Host -ForegroundColor` for colored output. Phase mapping:

| Phase | bash | PS7 (Scoop) |
|-------|------|-------------|
| 1 | brew bundle → Brewfile | scoop install via bucket/loop |
| 2 | Git identity → `~/.gitconfig.local` | Same via `Read-Host`, write to `$env:USERPROFILE` |
| 3 | `chsh -s fish` | Install fish via scoop, inform re: Windows Terminal |
| 4 | SSH detect/generate, `eval $(ssh-agent)` | Detect in `.ssh\`, enable ssh-agent service, generate |
| 5 | `gh auth login` | Identical |
| 6 | remote HTTPS→SSH | Identical |

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `scripts/bootstrap.ps1` | New | Windows PS7 interactive bootstrap |
| `.chezmoiignore` | Check | Ensure `.ps1` not ignored |
| `README.md` | Modified | Add Windows onboarding instructions |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Fish can't be default shell on Windows | High | Inform user to configure Windows Terminal manually |
| Scoop not installed | Medium | Script installs Scoop if missing |
| ssh-agent service absent | Low | Check & configure via `Get-Service`/`Set-Service` |
| User on PS5.1 (no `$PSStyle`) | Medium | Use `Write-Host -ForegroundColor` — works on both |

## Rollback Plan

- `git checkout` README.md
- Delete `scripts/bootstrap.ps1`
- Scoop uninstall: `scoop uninstall <app>` per tool
- `git checkout` .chezmoiignore if modified

## Dependencies

- PowerShell 7 (`winget install Microsoft.PowerShell`)
- Scoop (installed by script if missing)

## Success Criteria

- [ ] `scripts/bootstrap.ps1` runs end-to-end on clean Windows with Scoop
- [ ] All 6 phases complete with correct Windows equivalents
- [ ] Idempotent: re-run skips completed phases without errors
- [ ] README updated with Windows bootstrap instructions

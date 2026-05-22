# Cross-Platform Automation — Spec

## Domain: package-installation

### Requirement: OS-aware package install (MUST)

On first `chezmoi apply`, the system MUST install packages per OS using `run_once_before_install-packages` scripts.

#### Scenario: macOS brew install
- GIVEN a fresh macOS machine with Homebrew present
- WHEN `chezmoi apply` runs
- THEN `run_once_before_install-packages.sh` installs Brewfile packages
- AND the script does not execute on subsequent applies

#### Scenario: Linux brew install
- GIVEN a fresh Linux machine with Homebrew present
- WHEN `chezmoi apply` runs
- THEN `run_once_before_install-packages.sh` installs Brewfile packages

#### Scenario: Windows winget install
- GIVEN a fresh Windows machine with winget present
- WHEN `chezmoi apply` runs
- THEN `run_once_before_install-packages.ps1` installs equivalent packages

#### Scenario: Missing package manager
- GIVEN a machine without brew or winget
- WHEN the install script runs
- THEN it MUST log a warning and exit 0 without failing `chezmoi apply`

### Requirement: OS script filtering (MUST)

The system MUST expose only the OS-appropriate install script via `.chezmoiignore`.

#### Scenario: Unix hides PowerShell
- GIVEN `chezmoi apply` on Linux or macOS
- THEN `.ps1` scripts MUST be ignored

#### Scenario: Windows hides shell scripts
- GIVEN `chezmoi apply` on Windows
- THEN `.sh` scripts MUST be ignored

---

## Domain: binary-download

### Requirement: External binary auto-download (MUST)

`.chezmoiexternal.toml` MUST download delta and starship binaries matching `{{ .chezmoi.os }}_{{ .chezmoi.arch }}`.

#### Scenario: Linux amd64 download
- GIVEN `chezmoi apply` on Linux amd64
- THEN delta and starship binaries download to the configured path

#### Scenario: macOS arm64 download
- GIVEN `chezmoi apply` on macOS arm64
- THEN correct arm64 binaries download

#### Scenario: Network failure
- GIVEN a network error during download
- WHEN chezmoi fetches the external
- THEN chezmoi MUST abort with non-zero status and leave no partial binary

### Requirement: Refresh control (SHOULD)

Externals SHOULD use `refreshPeriod: 168h` to limit refetching.

---

## Domain: provisioning-automation

### Requirement: Headless first-apply provisioning (MUST)

Phase 1 (brew bundle) MUST move from `bootstrap.sh` to `run_once_before_install-packages`.

#### Scenario: Fresh machine headless provision
- GIVEN a new machine
- WHEN `chezmoi apply` runs
- THEN packages and binaries install without user interaction

#### Scenario: bootstrap.sh interactive fallback
- GIVEN `scripts/bootstrap.sh` is run manually after `run_once_` completed
- WHEN it reaches Phase 1
- THEN it MUST skip brew bundle and continue to SSH/gh auth/chsh

#### Scenario: bootstrap.sh run before apply
- GIVEN bootstrap.sh runs before any `chezmoi apply`
- WHEN it reaches Phase 1
- THEN it MAY still run brew bundle as a fallback

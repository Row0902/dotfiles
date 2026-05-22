# Windows Bootstrap Specification

## Purpose

Define the PowerShell 7 bootstrap script (`scripts/bootstrap.ps1`) that mirrors `bootstrap.sh` for tool install, Git identity, shell setup, SSH, gh auth, and remote conversion.

## Requirements

| ID | Requirement | Priority |
|---|---|---|
| R1 | Install Scoop if not present. | MUST |
| R2 | Install required tools via Scoop when missing. | MUST |
| R3 | Prompt for Git identity and create `~/.gitconfig.local` when missing or without `[user]`. | MUST |
| R4 | Install Fish via Scoop and inform user about Windows Terminal config. | SHOULD |
| R5 | Detect existing SSH keys, offer generation if absent, and enable ssh-agent service. | MUST |
| R6 | Ensure `gh` CLI is installed and authenticated. | SHOULD |
| R7 | Convert repository remote from HTTPS to SSH when SSH keys are available. | MUST |
| R8 | Detect non-admin execution and warn for operations requiring elevation. | SHOULD |

## Scenarios

### R1 — Scoop Installation

#### Scenario: Scoop not installed
- GIVEN Scoop is not present
- WHEN Phase 1 runs
- THEN it installs Scoop via the official script

#### Scenario: Scoop already installed
- GIVEN Scoop is already installed
- WHEN Phase 1 runs
- THEN it skips installation

#### Scenario: Admin check
- GIVEN the script runs without admin privileges
- WHEN it reaches elevation-requiring operations
- THEN it warns and continues

### R2 — Tool Installation

#### Scenario: Tool missing
- GIVEN a required tool is missing
- WHEN Phase 1 runs
- THEN it installs the tool via Scoop

#### Scenario: Tool already installed
- GIVEN a required tool is installed
- WHEN Phase 1 runs
- THEN it skips that tool

### R3 — Git Identity

#### Scenario: Git config missing
- GIVEN `~/.gitconfig.local` does not exist
- WHEN Phase 2 runs
- THEN it prompts for name, email, and optional GPG key
- AND writes the responses to `~/.gitconfig.local`

#### Scenario: Git config already populated
- GIVEN `~/.gitconfig.local` has a `[user]` section
- WHEN Phase 2 runs
- THEN it skips the prompt

### R4 — Fish Shell

#### Scenario: Fish not installed
- GIVEN Fish is not installed
- WHEN Phase 3 runs
- THEN it installs Fish via Scoop
- AND informs the user about Windows Terminal configuration

#### Scenario: Fish already installed
- GIVEN Fish is installed
- WHEN Phase 3 runs
- THEN it skips installation and reminds about Windows Terminal config

### R5 — SSH Keys

#### Scenario: Existing SSH keys found
- GIVEN private SSH keys exist in `~/.ssh/`
- WHEN Phase 4 runs
- THEN it lists the keys and offers to use them

#### Scenario: No SSH keys found
- GIVEN no private SSH keys exist in `~/.ssh/`
- WHEN Phase 4 runs
- THEN it prompts to generate an ed25519 key
- AND starts ssh-agent and adds the key

#### Scenario: ssh-agent service not running
- GIVEN the ssh-agent service is disabled or stopped
- WHEN Phase 4 runs
- THEN it sets startup to Automatic and starts the service

### R6 — GitHub CLI Auth

#### Scenario: gh not installed
- GIVEN `gh` is not installed
- WHEN Phase 5 runs
- THEN it installs `gh` via Scoop

#### Scenario: gh not authenticated
- GIVEN `gh` is installed but not authenticated
- WHEN Phase 5 runs
- THEN it runs `gh auth login`

#### Scenario: gh already authenticated
- GIVEN `gh` is authenticated
- WHEN Phase 5 runs
- THEN it skips authentication

### R7 — Remote URL

#### Scenario: Remote is HTTPS
- GIVEN the origin remote uses HTTPS
- WHEN Phase 6 runs
- THEN it changes the URL to SSH

#### Scenario: Remote already SSH
- GIVEN the origin remote uses SSH
- WHEN Phase 6 runs
- THEN it skips conversion

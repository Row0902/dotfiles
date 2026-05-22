# Config Foundation — Specifications

## Domain: chezmoi-config

### ADDED Requirements

| ID | Requirement | Priority |
|---|---|---|
| CFG-01 | `~/.config/chezmoi/chezmoi.toml` **MUST** set `git.autoAdd = true` | MUST |
| CFG-02 | It **MUST** set `git.autoCommit = true` with `commitMessageTemplate = "chore: sync dotfiles"` | MUST |
| CFG-03 | It **MUST** set `git.autoPush = false` | MUST |
| CFG-04 | It **MUST** set `diff.pager = "delta"` | MUST |
| CFG-05 | It **MUST** set `merge.command = "vimdiff"` and `merge.args` with template placeholders | MUST |
| CFG-06 | It **SHOULD** declare `interpreters.ps1` selecting `pwsh` or `powershell` | SHOULD |

#### Scenario: Auto-commit on add
- GIVEN a tracked dotfile is modified
- WHEN `chezmoi add <file>` runs
- THEN chezmoi stages and commits with the template message

#### Scenario: No auto-push
- GIVEN `git.autoPush = false`
- WHEN a chezmoi auto-commit is created
- THEN the commit stays local

#### Scenario: Delta diff
- GIVEN `diff.pager = "delta"`
- WHEN `chezmoi diff` runs
- THEN output is piped through delta

#### Scenario: Vimdiff merge
- GIVEN `merge.command = "vimdiff"`
- WHEN `chezmoi merge` runs on a conflict
- THEN vimdiff opens with Destination, Source, and Target

#### Scenario: Windows interpreter fallback
- GIVEN the OS is Windows and `pwsh` is unavailable
- WHEN a `.ps1` script runs via chezmoi
- THEN it falls back to `powershell`

---

## Domain: chezmoi-data

### ADDED Requirements

| ID | Requirement | Priority |
|---|---|---|
| DAT-01 | `.chezmoidata.toml` **MUST** expose `brew.prefix_darwin` and `brew.prefix_linux` | MUST |
| DAT-02 | It **MUST** expose `editor.command`, `editor.diff`, `git.default_branch`, and `os.config_dir` | MUST |
| DAT-03 | It **MUST NOT** contain secrets or credentials | MUST |

#### Scenario: Darwin brew prefix
- GIVEN `{{ .brew.prefix_darwin }}` is used in a template
- WHEN rendered on macOS
- THEN it resolves to `/opt/homebrew`

#### Scenario: Linux brew prefix
- GIVEN `{{ .brew.prefix_linux }}` is used in a template
- WHEN rendered on Linux
- THEN it resolves to `/home/linuxbrew/.linuxbrew`

#### Scenario: Public data only
- GIVEN `.chezmoidata.toml` is committed
- WHEN inspected
- THEN no sensitive values are present

---

## Domain: chezmoi-templates

### ADDED Requirements

| ID | Requirement | Priority |
|---|---|---|
| TPL-01 | `.chezmoitemplates/brew-path.tmpl` **MUST** return `/opt/homebrew` for `darwin` and `/home/linuxbrew/.linuxbrew` for `linux` | MUST |
| TPL-02 | `.chezmoitemplates/git-identity.tmpl` **MUST** emit a `[user]` section from `.chezmoidata` or prompt fallback | MUST |
| TPL-03 | `.chezmoitemplates/os-path.tmpl` **MUST** resolve base paths per OS (`~/.config` on Unix) | MUST |

#### Scenario: Brew path partial on Darwin
- GIVEN `{{ template "brew-path" . }}` is invoked
- WHEN `.chezmoi.os` is `darwin`
- THEN output is `/opt/homebrew`

#### Scenario: Brew path partial on Linux
- GIVEN `{{ template "brew-path" . }}` is invoked
- WHEN `.chezmoi.os` is `linux`
- THEN output is `/home/linuxbrew/.linuxbrew`

#### Scenario: Brew path partial on Windows
- GIVEN `{{ template "brew-path" . }}` is invoked
- WHEN `.chezmoi.os` is `windows`
- THEN output is empty string (no Homebrew)

#### Scenario: Git identity from data
- GIVEN `.chezmoidata` contains `git.user_name` and `git.user_email`
- WHEN `{{ template "git-identity" . }}` is rendered
- THEN it emits `name = {value}` and `email = {value}`

#### Scenario: OS path on Unix
- GIVEN `.chezmoi.os` is `linux` or `darwin`
- WHEN `{{ template "os-path" . }}` is rendered
- THEN output resolves to `$HOME/.config`

---

## Edge Cases

| Case | Handling |
|---|---|
| vimdiff not installed | `chezmoi merge` fails gracefully with OS error; user can override config locally |
| delta not installed | `chezmoi diff` falls back to plain diff (delta exits non-zero but chezmoi continues) |
| chezmoi.toml outside source dir | Managed via `chezmoi add ~/.config/chezmoi/chezmoi.toml`; chezmoi tracks it normally |
| `.chezmoidata.toml` missing key | Template renders empty string; partials **SHOULD** provide sensible defaults |
| Partial invoked without `.` context | Template engine raises clear error; no silent misrender |
| autoCommit on non-Git source dir | chezmoi ignores silently; no crash |

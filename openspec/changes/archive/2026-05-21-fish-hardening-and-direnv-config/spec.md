# Spec: Fish Config Hardening and Direnv Improvements

## Requirements

### F1: Safe Shell Startup
Every conf.d file MUST load without errors on every shell startup,
regardless of which tools are installed.

- F1.1: All `source` calls MUST be guarded with `test -f`
- F1.2: All variable references MUST use `$` prefix
- F1.3: All `set` commands must include the `set` keyword
- F1.4: No conf.d file may call `source ~/.config/fish/config.fish`

### F2: Graceful Tool Absence
When a tool is not installed, the shell MUST NOT show errors.

- F2.1: All external tool calls in functions MUST be guarded
  with `type -q` or `command -q`
- F2.2: All abbr/alias definitions for tools MUST be inside
  `type -q` guard blocks
- F2.3: Functions MUST display helpful error messages when
  required tools are missing

### F3: Fish Best Practices
- F3.1: Use `abbr` for interactive shortcuts (`oc`, `dv`)
- F3.2: Use `alias` for command replacements (`ls`, `cat`)
- F3.3: PATH manipulation should check for duplicates

### F4: Direnv Integration
- F4.1: Loading/unloading announcements MUST be suppressed
- F4.2: Errors (blocked .envrc, syntax errors) MUST still be visible
- F4.3: VIRTUAL_ENV MUST be exported via PATH_add (not source activate)
- F4.4: .envrc MUST support secret files via source_env_if_exists
- F4.5: strict_env MUST be enabled for safer .envrc execution

### F5: Productivity Tools
- F5.1: fzf keybindings (ctrl+T, alt+C) MUST work when fzf is installed
- F5.2: fzf MUST NOT override atuin's ctrl+R
- F5.3: gh abbreviations MUST be available when gh is installed

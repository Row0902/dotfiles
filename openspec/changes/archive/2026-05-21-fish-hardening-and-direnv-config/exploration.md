# Exploration: Fish config safety hardening and direnv improvements

## Trigger

User requested audit of Fish conf.d and functions for best practices
around tool availability validation. Also wanted to improve direnv
integration (silence loading announcements, add layout functions).

## Investigated

### Fish conf.d safety audit
- Each conf.d file read and analyzed for: missing tool guards,
  unsafe `source`, eval patterns, PATH manipulation safety
- Functions reviewed for guard patterns and error handling
- Compared against Fish shell documentation best practices

### Direnv features
- Researched `log_format`, `log_filter`, `hide_env_diff` config options
- Reviewed direnv source code (log.go) to confirm error vs status
  message separation
- Investigated builtin layout functions and `source_env_if_exists`
- Researched best practices for Python virtualenv + direnv integration

## Findings

### CRITICAL: 3 bugs that break shell startup
1. bat.fish: missing `set` keyword causes parse error
2. starship.fish: missing `$` in `test -n STARSHIP_PATH` (always true)
3. rustup.fish: unguarded `source` fails if Rust not installed

### SAFETY: Multiple best-practice violations
- system.fish: `abbr .fish` sourcing config.fish (double-load anti-pattern)
- opencode.fish, direnv.fish: `alias` instead of `abbr`
- fish_title.fish: unguarded `git` calls
- edit.fish: \$EDITOR not split into list (breaks with arguments)
- extract.fish: no per-tool guards

### DIRENV: Loading announcements redundant
- Starship already shows direnv status via \$direnv module
- `log_format = "-"` suppresses status but NOT errors (confirmed in source)
- Builtin layout functions can replace custom activate scripts
- `source_env_if_exists .envrc.private` enables local secrets
- `strict_env = true` adds set -euo pipefail safety

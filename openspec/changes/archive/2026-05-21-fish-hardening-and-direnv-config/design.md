# Design: Fish Config Hardening and Direnv Improvements

## Architecture

### Fish conf.d Pattern
Each conf.d file follows this structure:

```
set -l brew_path "/home/linuxbrew/.linuxbrew/bin"

if test -d "$brew_path"
    set -gx TOOL_PATH "$brew_path"
else if type -q tool
    set -gx TOOL_PATH ""
end

if set -q TOOL_PATH
    if test -n "$TOOL_PATH"
        if not contains "$TOOL_PATH" $PATH
            set -gx PATH "$TOOL_PATH" $PATH
        end
    end

    # Tool-specific config (abbr, source, etc.)
end
```

### Function Guard Pattern
```
function foo --description "Does something"
    if not type -q required_tool
        echo "Error: required_tool no está instalado."
        return 1
    end

    required_tool "$argv"
end
```

### Command Replacement vs Shortcut

| Pattern | Use Case | Files |
|---------|----------|-------|
| `alias x='y --flags'` | Replace standard command silently | eza.fish (ls→eza), bat.fish (cat→bat) |
| `abbr -g x y` | Expand shortcut at type-time | opencode.fish (oc→opencode), git.fish (gst→git status) |

### Direnv Architecture

```
direnv.toml                → global config (log_format, strict_env)
direnvrc                   → custom layout functions (layout_uv, etc.)
direnv.fish                → direnv hook init + abbreviations
.project/.envrc            → per-project: layout uv + source_env_if_exists + watch_file
.project/.envrc.private    → per-machine secrets (not versioned)
```

### Log Suppression Logic (direnv source-confirmed)

```
logError()  → always logs (errors always visible)
logStatus() → checks log_format:
               - format=""  → suppressed (our config: "-" → "")
               - format!="" → logged with format
```

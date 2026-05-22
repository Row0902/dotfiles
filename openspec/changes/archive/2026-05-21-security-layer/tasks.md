# Security Layer — Tasks

## Phase 1: Encryption Setup

### 1.1 Generate age key
`chezmoi age-keygen --output=~/.config/chezmoi/key.txt`

### 1.2 Update chezmoi.toml — add encryption section
Modificar `dot_config/chezmoi/chezmoi.toml`:
```toml
encryption = "age"
[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "<public-key>"
```

## Phase 2: Modify Template

### 2.1 Create `modify_dot_gitconfig.local`
Archivo en raíz del source dir que modifica `~/.gitconfig.local`.

## Review Workload
- Estimated lines: ~30
- Budget risk: **Low**
- Single PR: ✅

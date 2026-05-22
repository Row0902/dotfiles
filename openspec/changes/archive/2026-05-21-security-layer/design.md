# Security Layer — Design

## Architecture Decisions

### AD-01: Asymmetric age key (not symmetric)
- Elegido: asymmetric con X25519 key dedicada
- Motivo: `useBuiltinAge` no soporta symmetric. Builtin es más portable.

### AD-02: Key location
- Elegido: `~/.config/chezmoi/key.txt`
- Motivo: chezmoi resuelve `~` por OS (forward slashes siempre)

### AD-03: modify template approach
- Elegido: `modify_` prefix sin `.tmpl` extension
- Motivo: chezmoi reconoce modify templates por el prefijo, no por extensión

## File Specifications

### 1. `chezmoi.toml` — agregar encryption section
```toml
encryption = "age"
[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1..."  # se obtiene de chezmoi age-keygen
```

### 2. `modify_dot_gitconfig.local` (NUEVO)
```
{{- /* chezmoi:modify-template */ -}}
{{- $data := fromIni .chezmoi.stdin -}}
{{- $user := $data.user | default dict -}}
{{- $_ := set $user "name" (promptStringOnce . "git_user_name" "Your full name") -}}
{{- $_ := set $user "email" (promptStringOnce . "git_user_email" "Your email") -}}
{{- $_ := set $user "signingkey" (promptStringOnce . "git_signingkey" "Your signing key (leave empty if none)") -}}
{{- $_ := set $data "user" $user -}}
{{- toIni $data -}}
```

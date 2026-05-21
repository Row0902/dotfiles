## Exploration: gitconfig Enhancement

### Current State

`dot_gitconfig.tmpl` gestiona ~/.gitconfig con chezmoi en Windows y Unix. Config actual:

- **core**: pager=delta, editor=code --wait, autocrlf, filemode (OS-aware)
- **init**: defaultBranch=main
- **push**: autoSetupRemote=true
- **interactive**: diffFilter=delta
- **delta**: navigate, side-by-side, line-numbers, Monokai Extended Bright
- **alias**: st, cm, br, lg, f
- **include**: ~/.gitconfig.local
- **commit**: gpgsign=true
- **gpg**: format=ssh

Git 2.54.0 | Delta 0.19.2 | Fedora 44 / WSL2 / Windows

### Features evaluadas

| Feature | Config | Impacto | Veredicto |
|---------|--------|---------|-----------|
| `merge.conflictStyle = zdiff3` | `[merge]` | Merge conflicts muestran base + ours + theirs con más contexto. Recomendado por delta | ✅ |
| `diff.algorithm = histogram` | `[diff]` | Diffs más limpios que el default (myers). Mejor para código estructurado | ✅ |
| `rebase.autosquash = true` | `[rebase]` | `git rebase -i --autosquash` auto-ordena fixup/squash commits | ✅ |
| `rebase.autostash = true` | `[rebase]` | Stashea cambios dirty antes de rebase, los pop al terminar | ✅ |
| `rebase.updateRefs = true` | `[rebase]` | Actualiza branch pointers que apuntan a commits rebaseados | ✅ |
| `fetch.prune = true` | `[fetch]` | `git fetch` limpia remote-tracking branches eliminadas | ✅ |
| `fetch.pruneTags = true` | `[fetch]` | `git fetch` también limpia tags huérfanos | ✅ |
| `rerere.enabled = true` | `[rerere]` | Recuerda resoluciones de conflictos merge para re-aplicarlas | ✅ |
| `help.autocorrect = 10` | `[help]` | Corrige comandos mal escritos (10 = 1s de delay) | ✅ |
| `protocol.version = 2` | `[protocol]` | Git protocol v2 (más rápido, default desde 2.26) | ✅ |
| `log.date = iso` | `[log]` | Fechas en formato ISO en `git log` | 🟡 Bajo impacto |
| `tag.gpgsign = true` | `[tag]` | Firma tags GPG igual que commits | ✅ |
| `core.untrackedCache = true` | `[core]` | Cachea archivos untracked para `git status` más rápido | ✅ |
| `core.fsmonitor` | `[core]` (Windows) | File system monitor para status instantáneo (built-in desde git 2.35) | ✅ Windows |
| `diff.colorMoved = default` | `[diff]` | Resalta código movido (no modificado) en diffs | 🟡 |
| `credential.helper` | OS-aware | `manager-core` (Win), `cache --timeout=86400` (Unix), `osxkeychain` (macOS) | ✅ |
| `alias` nuevos | `[alias]` | co, rb, ap, dc, amend, unstage, wip | 🟡 |

### Aliases nuevos recomendados

| Alias | Comando | Por qué |
|-------|---------|---------|
| `co` | `checkout` | El más básico que falta |
| `rb` | `rebase` | Para usar con autosquash |
| `rbi` | `rebase -i` | Rebase interactivo |
| `ap` | `add -p` | Add parcial |
| `dc` | `diff --cached` | Diff de staged |
| `amend` | `commit --amend --no-edit` | Amend rápido |
| `unstage` | `restore --staged .` | Unstage todo |
| `wip` | `add . && commit -m wip` | Commit rápido WIP |

### Recomendación: Gitconfig Enhancement Pack

Agrupar mejoras en categorías:

1. **Performance** — untrackedCache, protocol.version, fsmonitor (Win), credential helper OS-aware
2. **Workflow** — merge.conflictStyle, diff.algorithm, rebase.*, fetch.prune, rerere, help.autocorrect
3. **Aliases** — co, rb, rbi, ap, dc, amend, unstage
4. **Delta features** — diff.colorMoved, hyperlinks
5. **Signing** — tag.gpgsign

### Riesgos

- `fetch.pruneTags = true` puede ser agresivo si compartís tags entre repos — considerar `--prune-tags` manual en vez de config
- `core.untrackedCache` requiere `core.trustctime = true` o puede dar falsos positivos
- `credential.helper` en WSL2 es tricky — la helper de Windows no funciona directo desde WSL
- `help.autocorrect = 10` puede ejecutar comandos no intencionales si escribís rápido — 0 desactiva, 10 es seguro (1s de pausa)

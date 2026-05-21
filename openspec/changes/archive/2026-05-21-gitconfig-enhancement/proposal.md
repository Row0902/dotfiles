# Proposal: Gitconfig Enhancement

## Intent

Modernize `dot_gitconfig.tmpl` with performance optimizations, workflow improvements, and security hardening across Windows, Linux/WSL2, and macOS. The current config lacks modern Git features that improve daily developer experience.

## Scope

### In Scope
- Performance: `core.untrackedCache`, `protocol.version = 2`, `core.fsmonitor` (Windows)
- Workflow: `merge.conflictStyle = zdiff3`, `diff.algorithm = histogram`, `rebase.*`, `fetch.prune`, `rerere.enabled`, `help.autocorrect`
- Security: `tag.gpgsign = true`
- Auth: `credential.helper` OS-aware (manager-core / osxkeychain / cache)
- Aliases: co, rb, rbi, ap, dc, amend, unstage

### Out of Scope
- `diff.colorMoved` (stylistic only, low impact)
- `fetch.pruneTags` (aggressive for shared tag workflows)
- `log.date` formatting
- Repo-level gitattributes/gitignore

## Capabilities

### New Capabilities
None — config-only change, no spec-level behavior changes.

### Modified Capabilities
None — no existing capabilities affected.

## Approach

Single-file edit to `dot_gitconfig.tmpl`. Add 4 new config sections (`[merge]`, `[diff]`, `[rebase]`, `[fetch]`, `[rerere]`, `[help]`, `[protocol]`, `[credential]`, `[tag]`) and extend existing `[core]` and `[alias]` sections. Use chezmoi `{{ if }}` blocks for OS-aware settings (credential helper, fsmonitor). Order: core → init → push → merge → diff → rebase → fetch → rerere → help → protocol → interactive → delta → alias → include → commit → tag → gpg → credential.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `dot_gitconfig.tmpl` | Modified | Add ~35 lines of new config across 9 sections |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| `untrackedCache` needs `trustctime=true` | Low | Verify trustctime is default; document in comment |
| `help.autocorrect` could auto-run wrong commands | Low | Set to 10 (1s delay, requires confirmation) |
| Credential helper in WSL2 | Low | Use `cache --timeout=86400` for Linux/WSL2, not manager-core |

## Rollback Plan

Restore `dot_gitconfig.tmpl` from git history via `git checkout HEAD -- dot_gitconfig.tmpl`, then run `chezmoi apply` to regenerate `~/.gitconfig`.

## Dependencies

None.

## Success Criteria

- [ ] `chezmoi apply` succeeds without errors
- [ ] `git config --list` shows all new settings
- [ ] `git status` still works (untrackedCache, fsmonitor)
- [ ] `git rebase -i` respects autosquash/autostash
- [ ] `git merge` shows zdiff3 conflict style
- [ ] `git credential` uses correct OS helper

## Verification Report

**Change**: new-machine-bootstrap
**Version**: N/A
**Mode**: Standard (dotfiles project — no test runner, no Strict TDD)

---

### Completeness

| Metric | Value |
|--------|-------|
| Tasks total | 8 (implementation tasks 1.1–4.2) |
| Tasks complete | 8 |
| Tasks incomplete | 0 |

Notes: Tasks 5.x (verification) and 6.x (archive) are process tasks, not implementation items. All implementation tasks are done.

---

### Build & Tests Execution

**Build**: ➖ Not applicable (dotfiles / shell scripts — no build system)

**Tests**: ➖ Not applicable (no test runner for this project; spec scenarios validated via structural/behavioral review below)

**Coverage**: ➖ Not available

---

### Spec Compliance Matrix

| Requirement | Scenario | Evidence | Result |
|-------------|----------|----------|--------|
| **B1.1** Brewfile lists all brew tools | Brewfile is comprehensive | Brewfile contains 16 brew formulas + 1 tap | ✅ COMPLIANT |
| **B1.2** bootstrap runs brew bundle | brew bundle executes | `bootstrap.sh:61` runs `brew bundle --file "$REPO_DIR/Brewfile"` | ✅ COMPLIANT |
| **B1.3** Brewfile works on both Linux and macOS | No platform-specific entries | All entries are `brew` type, no `cask`, no macOS-only taps | ✅ COMPLIANT |
| **B2.1** promptOnce for name, email, signingkey | Template uses promptOnce | `dot_gitconfig.local.tmpl` lines 2–6 use `promptOnce` for all three fields | ✅ COMPLIANT |
| **B2.2** Template sources from main gitconfig | Include directive exists | `dot_gitconfig.tmpl:70-71` has `[include] path = ~/.gitconfig.local` | ✅ COMPLIANT |
| **B2.3** Responses cached (no re-prompt) | chezmoi promptOnce caches | `promptOnce` stores values in chezmoi config data by design | ✅ COMPLIANT |
| **B3.1** Scan ~/.ssh/ with file command | detect_ssh_keys uses file | `bootstrap.sh:120-131` uses `file … grep -qi "private key"` | ✅ COMPLIANT |
| **B3.2** Offer to switch remote if keys exist | User prompt present | `bootstrap.sh:144` asks to use keys and switch remote | ✅ COMPLIANT |
| **B3.3** WSL: scan Windows SSH dir | Scans /mnt/c/Users/*/.ssh/ | `bootstrap.sh:152-188` detects WSL and scans Windows directory | ✅ COMPLIANT |
| **B3.4** Ask to import Windows keys | User prompt present | `bootstrap.sh:172` asks to import keys to WSL | ✅ COMPLIANT |
| **B3.5** Offer ed25519 key generation | Generation offered | `bootstrap.sh:194` asks to generate new ed25519 key | ✅ COMPLIANT |
| **B3.6** Run gh auth login + gh ssh-key add | Both commands present | `bootstrap.sh:205-206` runs `gh auth login` + `gh ssh-key add` | ✅ COMPLIANT |
| **B4.1** chsh to fish | Shell change present | `bootstrap.sh:104` runs `chsh -s "$FISH_PATH"` using dynamic path | ✅ COMPLIANT* |
| **B5.1** Change remote to SSH after SSH setup | HTTPS → SSH switch | `bootstrap.sh:241-243` detects HTTPS remote and switches to SSH | ✅ COMPLIANT |

**Compliance summary**: 14/14 scenarios compliant

*\*B4.1 note: Spec says `chsh -s /usr/bin/fish` but implementation uses `command -v fish` for the path. This is a **strict improvement** — hardcoded `/usr/bin/fish` would fail on Linuxbrew installs where fish lives at `/home/linuxbrew/.linuxbrew/bin/fish`. Dynamic resolution is correct.*

---

### Correctness (Static — Structural Evidence)

| Requirement | Status | Notes |
|------------|--------|-------|
| Brewfile covers all brew tools | ✅ Implemented | 16 formulas covering all categories (shell, prompt, tools, git, languages, terminal) |
| dot_gitconfig.local.tmpl uses promptOnce | ✅ Implemented | All three fields (name, email, signingkey) use promptOnce; signingkey conditionally rendered |
| dot_gitconfig.tmpl includes local | ✅ Implemented | `[include] path = ~/.gitconfig.local` at line 70 |
| bootstrap.sh is executable | ✅ Implemented | Permissions: 755 |
| bootstrap.sh is idempotent | ✅ Implemented | Each phase checks preconditions before acting (Homebrew installed, .gitconfig.local exists, fish is shell, keys exist, gh authenticated, remote is SSH) |
| bootstrap.sh covers all phases | ✅ Implemented | Phases 1–6 match spec: brew → git identity → fish → SSH → gh auth → remote |
| README has simplified onboarding | ✅ Implemented | Two-step flow: `chezmoi init --apply` (mandatory) + `bootstrap.sh` (optional/recommended) |

---

### Coherence (Design)

| Decision | Followed? | Notes |
|----------|-----------|-------|
| Brewfile catalog structure | ✅ Yes | Matches design — organized by category with comments |
| promptOnly template approach | ✅ Yes | Uses promptOnce as designed; signingkey conditional handled with `{{ if $key }}` |
| SSH key detection algorithm | ✅ Yes | Implementation matches design pseudocode exactly (file exclusion list, file command grep) |
| bootstrap.sh architecture | ✅ Yes | All 6 phases present, idempotent, interactive with colored output |
| File locations match design table | ✅ Yes | Brewfile, scripts/bootstrap.sh, dot_gitconfig.local.tmpl all in expected locations |
| Brewfile formula list | ⚠️ Deviated | Design listed `bash`; actual omits it (reasonable — system pre-installed). Design didn't list `fnm` or `zellij`; actual adds them (reasonable improvements) |

---

### Issues Found

**CRITICAL** (must fix before archive):
None

**WARNING** (should fix):
1. **bootstrap.sh Phase 2 creates .gitconfig.local manually** — The script's Phase 2 writes `~/.gitconfig.local` via `read -rp`, bypassing chezmoi's `promptOnce`. If bootstrap runs before `chezmoi apply`, the template would prompt again (values not cached in chezmoi config). The README clarifies the correct order (chezmoi first), but the script itself doesn't enforce or warn about this. Consider adding a comment or guard.

2. **Brewfile formula drift from design** — `bash` was dropped, `fnm` and `zellij` were added. Not a spec violation (spec says "all brew-formula tools needed", not "exactly these"), but differs from design document.

**SUGGESTION** (nice to have):
1. **Hardcoded GitHub remote** — `bootstrap.sh:243` hardcodes `git@github.com:Row0902/dotfiles.git`. Consider deriving the SSH URL from the current remote (e.g., convert `https://github.com/Row0902/dotfiles` → `git@github.com:Row0902/dotfiles.git`) for robustness.

2. **bootstrap.sh Phase numbering** — Comments say "Fase 1/5", "Fase 2/6", "Fase 3/6"... The first says 1/5 but there are 6 phases. Cosmetic but confusing.

3. **B1.3 cross-platform Brewfile** — While all current entries are `brew` (no `cask`), consider adding a comment clarifying this is intentional for Linux compatibility.

---

### Verdict

**PASS WITH WARNINGS**

All 14 spec scenarios are structurally and behaviorally compliant. The two warnings (manual gitconfig creation bypassing promptOnce, and minor formula list drift) are non-blocking for archive but worth noting. The implementation is solid, idempotent, and well-structured.
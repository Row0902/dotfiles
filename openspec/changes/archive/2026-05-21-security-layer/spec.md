# Security Layer — Spec

## Domain: age-encryption

### AGE-01: age encryption config (MUST)
`chezmoi.toml` MUST configure `encryption = "age"` con identity + recipient.

#### Scenario: age key generation
- GIVEN `chezmoi age-keygen --output=~/.config/chezmoi/key.txt`
- WHEN the command runs
- THEN key.txt is created and the public key is printed

#### Scenario: encrypt config
- GIVEN key.txt exists
- WHEN `chezmoi add --encrypt` runs
- THEN files are stored as `.age` in source state

### AGE-02: Key backup (SHOULD)
The public key MUST be documented. Private key SHOULD be backed up externally.

## Domain: modify-gitconfig-local

### MOD-01: modify template for gitconfig.local (MUST)
A modify template MUST edit the `[user]` section of `~/.gitconfig.local`.

#### Scenario: modify user section
- GIVEN `~/.gitconfig.local` with existing or empty `[user]` section
- WHEN `chezmoi apply` runs
- THEN it prompts and updates name/email/signingkey

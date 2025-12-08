# AGENTS
Scope: entire repo (no nested overrides).
Cursor/Copilot rules: none present as of 2025-12-08.
## Build / Lint / Test
Container: `mcr.microsoft.com/vscode/devcontainers/base:bullseye` (starship feature).
Lint everything: `shellcheck .bash_aliases scripts/**/*.sh`.
Syntax check: `bash -n .bash_aliases scripts/**/*.sh` (or per-file while editing).
Runtime sanity: `bash -lc "source .bashrc && source .bash_aliases"`.
Single-file lint remains `shellcheck path/to/file.sh`.
## Style / Conventions
Modules live in `scripts/lib`, `scripts/aliases`, and `scripts/os`; each is `#!/bin/bash` with matching `#region/#endregion` markers.
Define helpers with `function name {` blocks, leading `# @description` (+ `@arg` when applicable), `local` vars, and quoted expansions.
Use shared helpers (`os`, `confirm`, `exists`, `alias-help`, `get_alias_table`) instead of duplicating logic.
Aliases belong in descriptive `kebab-case`; functions stick to verb_noun and reuse module-level coloring/globals from `scripts/lib/core.sh`.
Source user overrides only after verifying the file exists, and keep Starship init last in `.bashrc`.
Prefer early returns with stderr messaging and confirmations before destructive actions.
Update this file/README whenever workflows or conventions change.

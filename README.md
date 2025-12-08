# dotfiles

Personal Bash environment that keeps aliases, helper functions, and OS-specific tweaks organized into modules.

## Installation
1. Run `./install.sh` from the repo root; it detects macOS/Linux and adds a guarded `source` block to your preferred Bash startup file.
2. The script only appends the snippet when it doesn't already exist, so re-running it is safe.
3. Reload your shell (`source ~/.bashrc` or `source ~/.bash_profile`) or open a new terminal to pick up the aliases.

## Structure
- `.bashrc` sources `.bash_aliases`, then boots Starship (keep it last).
- `.bash_aliases` exports `DOTFILES_ROOT`/`SCRIPTS_ROOT` and auto-sources everything inside `scripts/lib`, `scripts/aliases`, and `scripts/os`.
- `scripts/lib/core.sh` holds the prompt, shared globals, and helper utilities like `confirm`, `alias-help`, and `get_alias_table`.
- `scripts/aliases/` groups related commands (navigation, git, docker, network, services, etc.) behind `#region` markers.
- `scripts/os/` contains platform-aware extras (Linux `update`, macOS Finder helpers).

## Usage
- Add new helpers by dropping a `#!/bin/bash` module under `scripts/aliases` (or `scripts/os/<platform>.sh`) with `# @description` metadata and `function name { ... }` bodies.
- Use `alias-help <name>` to see the resolved alias/function plus the nearest `# @description`.
- Generate a quick capability table with `get_alias_table` (optionally pass a directory/file to scope the output).
- Keep overrides in `~/.bash_private_aliases`; the loader only sources it when the file exists.

## Validation
- ShellCheck: `shellcheck .bash_aliases scripts/**/*.sh`.
- Syntax check: `bash -n .bash_aliases scripts/**/*.sh` (or run per-file while editing).
- Runtime sanity: `bash -lc "source .bashrc && source .bash_aliases"` to ensure every module loads cleanly.

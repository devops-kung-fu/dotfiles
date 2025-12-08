#!/bin/bash

#region module-loader
# @description Loads modularized dotfiles helpers and alias groups.
DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_ROOT="$DOTFILES_ROOT/scripts"
export DOTFILES_ROOT
export SCRIPTS_ROOT

function source_dir {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    local file
    local files=("$dir"/*.sh)
    for file in "${files[@]}"; do
      [[ -f "$file" ]] || continue
      # shellcheck source=/dev/null
      source "$file"
    done
  fi
}

source_dir "$SCRIPTS_ROOT/lib"
source_dir "$SCRIPTS_ROOT/aliases"
source_dir "$SCRIPTS_ROOT/os"

#load private aliases if available
if [[ -f ~/.bash_private_aliases ]]; then
  # shellcheck source=/dev/null
  source ~/.bash_private_aliases
fi
#endregion

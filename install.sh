#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
DOTFILES_ROOT="$SCRIPT_DIR"
DOTFILES_SNIPPET_ID="# >>> dotfiles aliases >>>"

log() {
  printf '[dotfiles] %s\n' "$1"
}

fail() {
  printf '[dotfiles] %s\n' "$1" >&2
  exit 1
}

detect_os() {
  local uname_out
  uname_out="$(uname -s | tr '[:upper:]' '[:lower:]')"
  case "$uname_out" in
    linux*) echo "linux" ;;
    darwin*) echo "darwin" ;;
    *) fail "Unsupported OS: $uname_out" ;;
  esac
}

choose_rc_file() {
  local os="$1"
  local home_dir="$HOME"
  local bashrc="$home_dir/.bashrc"
  local bash_profile="$home_dir/.bash_profile"

  if [[ "$os" == "darwin" ]]; then
    if [[ -f "$bash_profile" ]]; then
      echo "$bash_profile"
    else
      echo "$bashrc"
    fi
  else
    if [[ -f "$bashrc" || ! -f "$bash_profile" ]]; then
      echo "$bashrc"
    else
      echo "$bash_profile"
    fi
  fi
}

build_snippet() {
  cat <<EOF
$DOTFILES_SNIPPET_ID
if [ -f "$DOTFILES_ROOT/.bash_aliases" ]; then
  source "$DOTFILES_ROOT/.bash_aliases"
fi
# <<< dotfiles aliases <<<
EOF
}

ensure_snippet() {
  local rc_file="$1"
  touch "$rc_file"

  if grep -F "$DOTFILES_SNIPPET_ID" "$rc_file" >/dev/null 2>&1; then
    log "Snippet already present in $rc_file. No changes made."
    return 0
  fi

  {
    echo
    build_snippet
  } >> "$rc_file"

  log "Added dotfiles loader to $rc_file"
}

main() {
  local os
  os="$(detect_os)"
  local rc_file
  rc_file="$(choose_rc_file "$os")"

  ensure_snippet "$rc_file"
  log "Done. Reload your shell or run: source $rc_file"
}

main "$@"

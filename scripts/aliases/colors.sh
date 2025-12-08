#!/bin/bash

#region colors
# @description Generates a color table for 16 million RGB colors using ANSI escape codes.
# @arg $1 integer 3 or 4 (foreground or background).
function color-table-rgb {
  echo
  echo 'Mode 2 Color Table'
  echo '------------------'
  echo 
  echo 'Parameters are 3 or 4 (foreground or background)'
  echo "Some samples of colors for r;g;b. Each one may be 000..255"
  echo

  local fb="$1"
  [[ $fb != 3 ]] && fb=4

  local samples=(0 63 127 191 255)
  local r
  local g
  local b
  for r in "${samples[@]}"; do
    for g in "${samples[@]}"; do
      for b in "${samples[@]}"; do
        printf '\e[0;%s8;2;%s;%s;%sm%03d;%03d;%03d ' "$fb" "$r" "$g" "$b" "$r" "$g" "$b"
      done
      printf '\e[m\n'
    done
    printf '\e[m'
  done
  echo
}

# @description Displays a single ANSI color.
# @arg $c integer ANSI color code.
function color {
  local c
  for c; do
    printf '\e[48;5;%dm%03d' "$c" "$c"
  done
  printf '\e[0m \n'
}

# @description Generates a color table using ANSI escape codes.
function color-table {
  # nosemgrep: bash.lang.security.ifs-tampering.ifs-tampering
  IFS=$' \t\n'
  color {0..15}
  local i
  for ((i=0; i<6; i++)); do
    color $(seq $((i*36+16)) $((i*36+51)))
  done
  color {232..255}
}
#endregion

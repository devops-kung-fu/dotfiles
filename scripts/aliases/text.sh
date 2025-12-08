#!/bin/bash

: "${orange:=}"
: "${reset:=}"
: "${green:=}"

#region text
# @description Trims a specified number of characters from the end of a string.
# @arg $1 string The input string.
# @arg $2 integer The number of characters to trim from the end.
function trim-end {
  printf '%s' "$1" | sed "s/.{$2}$//"
}

# @description Displays unique lines from a file, ignoring case.
# @arg $1 string The path to the input file.
function unique-lines {
  sort -rn "$1" | uniq -u
}

# @description Cleans accents from directory names.
function clean-accents-dirs {
  find . -type d | tac | while IFS= read -r d; do 
    local d_clean
    d_clean=$(echo "$d" | iconv -c -f utf8 -t ascii)
    if [[ "$d" != "$d_clean" ]]; then
      echo "[${orange}>${reset}] Moving $d to $d_clean..."
      echo "[${green}*${reset}] mv -n \"$d\" \"$d_clean\" "
    fi
  done
}

# @description Cleans accents from file names.
function clean-accents-files {
  find . -name "*" | while IFS= read -r f; do 
    local f_clean
    f_clean=$(echo "$f" | iconv -c -f utf8 -t ascii)
    if [[ "$f" != "$f_clean" ]]; then
      echo "[${orange}>${reset}] Moving $f to $f_clean..."
      echo "[${green}*${reset}] mv -n \"$f\" \"$f_clean\" "
    fi
  done
}

# @description Cleans accents from both directory and file names.
function clean-accents {
  clean-accents-dirs
  clean-accents-files
}

# @description Replaces spaces with line breaks in a file.
# @arg $1 string The path to the input file.
function spaces-to-breaks {
  tr ' ' '\n' < "$1"
}
#endregion

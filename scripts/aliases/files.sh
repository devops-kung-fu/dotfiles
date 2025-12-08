#!/bin/bash

: "${red:=}"
: "${reset:=}"

#region files
# @description Counts all files (including hidden files) recursively in the current folder.
# @usage countallfiles
function countallfiles {
    local count
    count=$(find . -type f | wc -l)
    echo "Number of files: $count"
}

# @description Counts the number of non-hidden files recursively in the current folder.
# @usage countfiles
function countfiles {
    local count
    count=$(find . -type f ! -name '.*' | wc -l)
    echo "Number of non-hidden files: $count"
}

# @description Counts the number of lines in a file
# @param $1 filename
function countlines {
  find "./$1" -name '*.*' -print0 | xargs -0 wc -l
}

# @description Delete a folder from all subfolders recursively
# @param $1 folder name
function rrd {
  echo "The following folders will be ${red} DELETED! ${reset}"
  echo
  find . -type d -name "$1" -a -prune
  echo
  confirm && find . -type d -name "$1" -a -prune -exec rm -rf {} \;
}

# @description Delete a file from all subfolders recursively
# @param $1 file name
function rr {
  if [[ $# -ne 1 ]]; then
    echo "Usage: loadenv <filename>"
    return 1
  fi

  read -r -p "Are you sure you want to delete $1? (y/n)" answer
  if [[ "$answer" == "y" ]]; then
    find . -name "$1" -delete
  else
    echo "File deletion aborted."
  fi
}
#endregion

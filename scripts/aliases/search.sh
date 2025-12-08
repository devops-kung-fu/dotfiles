#!/bin/bash

#region search
# @description Searches for a given pattern in all files under the current directory and prints the matched text with line numbers, highlighting occurrences of the pattern in red.
# @arg $1 string The pattern to search for.
function term {
  find "$(pwd)" -type f -print0 | xargs -0 grep -n -- "$1" | awk -F ':' -v pattern="$1" '{gsub(pattern, "\033[1;31m&\033[0m", $3); printf "\033[1;33m%s\033[0m:%s %s\n", $1, $2, $3}'
}

# @description Searches for a given pattern in all files under the current directory, displays the matches with colors, and prints "DONE!" afterward.
# @arg $1 string The pattern to search for.
function search {
  echo "Searching for '$1' in '$(pwd)'..."
  grep -r --color=always -- "$1" .
  echo "DONE!"
}
#endregion

#!/bin/bash

#region prompt
# @description Sets a colored prompt for the terminal, including user, host, current location, and Git branch (if applicable).
function color_prompt {
    local __user_and_host="\[\033[01;32m\]\u@\h"
    local __cur_location="\[\033[01;34m\]\w"
    local __git_branch_color="\[\033[31m\]"
    local __git_branch=""
    local __branch_name
    __branch_name=$(git symbolic-ref --quiet --short HEAD 2>/dev/null)
    if [[ -n "$__branch_name" ]]; then
        __git_branch="($__branch_name) "
    fi
    local __prompt_tail="\[\033[35m\]$"
    local __last_color="\[\033[00m\]"
    export PS1="$__user_and_host $__cur_location $__git_branch_color$__git_branch$__prompt_tail$__last_color "
}

color_prompt
#endregion


#region globals
red=$(tput setaf 1); export red
green=$(tput setaf 2); export green
yellow=$(tput setaf 3); export yellow
blue=$(tput setaf 4); export blue
magenta=$(tput setaf 5); export magenta
cyan=$(tput setaf 6); export cyan
pinkish=$(tput setaf 160); export pinkish
orange=$(tput setaf 202); export orange
lightblue=$(tput setaf 39); export lightblue
reset=$(tput sgr0); export reset

export EDITOR="nano"
export TEMP="/tmp"
GPG_TTY=$(tty)
export GPG_TTY
#endregion

#region helpers
# @description Displays a message indicating that a specific command or function is not available on the current operating system.
# @param $1 string The name of the command or function that is not available.
function notavailable {
  echo "$1 not available on $(lowercase "$(uname)")"
}

# @description Returns the list of dotfiles module scripts to inspect for aliases/functions.
function __dotfiles_module_files {
  if [[ -n "$SCRIPTS_ROOT" && -d "$SCRIPTS_ROOT" ]]; then
    find "$SCRIPTS_ROOT" -type f -name '*.sh' -print | sort
  else
    printf '%s\n' "$HOME/.bash_aliases"
  fi
}

# Experimental
function get_alias_table {
  local target_path="$1"
  local wrap_width=70
  local -a files=()

  if [[ -n "$target_path" ]]; then
    if [[ -d "$target_path" ]]; then
      while IFS= read -r file; do
        files+=("$file")
      done < <(find "$target_path" -type f -name '*.sh' -print | sort)
    elif [[ -f "$target_path" ]]; then
      files+=("$target_path")
    else
      echo "Error: File not found: $target_path"
      return 1
    fi
  else
    while IFS= read -r file; do
      files+=("$file")
    done < <(__dotfiles_module_files)
  fi

  if [[ ${#files[@]} -eq 0 ]]; then
    echo "Error: No alias files found."
    return 1
  fi

  echo "+---------------------+----------------------------------------------------+"
  printf "| %-20s | %-70s |\n" "Alias/Function" "Description"
  echo "+---------------------+----------------------------------------------------+"

  local file line description
  for file in "${files[@]}"; do
    description=""
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -z "$line" ]] && continue
      if [[ "$line" =~ ^#\ @description ]]; then
        description="${line#\# @description }"
        continue
      fi

      if [[ "$line" =~ ^alias[[:space:]]+([[:alnum:]_-]+)= ]]; then
        local alias_name="${BASH_REMATCH[1]}"
        local wrapped_comment
        wrapped_comment=$(echo "${description:-No description provided}" | fold -s -w "$wrap_width")
        printf "| %-20s | %-70s |\n" "$alias_name" "$wrapped_comment"
        echo "+---------------------+----------------------------------------------------+"
        description=""
      elif [[ "$line" =~ ^function[[:space:]]+([[:alnum:]_-]+)[[:space:]]*\{ ]]; then
        local func_name="${BASH_REMATCH[1]}"
        local wrapped_func_comment
        wrapped_func_comment=$(echo "${description:-No description provided}" | fold -s -w "$wrap_width")
        printf "| %-20s | %-70s |\n" "$func_name" "$wrapped_func_comment"
        echo "+---------------------+----------------------------------------------------+"
        description=""
      fi
    done < "$file"
  done
}

# @description Displays the help information for a specified alias or function.
# @param $1 string The alias/function for which to display help information.
# @return 0 if the alias/function is found, 1 otherwise.
function alias-help {
  local target="$1"
  if [[ -z "$target" ]]; then
    echo "Error: Please provide an alias as an argument"
    return 1
  fi

  local description=""
  local match_type=""

  while IFS= read -r file; do
    local current_description=""
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -z "$line" ]] && continue
      if [[ "$line" =~ ^#\ @description ]]; then
        current_description="${line#\# @description }"
        continue
      fi

      if [[ "$line" =~ ^alias[[:space:]]+${target}= ]]; then
        description="$current_description"
        match_type="alias"
        break 2
      fi

      if [[ "$line" =~ ^function[[:space:]]+${target}[[:space:]]*\{ ]]; then
        description="$current_description"
        match_type="function"
        break 2
      fi
    done < "$file"
  done < <(__dotfiles_module_files)

  if [[ "$match_type" == "alias" ]]; then
    alias "$target"
  elif [[ "$match_type" == "function" ]]; then
    declare -f "$target"
  else
    if alias "$target" >/dev/null 2>&1; then
      alias "$target"
    elif declare -f "$target" >/dev/null 2>&1; then
      declare -f "$target"
    else
      echo "Alias not found: $target"
      return 1
    fi
  fi

  if [[ -n "$description" ]]; then
    echo "$target - $description"
  fi
}

# @description Displays a progress bar in the terminal.
# @param $1 int The percentage of completion for the progress bar.
# @param $@ string Additional information to display alongside the progress bar.
function progressbar {
  local w=80
  local p=$1
  shift
  printf -v dots "%*s" "$(( p*w/100 ))" ""
  dots=${dots// /.}
  printf "\r\e[K|%-*s| %3d %% %s" "$w" "$dots" "$p" "$*"
}

# @description Converts a string to lowercase.
# @param $1 string The string to convert to lowercase.
function lowercase {
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

# @description Checks if the current operating system matches the specified one.
# @param $1 string The operating system to check against.
# @return 0 if the operating systems match, 1 otherwise.
function os {
  local INSTALLEDOS
  INSTALLEDOS=$(lowercase "$(uname)")
  local PASSEDOS
  PASSEDOS=$(lowercase "$1")

  if [[ "$INSTALLEDOS" == "$PASSEDOS" ]]; then
      return 0
  fi
  return 1
}

# @description Checks if a command exists in the system.
# @param $1 string The command to check for existence.
# @return 0 if the command exists, 1 otherwise.
function exists {
  if command -v "$1" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# @description Sources the specified .env file or sources every .env file in the current folder.
# @param $1 string (optional) Path to the .env file to source.
function loadenv {
  local file="$1"

  if [[ -n "$file" ]]; then
    echo "Sourcing: $file"
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      export "${line?}"
    done < "$file"
  else
    for env_file in ./*.env; do
      [[ -e "$env_file" ]] || continue
      echo "Sourcing: $env_file"
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        export "${line?}"
      done < "$env_file"
    done
  fi
}

# @description Waits for a specified number of seconds, displaying a countdown.
# @param $1 int Number of seconds to wait.
function waitsec {
  local secs=$1
  while [[ $secs -gt 0 ]]; do
    printf "Waiting: %s \033[0K\r" "$secs"
    sleep 1
    : $((secs--))
  done
}

# @description Prompts the user for confirmation with a default message.
# @param ${1:-Are you sure? [y/N]} string Custom confirmation message (optional).
# @returns true if the user confirms (y or yes), false otherwise.
function confirm {
  read -r -p "${1:-Are you sure? [y/N]} " response
  case "$response" in
    [yY][eE][sS]|[yY])
      true
      ;;
    *)
      false
      ;;
  esac
}

# @description Displays a list of available aliases and functions.
function aliases {
  echo "Aliases:"
  alias -p | cut -d= -f1 | sed 's/^alias //' | sort
  echo
  echo "Functions:"
  compgen -A function | sort
}

# @description Copies the contents of a file to the clipboard.
# @param $1 string Path to the file.
function clip {
  if os Darwin; then
    pbcopy < "$1"
  elif os Linux; then
    xclip -selection clipboard < "$1"
  else
    echo "Error: Clipboard operations are not supported on this platform." >&2
    return 1
  fi
}

# @description Copies the current working directory to the clipboard.
function clippwd {
  if os Darwin; then
    pwd | pbcopy
  elif os Linux; then
    pwd | xclip -selection clipboard
  else
    echo "Error: Clipboard operations are not supported on this platform." >&2
    return 1
  fi
}
#endregion

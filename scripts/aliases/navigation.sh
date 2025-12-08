#!/bin/bash

#region navigation
# @description Changes directory to the parent directory.
alias ..="cd .."

# @description Changes directory to two levels up from the current directory.
alias ....="cd ../../"

# @description Changes directory to three levels up from the current directory.
alias ......="cd ../../../"

if [ -x /usr/bin/dircolors ]; then
  # @description Checks if the ~/.dircolors file is readable, and if so, evaluates its content; otherwise, evaluates the default dircolors settings.
  if test -r ~/.dircolors; then
    eval "$(dircolors -b ~/.dircolors)"
  else
    eval "$(dircolors -b)"
  fi

  # @description Alias for 'ls' command with automatic coloring enabled.
  alias ls='ls --color=auto'

  # @description Alias for 'dir' command with automatic coloring enabled.
  alias dir='dir --color=auto'

  # @description Alias for 'vdir' command with automatic coloring enabled.
  alias vdir='vdir --color=auto'

  # @description Alias for 'grep' command with automatic coloring enabled.
  alias grep='grep --color=auto'

  # @description Alias for 'fgrep' command with automatic coloring enabled.
  alias fgrep='fgrep --color=auto'

  # @description Alias for 'egrep' command with automatic coloring enabled.
  alias egrep='egrep --color=auto'
fi

# @description Lists all files and directories in long format with human-readable sizes.
alias ll='ls -lah'

# @description Lists all files and directories, excluding "." and "..".
alias la='ls -A'

# @description Lists files and directories in a single column with indicators.
alias l='ls -CF'

# @description Opens the default editor (Neovim).
alias edit='nvim'

# @description Changes to the previous directory.
alias cdb="cd -"

# @description Changes to the home directory.
alias cdh='cd ~/'

# @description Changes to the home directory.
alias h='cd ~/'

# Check if the user is not root (UID is not 0) and create an alias to reboot with sudo if true.
if [ "$UID" -ne 0 ]; then
  alias reboot='sudo reboot'
fi

# @description Wrapper for 'pushd' command, redirects output to /dev/null.
function pushd {
  command pushd "$@" > /dev/null || return
}

# @description Wrapper for 'popd' command, redirects output to /dev/null.
function popd {
  command popd "$@" > /dev/null || return
}
#endregion

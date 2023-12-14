#!/bin/bash

#region prompt
# @description Sets a colored prompt for the terminal, including user, host, current location, and Git branch (if applicable).
function color_prompt {
    # Set the color for the user and host
    local __user_and_host="\[\033[01;32m\]\u@\h"

    # Set the color for the current location (working directory)
    local __cur_location="\[\033[01;34m\]\w"

    # Set the color for the Git branch (if in a Git repository)
    local __git_branch_color="\[\033[31m\]"
    local __git_branch='`git branch 2> /dev/null | grep -e ^* | sed -E  s/^\\\\\*\ \(.+\)$/\(\\\\\1\)\ /`'

    # Set the color for the prompt tail (symbol indicating the end of the prompt)
    local __prompt_tail="\[\033[35m\]$"

    # Set the color for the last part of the prompt to reset any color changes
    local __last_color="\[\033[00m\]"

    # Combine all components to form the complete PS1 prompt string
    export PS1="$__user_and_host $__cur_location $__git_branch_color$__git_branch$__prompt_tail$__last_color "
}

# Call the color_prompt function to apply the colored prompt
color_prompt


#endregion

#region globals

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
pinkish=`tput setaf 160`
orange=`tput setaf 202`
lightblue=`tput setaf 39`
reset=`tput sgr0`

export EDITOR="nano"
export TEMP="/tmp"

# @description Displays a message indicating that a specific command or function is not available on the current operating system.
# @param $1 string The name of the command or function that is not available.
function notavailable {
  echo "$1 not available on $(lowercase $(uname))"
}

# Experimental
get_alias_table() {
  local file_path="$1"
  local wrap_width=70

  # Check if the file exists
  if [ ! -f "$file_path" ]; then
    echo "Error: File not found: $file_path"
    exit 1
  fi

  # Function to wrap text to a specified width
  wrap_text() {
    local text="$1"
    echo "$text" | fold -s -w "$wrap_width"
  }

  # Print the table header
  echo "+---------------------+----------------------------------------------------+"
  printf "| %-20s | %-70s |\n" "Alias" "Description"
  echo "+---------------------+----------------------------------------------------+"

  # Extract aliases and descriptions from the file
  grep -E '^alias [a-zA-Z0-9_]+=' "$file_path" | while read -r line; do
    alias_name=$(echo "$line" | cut -d '=' -f1 | cut -d ' ' -f2)
    comment=$(grep -E "^# @description" "$file_path" | grep "$alias_name" | sed 's/# @description //')
    wrapped_comment=$(wrap_text "$comment")
    printf "| %-20s | %-70s |\n" "$alias_name" "$wrapped_comment"
    echo "+---------------------+----------------------------------------------------+"
  done
}

# @description Displays the help information for a specified alias.
# @param $1 string The alias for which to display help information.
# @return 0 if the alias is found, 1 otherwise.
function alias-help {
  if [[ -z "$1" ]]; then
    echo "Error: Please provide an alias as an argument"
    return 1
  fi

  while read -r line; do
    full="${line}"
    line="${line#alias }"
    line="${line%=*}"
    if [[ "$line" == "$1" ]]; then
      echo $1 -"${full#*#}"
      return 0
    fi
  done < "$HOME/.bash_aliases"

  echo "Alias not found: $1"
  return 1
}

# @description Displays a progress bar in the terminal.
# @param $1 int The percentage of completion for the progress bar.
# @param $@ string Additional information to display alongside the progress bar.
function progressbar {
  local w=80 p=$1;  shift
  # create a string of spaces, then change them to dots
  printf -v dots "%*s" "$(( $p*$w/100 ))" ""; dots=${dots// /.};
  # print those dots on a fixed-width space plus the percentage etc. 
  printf "\r\e[K|%-*s| %3d %% %s" "$w" "$dots" "$p" "$*"; 
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
  INSTALLEDOS=$(lowercase $(uname))
  PASSEDOS=$(lowercase $1)

  if [[ $INSTALLEDOS == $PASSEDOS ]]; then
      return 0
  fi
  return 1
}

# @description Checks if a command exists in the system.
# @param $1 string The command to check for existence.
# @return 0 if the command exists, 1 otherwise.
function exists {
  if [ -x "$(command -v $1)" ]; then
    return 0
  fi
  return 1
}


# @description Sources the specified .env file or sources every .env file in the current folder.
# @param $1 string (optional) Path to the .env file to source.
function loadenv {
  if [ -n "$1" ]; then
    # If $1 is provided, source the specified .env file
    echo "Sourcing: $1"
    source "$1"
  else
    # Source every .env file in the current folder
    for env_file in ./*.env; do
      [ -e "$env_file" ] || continue
      echo "Sourcing: $env_file"
      source "$env_file"
    done
  fi
}

# @description Waits for a specified number of seconds, displaying a countdown.
# @param $1 int Number of seconds to wait.
function waitsec {
  secs=$1
  while [ $secs -gt 0 ]; do
    printf "Waiting: $secs \033[0K\r"
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

# @description Displays a list of functions and aliases defined in ~/.bash_aliases.
function aliases {
  # Extracts and displays a list of functions and aliases from ~/.bash_aliases.
  aliases=$(grep "^function" ~/.bash_aliases | awk '{print $2}')
  echo $aliases
}


# @description Copies the contents of a file to the clipboard.
# @param $1 string Path to the file.
function clip {
  # Check if the operating system is Darwin (macOS)
  if os Darwin; then
    cat "$1" | pbcopy
  elif os Linux; then
    # Use xclip on Linux
    cat "$1" | xclip -selection clipboard
  else
    # Handle other operating systems
    echo "Error: Clipboard operations are not supported on this platform." >&2
    return 1
  fi
}

# @description Copies the current working directory to the clipboard.
function clippwd {
  # Check if the operating system is Darwin (macOS)
  if os Darwin; then
    echo "$(pwd)" | pbcopy
  elif os Linux; then
    # Use xclip on Linux
    echo "$(pwd)" | xclip -selection clipboard
  else
    # Handle other operating systems
    echo "Error: Clipboard operations are not supported on this platform." >&2
    return 1
  fi
}

#endregion

#region linux specific

if os Linux; then
  # @description Updates the package list, upgrades installed packages, and removes unnecessary dependencies. Requires sudo privileges.
  function update {
    sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
  }
fi

#endregion

#region navigation

# @description Changes directory to the parent directory.
alias ..="cd .."

# @description Changes directory to two levels up from the current directory.
alias ....="cd ../../"

# @description Changes directory to three levels up from the current directory.
alias ......="cd ../../../"

if [ -x /usr/bin/dircolors ]; then
  # @description Checks if the ~/.dircolors file is readable, and if so, evaluates its content; otherwise, evaluates the default dircolors settings.
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"

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

# @description Changes to the previous directory.
alias cdb="cd -"

# @description Changes to the home directory.
alias cdh='cd ~/'

# @description Changes to the home directory.
alias h='cd ~/'

# Check if the user is not root (UID is not 0) and create an alias to reboot with sudo if true.
if [ $UID -ne 0 ]; then
  alias reboot='sudo reboot'
fi

# @description Wrapper for 'pushd' command, redirects output to /dev/null.
function pushd () {
  command pushd "$@" > /dev/null
}

# @description Wrapper for 'popd' command, redirects output to /dev/null.
function popd () {
  command popd "$@" > /dev/null
}

#endregion

#region search

# @description Searches for a given pattern in all files under the current directory and prints the matched text with line numbers, highlighting occurrences of the pattern in red.
# @arg $1 string The pattern to search for.
function term {
  find "$(pwd)" -type f -print | xargs grep -n "$1" | awk -F ':' -v pattern="$1" '{gsub(pattern, "\033[1;31m&\033[0m", $3); printf "\033[1;33m%s\033[0m:%s %s\n", $1, $2, $3}'
}

# @description Searches for a given pattern in all files under the current directory, displays the matches with colors, and prints "DONE!" afterward.
# @arg $1 string The pattern to search for.
function search {
  echo "Searching for '$1' in '$(pwd)'..."
  grep -r --color=always "$1" *
  echo "DONE!"
}

#endregion

#region files

#  @description : Count lines in a file
#  @param : $1 : file name
function linecount () {
	find ./$1 -name '*.*' | xargs wc -l
}

# @description : Delete a folder from all subfolders recursively
# @param : $1 : folder name
function rrd {
  echo The following folders will be ${red} DELETED! ${reset}
  echo
  find -type d -name $1 -a -prune
  echo
  confirm && find -type d -name $1 -a -prune -exec rm -rf {} \;
}

# @description : Delete a file from all subfolders recursively
# @param : $1 : file name
function rr {
  if [ $# -ne 1 ]; then
    echo "Usage: loadenv <filename>"
    return 1
  else
    read -p "Are you sure you want to delete $1? (y/n)" answer
    if [ "$answer" == "y" ]; then
      find . -name "$1" -delete
    else
      echo "File deletion aborted."
    fi
  fi
}

#endregion

#region network
# @description Displays the IPv4 addresses of all active network interfaces.
alias ipaddr="ifconfig | grep inet | grep -v inet6 | cut -d ' ' -f2"

# @description Displays a list of processes that are listening on network ports.
alias listen="sudo lsof -i -P -n | grep LISTEN"

# @description Displays a list of open ports on the system.
function ports {
  if command -v ifconfig >/dev/null 2>&1; then
    sudo netstat -tulpn | grep LISTEN
  else
    echo "Error: ifconfig command not found. Please install ifconfig and try again." >&2
    return 1
  fi
}

# @description Displays a list of open mail-related ports on the system.
function mailports {
  if command -v ifconfig >/dev/null 2>&1; then
    netstat -tulpn | grep -E -w '25|80|110|143|443|465|587|993|995|4190'
  else
    echo "Error: ifconfig command not found. Please install ifconfig and try again." >&2
    return 1
  fi
}

# @description Displays the IPv4 addresses of the eth0 network interface.
function ips {
  if command -v ifconfig >/dev/null 2>&1; then
    ifconfig eth0 | /bin/grep 'inet' | cut -d ':' -f 2 | grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])'
  else
    echo "Error: ifconfig command not found. Please install ifconfig and try again." >&2
    return 1
  fi
}


# @description Displays the current external IP address using ifconfig.co.
function checkip {
    echo "Current External IP Address"
    curl -sb -H ifconfig.co/json | jq '.'
    echo
}

# @description Copies the current external IP address to the clipboard.
function clipip {
  tempFile=/tmp/ip.tmp
  ip=$(curl -sb -H ifconfig.co)
  echo $ip > $tempFile
  
  # Check the operating system and use the appropriate command for clipboard copying.
  if os Linux; then
    if command -v xclip &>/dev/null; then
      xclip -selection clipboard $tempFile
      echo "Copied external address $ip to the clipboard"
    else
      echo "Error: xclip command not found. Please install xclip and try again." >&2
      rm $tempFile
      return 1
    fi
  elif os Darwin; then
    if command -v pbcopy &>/dev/null; then
      pbcopy < $tempFile
      echo "Copied external address $ip to the clipboard"
    else
      echo "Error: pbcopy command not found. Please install pbcopy and try again." >&2
      rm $tempFile
      return 1
    fi
  else
    echo "Error: Unsupported operating system." >&2
    rm $tempFile
    return 1
  fi
  
  rm $tempFile
}


# @description Displays the current MAC address of all network interfaces.
function currentmac {
  echo -e "\e[1;31m"`ifconfig | awk -FHWaddr '{ print $2 }'`"\e[0m"
}


#endregion

#region git

if [ -x "$(command -v git)" ]; then
  git config --global core.editor $EDITOR
fi

# @description Pushes all branches to their respective remotes.
alias gpa="git remote | xargs -L1 git push --all"

# @description Displays the current Git repository status.
alias gs='git status'

# @description Displays a concise Git log with one line per commit.
alias glo='git log --pretty=oneline'

# @description Lists Git submodule configurations.
alias gsl='git config --list | egrep "^submodule"'

# @description Displays a Git log with commit hash, author, and subject.
alias gls='git log --pretty="format:%h %G? %aN  %s"'

# @description Initializes and updates Git submodules recursively.
alias gsi='git submodule update --init --recursive'

# @description Updates Git submodules recursively.
alias gsu='git submodule update --recursive'

# @description Performs a hard reset on all Git submodules.
alias gsr='git submodule foreach git reset --hard'

# @description Pulls changes from the remote repository.
alias gp='git pull'

# @description Fetches changes from the remote repository and prunes deleted branches.
alias gprune="git fetch -p && git branch -vv | awk '/: gone]/{print \$1}' | xargs git branch -d"

# @description Displays a colorful and graph-like Git log.
alias ggg='git log --oneline --graph --decorate --all'

# @description Displays a detailed and decorated Git log with a graph.
alias gg="git log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"

# @description Retrieves the URL of the remote repository named 'origin'.
alias grl="git remote get-url --all origin"

# @description Creates a branch and checks it out if a param is passed, otherwise lists all branches
# @example
#   gb wip
# @arg  string The name of the branch (optional)
function gb {
  if [[ -n "$1" ]]; then
    git branch $1 && git checkout $1
  else
    git branch
  fi
}

# @description Clones all repositories in an organization on Github
# @example
#   cloneorg [api-token] [organization-name]
# @arg  string github token
# @arg  string The organization name
# @arg  string The git locator (default github.com)
# @stdout Path to something.
function git-clone-org {
	connect_method="ssh_url"
	locator="github.com"
	curl -s https://$1:@api.github.com/orgs/$2/repos?per_page=200 | jq .[].$connect_method | xargs -n 1 -i echo {} | sed -e "s/$locator/$3/g" | xargs -n 1 git clone
}

# @description Pushes a release tag to the origin remote and current branch
# @example
#   gitorade v1.0.0
# @arg string The version number for the release
function gitorade {
  if [ $# -ne 1 ]; then
    echo "Usage: gitorade <version>"
    return 1
  fi
  message="Release $1"
  branch=`git branch 2> /dev/null | grep -e ^* | sed -E  s/^\\\\\*\ \(.+\)$/\\\\\\1\\ /`
  git add .
  git commit -S -m "$message"
  git push origin $branch
  git tag -a $1 -m "$message"
  git push origin --tags
}

# @description Removes a release tag from the origin remote and current branch
# @example
#   ungitorade v1.0.0
# @arg string The version number for the release
function ungitorade() {
    if [ $# -ne 1 ]; then
      echo "Usage: ungitorade <version>"
      return 1
    fi
    local tag_name=$1

    git tag -d "$tag_name"
    git push origin :refs/tags/"$tag_name"
}

# @description Logs into github with either a --global
# @example
#   cloneorg [api-token] [organization-name]
# @arg  string User name
# @arg  string User email address
# @arg  flag --g login globally
# @stdout Path to something.
function git-user {
  if [[ -n $3 ]]; then
    SCOPE="--global"
  else
    SCOPE=$3
  fi
  git config $SCOPE user.name $1
  git config $SCOPE user.email $2
}

# @description Returns the current logged in git user information
# @noargs
function git-whoami {
	echo "git logged in as \"`git config user.name` <`git config user.email`>\""
}

# @description Pulls all remote branches locally - definitely use with caution
# @noargs
function git-pull-all {
	#git branch -r | grep -v '\->' | while read remote; do git branch --track "${remote#origin/}" "$remote"; done
	git fetch --all
	git pull --all
}

function git-submodule-delete {
	sed -i ".bak" "/$1/d" .gitmodules
	git add .gitmodules
	sed -i ".bak" "/$1/d" .git/config
	git rm --cached $1
	rm -rf .git/modules/$1
	git commit -m "Removed submodule $1"
	rm -rf $1
	echo "Deleted submodule $1"
}

# @description Adds, commits, and pushes current changes with a GPG key to origin and current branch
# @arg string The commit message
function git-commit-secure {
  git add .
  git commit -S -am "$1"
  git push
}

# @description Adds, commits, and pushes current changes with a GPG key to origin and current branch
# @arg string The commit message
function gcs {
  git-commit-secure "$1"
}

# @description Adds, commits, and pushes current changes with a GPG key to origin and current branch then pushes to all remotes
# @arg string The commit message
function gcsa {
  git commit-secure "$1" && gpa
}


# @description Adds, commits, and pushes current changes WITHOUT a GPG key to origin and current branch
# @arg string The commit message
function gc {
  echo "Use the non-secure way?" && confirm
	git add .
	git commit -am "$1"
	git push
}

# @description Check if local git branches have corresponding remote branches or if remote branches were deleted.
# @example
#   checkRemoteBranches
function checkRemoteBranches {
    # Fetch the latest information from the remote repository
    git fetch -p

    # Iterate over all local branches
    for branch in $(git branch | sed 's/^[* ]//'); do
        # Check if the branch has a corresponding remote branch
        if git show-ref --quiet refs/remotes/origin/$branch; then
            echo "Branch '$branch' has a corresponding remote branch."
        else
            echo "Branch '$branch' does not have a corresponding remote branch."

            # Check if the remote branch was deleted
            if git ls-remote --exit-code origin $branch >/dev/null 2>&1; then
                echo "The remote branch for '$branch' was deleted."
            else
                echo "No information about the remote branch for '$branch'."
            fi
        fi
    done
}

# @description EXPERIMENTAL List remote branches that are not present locally in the Git repository.
# @example
#   get_local_branches_not_on_remote
function get_local_branches_not_on_remote() {
  # Get the current branch name
  local current_branch
  current_branch=$(git symbolic-ref --short HEAD)

  # Get the remote associated with the current branch
  local remote_name
  remote_name=$(git config "branch.$current_branch.remote")

  if [ -z "$remote_name" ]; then
    echo "Error: No remote associated with the current branch."
    exit 1
  fi

  # Fetch the latest changes from the remote
  git fetch "$remote_name"

  # Get a list of remote branches
  remote_branches=$(git branch -r | sed 's/^[[:space:]]*//' | sed 's/ ->.*$//')

  # Get a list of local branches
  local_branches=$(git branch | sed 's/^[[:space:]]*//' | sed 's/^* //')

  # Determine local branches not in the list of remote branches
  local_branches_not_on_remote=$(comm -23 <(echo "$local_branches" | sort) <(echo "$remote_branches" | sort | cut -d '/' -f 2-))

  # Print the list of local branches not on the remote
  if [ -z "$local_branches_not_on_remote" ]; then
    echo "All local branches are also present on $remote_name."
  else
    echo "Local branches not present on $remote_name:"
    echo "$local_branches_not_on_remote"
  fi
}

export GPG_TTY=`tty`

function git-clear {
  git pull -a > /dev/null

  local branches=$(git branch --merged | grep -v '\*' | sed 's/^\s*//' | grep -v 'main$')
  branches=(${branches//;/ })

  if [ -z $branches ]; then
    echo 'No branches to delete...'
    return;
  fi

  echo $branches

  echo 'Do you want to delete these merged branches? (y/n)'
  read yn
  case $yn in
      [^Yy]* ) return;;
  esac

  echo 'Deleting...'

  git fetch --prune
  git remote prune origin
  echo $branches | xargs -n 1 git branch -d &&
  git remote prune origin 
}

# @description Shows the history of a specific file
# @example
#   git-file-history README.md
# @arg string The file to show history for
function git-file-history {
	git log -p -- $1
}

function git-fix-commits {
  export $authors_file=author-conv-file

  git filter-branch -f --env-filter '
    get_name () {
        grep "^$1=" "$authors_file" |
            sed "s/^.*=\(.*\) <.*>$/\1/"
    }
    get_email () {
        grep "^$1=" "$authors_file" |
            sed "s/^.*=.* <\(.*\)>$/\1/"
    }
    GIT_AUTHOR_NAME=$(get_name $GIT_COMMITTER_NAME) &&
    GIT_AUTHOR_EMAIL=$(get_email $GIT_COMMITTER_NAME) &&
    GIT_COMMITTER_NAME=$GIT_AUTHOR_NAME &&
    GIT_COMMITTER_EMAIL=$GIT_AUTHOR_EMAIL &&
    export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
  ' -- --all
}

#endregion

#region docker

alias ddisk='docker run --rm -it -v /:/docker alpine:edge $@'

# @description Lists docker volumes on the current host
# @noargs
function dvol {
	ddisk ls -l /docker/var/lib/docker/volumes/
}

# @description Prompts the user for confirmation before forcefully deleting a Docker volume.
# @example
#   dvolrm my_volume - Prompts the user to confirm before forcefully removing the Docker volume "my_volume".
# @arg $1 string Name of the Docker volume to be forcefully removed.
function dvolrm {
  # Prompt the user for confirmation
  read -p "Are you sure you want to force delete the \"$1\" Docker volume? " -n 1 -r
  echo

  # Call the confirm function and then remove the volume
  confirm && docker volume rm "$1"
}

# @description Determines if the current user is logged into Dockerhub
# @noargs
function docker-logged-in {
  if [[ !  -z $(cat ~/.docker/config.json | jq ".HttpHeaders" | grep "darwin") ]]; then
    if [[ ! -z $(cat ~/.docker/config.json | jq ".credSstore") ]]; then
      echo "You are currently logged into Docker (Mac)"
    fi
  else
    if [[ ! -z $(cat ~/.docker/config.json | jq ".auths[].auth") ]]; then
      echo "You are currently logged into Docker (linux)"
    fi
  fi
}

# @description Interactively logs into a container
# This function takes two arguments:$1 represents the shell to use, and $2 represents the Docker image to run. It then uses the docker run command to start a new container with the specified image and shell. The --rm flag ensures that the container is automatically removed when it exits, and the -it flag allocates a pseudo-TTY and opens an interactive session. Finally, the --entrypoint flag specifies the shell to use inside the container.
function docker-shell {
  docker run --rm -it --entrypoint=/bin/$1 $2
}

# @description Logs in to Docker Hub using the specified username and password.
# @example
#   docker-hub-login myusername mypassword - Logs in to Docker Hub with the given credentials.
# @arg $1 string Docker Hub username.
# @arg $2 string Docker Hub password.
function docker-hub-login {
  docker login --username="$1" --password="$2"
}

# @description Executes an interactive shell in a running Docker container.
# @example
#   docker-login container_name /bin/bash - Opens an interactive shell in the specified Docker container.
# @arg $1 string Docker container name or ID.
# @arg $2 string The command to run in the container (e.g., /bin/bash).
function docker-login {
  docker exec -it "$1" "$2"
}

# @description Runs a Docker container, removing it after it stops, and opens an interactive terminal.
# @example
#   docker-run image_name - Runs a Docker container based on the specified image interactively.
# @arg $1 string Docker image name.
function docker-run {
  docker run --rm -it "$1"
}

# @description Removes exited Docker containers and dangling images.
# @example
#   docker-clean - Removes all exited containers and dangling images.
# @arg None.
function docker-clean {
  docker rm -v $(docker ps -a -q -f status=exited)
  docker rmi $(docker images -f "dangling=true" -q)
}

# @description Opens an interactive shell in a running Docker container with an optional custom application.
# @example
#   docker-shell-app container_name /path/to/custom/app - Opens an interactive shell in the specified container
#   running the custom application. If no application is provided, it defaults to /bin/bash.
# @arg $1 string Docker container name or ID.
# @arg $2 string (Optional) The custom application to run in the container.
function docker-shell-app {
  app="/bin/bash"
  if [ ! -z "$2" ]; then
    app="$2"
  fi
  echo "[+] Running $app in container $1"
  docker exec -it "$1" "$app"
}

# @description Removes all stopped containers and all images.
# @example
#   docker-deep-clean - Prunes stopped containers and removes all Docker images.
# @arg None.
function docker-deep-clean {
  docker container prune -f
  docker rmi $(docker images -q)
}

# @description Stops all running Docker containers.
# @example
#   docker-stop - Stops all running Docker containers.
# @arg None.
function docker-stop {
  docker stop $(docker ps -q)
}


# @description Removes all cached docker images by name
# @example
#   dockerrmi nginx - Removes any image with "NGINX" in the name
# @arg $1 string Name or partial name to match
function docker-rmi {
	docker rmi $(docker images --format '{{.Repository}}:{{.Tag}}' | grep $1)
}

# @description Short alias for 'docker'.
alias d="docker"

# @description Short alias for '_ds'.
alias ds="_ds"

# @description Short alias for opening Dockerfile with the default editor.
alias de='${EDITOR} Dockerfile'

# @description Short alias for 'docker ps -l -q'.
alias dl='docker ps -l -q'

# @description Short alias for 'docker image list'.
alias dli='d image list'

# @description Short alias for stopping and removing the last container started.
alias dkl='d kill `dl` && docker rm `dl`'

# @description Short alias for interactively logging in to the last container started.
alias dil='docker exec -it $(docker ps -q -l) bash || docker exec -it $(docker ps -q -l) sh'

# @description Short alias for stopping the last container started.
alias dsl='docker stop $(docker ps -q -l)'

# @description Short alias for 'docker -shell-app'.
alias dsh='d -shell-app'

# @description Short alias for viewing logs of the last container started.
alias dlog='d logs -f `dl`'

# @description Short alias for removing all exited Docker containers.
alias dcc='d ps -a -q -f status=exited | xargs L1 docker rm -v'

# @description Short alias for removing all local Docker images.
alias dci='d rmi $(docker images -q) --force'

# @description Short alias for 'docker ps'.
alias dps='d ps'

# @description Short alias for 'docker -run'.
alias dr='d -run'

# @description Short alias for stopping all Docker containers.
alias dsa='docker stop $(docker ps -a -q)'

# @description Short alias for removing all Docker containers.
alias drma='docker rm $(docker ps -aq)'

# @description Short alias for updating all local Docker images.
alias diu='docker images | awk `{print $1}` | xargs -L1 docker pull'

# @description Short alias for 'docker-compose up -d'.
alias up='docker-compose up -d'

# @description Short alias for 'docker-compose down'.
alias down='docker-compose down'


#endregin

#region kubernetes

alias k="kubectl"

# @description Retrieves the authentication token for accessing the Kubernetes Dashboard.
# @example
#   kube-dashboard-token - Displays the authentication token for the Kubernetes Dashboard.
# @arg None.
function kube-dashboard-token {
  kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
}

#endregion

#region text

# @description Trims a specified number of characters from the end of a string.
# @example
#   trim-end "example" 3 - Trims 3 characters from the end of the string "example".
# @arg $1 string The input string.
# @arg $2 integer The number of characters to trim from the end.
function trim-end {
  echo -e  "$1" | sed "s/.{\$2}$//"
}

# @description Displays unique lines from a file, ignoring case.
# @example
#   unique-lines input.txt - Displays unique lines from the file "input.txt".
# @arg $1 string The path to the input file.
function unique-lines {
  cat "$1" | sort -rn | uniq -u
}

# @description Cleans accents from directory names.
# @example
#   clean-accents-dirs - Cleans accents from directory names.
function clean-accents-dirs {
  find . -type d | tac | while IFS= read -r d; do 
    d_clean=$(echo "$d" | iconv -c -f utf8 -t ascii)
    if [ "$d" = "$d_clean" ]
    then
      :
    else
      echo "[${orange}>${reset}] Moving $d to $d_clean..."
      echo "[${green}*${reset}] mv -n \"$d\" \"$d_clean\" "
    fi
  done
}

# @description Cleans accents from file names.
# @example
#   clean-accents-files - Cleans accents from file names.
function clean-accents-files {
  find . -name "*" | while IFS= read -r f; do 
    f_clean=$(echo "$f" | iconv -c -f utf8 -t ascii)
    if [ "$f" = "$f_clean" ]
    then
      :
    else
      echo "[${orange}>${reset}] Moving $f to $f_clean..."
      echo "[${green}*${reset}] mv -n \"$f\" \"$f_clean\" "
    fi
  done
}

# @description Cleans accents from both directory and file names.
# @example
#   clean-accents - Cleans accents from both directory and file names.
function clean-accents {
  clean-accents-dirs
  clean-accents-files
}

# @description Replaces spaces with line breaks in a file.
# @example
#   spaces-to-breaks input.txt - Replaces spaces with line breaks in the file "input.txt".
# @arg $1 string The path to the input file.
function spaces-to-breaks {
  tr ' ' '\n' < "$1"
}


#endregion

#region services

# @description Displays boot logs using journalctl or notifies that the function is not available on Darwin.
# @example
#   boot-log - Displays boot logs on Linux using journalctl.
function boot-log {
	if ! os Darwin; then
		journalctl _PID=1
    return
	fi 
	notavailable ${FUNCNAME[0]}
}

# @description Lists all available systemd services or notifies that the function is not available on Darwin.
# @example
#   service-list - Lists all available systemd services on Linux.
function service-list {
	if ! os Darwin; then
		systemctl list-unit-files
	fi 
	notavailable ${FUNCNAME[0]}
}

# @description Displays the time taken by each service during startup using systemd-analyze blame or notifies that the function is not available on Darwin.
# @example
#   service-long-start - Displays the time taken by each service during startup on Linux.
function service-long-start {
	if ! os Darwin; then
		systemd-analyze blame
	fi 
	notavailable ${FUNCNAME[0]}
}

# @description Displays the contents of a systemd service file using systemctl cat or notifies that the function is not available on Darwin.
# @example
#   service-cat service_name - Displays the contents of a systemd service file on Linux.
# @arg $1 string The name of the systemd service.
function service-cat {
	if ! os Darwin; then
		systemctl cat "$1"
	fi 
	notavailable ${FUNCNAME[0]}
}

# @description Lists all running systemd services using systemctl list-units or notifies that the function is not available on Darwin.
# @example
#   service-list-systemd - Lists all running systemd services on Linux.
function service-list-systemd {
	if ! os "Darwin"; then
		systemctl list-units --type service
	fi 
	notavailable ${FUNCNAME[0]}
}

# @description Lists all enabled systemd services using systemctl list-units or notifies that the function is not available on Darwin.
# @example
#   service-list-enabled - Lists all enabled systemd services on Linux.
function service-list-enabled {
	if ! os "Darwin"; then
    systemctl list-units --type service | grep enabled
	fi 
	notavailable ${FUNCNAME[0]}
}

# @description Displays the status of a systemd service using systemctl status or notifies that the function is not available on Darwin.
# @example
#   service-status service_name - Displays the status of a systemd service on Linux.
# @arg $1 string The name of the systemd service.
function service-status {
	#$1 is the name of the service
	if ! os "Darwin"; then
		systemctl status "$1"
	fi 
	notavailable ${FUNCNAME[0]}
}

# @description Checks if a systemd service is active using systemctl is-active or notifies that the function is not available on Darwin.
# @example
#   service-isactive service_name - Checks if a systemd service is active on Linux.
# @arg $1 string The name of the systemd service.
function service-isactive {
	#$1 is the name of the service
	if ! os "Darwin"; then
		systemctl is-active "$1"
	fi 
	notavailable ${FUNCNAME[0]}
}

# @description Checks if a systemd service is enabled using systemctl is-enabled or notifies that the function is not available on Darwin.
# @example
#   service-isenabled service_name - Checks if a systemd service is enabled on Linux.
# @arg $1 string The name of the systemd service.
function service-isenabled {
	#$1 is the name of the service
	if ! os "Darwin"; then
		systemctl is-enabled "$1"
	fi 
	notavailable ${FUNCNAME[0]}
}

# @description Edits a systemd service file using micro or notifies that the function is not available on Darwin.
# @example
#   service-edit service_name - Edits a systemd service file on Linux.
# @arg $1 string The name of the systemd service (no extension).
function service-edit {
	#$1 is the name of the service (no extension)
	if ! os "Darwin"; then
		micro "/etc/systemd/system/$1.service"
	fi 
	notavailable ${FUNCNAME[0]}
}

# @description Restarts a systemd service using systemctl restart or notifies that the function is not available on Darwin.
# @example
#   service-restart service_name - Restarts a systemd service on Linux.
# @arg $1 string The name of the systemd service (no extension).
function service-restart {
	#$1 is the name of the service (no extension)
	if ! os "Darwin"; then
		systemctl restart "$1.service"
	fi 
	notavailable ${FUNCNAME[0]}
}

#endregion

#region web

# @description Downloads a website for offline viewing using wget with mirroring.
# @example
#   webvacuum http://example.com - Downloads the website at "http://example.com" for offline viewing.
# @arg $1 string The URL of the website to be downloaded.
function webvacuum {
  wget --mirror         \
    --convert-links     \
    --html-extension    \
    --wait=2            \
    -o log              \
    $1
}

#endregion

#region colors

# @description Generates a color table for 16 million RGB colors using ANSI escape codes.
# @example
#   color-table-rgb 3 - Generates a foreground color table for 16 million RGB colors.
#   color-table-rgb 4 - Generates a background color table for 16 million RGB colors.
# @arg $1 integer 3 or 4 (foreground or background).
function color-table-rgb {
  echo
  echo 'Mode 2 Color Table'
  echo '------------------'
  echo 
  echo 'Parameters are 3 or 4 (foreground or background)'
  echo "Some samples of colors for r;g;b. Each one may be 000..255"
  echo

  # foreground or background (only 3 or 4 are accepted)
  local fb="$1"
  [[ $fb != 3 ]] && fb=4

  local samples=(0 63 127 191 255)
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
# @example
#   color 123 - Displays ANSI color 123.
# @arg $c integer ANSI color code.
function color {
  for c; do
    printf '\e[48;5;%dm%03d' "$c" "$c"
  done
  printf '\e[0m \n'
}

# @description Generates a color table using ANSI escape codes.
# @example
#   color-table - Generates a color table using ANSI escape codes.
function color-table {
  # nosemgrep: bash.lang.security.ifs-tampering.ifs-tampering
  IFS=$' \t\n'
  color {0..15}
  for ((i=0; i<6; i++)); do
    color $(seq $((i*36+16)) $((i*36+51)))
  done
  color {232..255}
}


#endregion

#region mac specific

if os Darwin; then
	# @description Shows hidden files in Finder.
  # @example
  #   show-files - Enables the display of hidden files in Finder.
  alias show-files='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app'

  # @description Hides hidden files in Finder.
  # @example
  #   hide-files - Disables the display of hidden files in Finder.
  alias hide-files='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app'

  # @description Hides desktop icons in Finder.
  # @example
  #   hide-desktop-icons - Hides all desktop icons in Finder.
  alias hide-desktop-icons='defaults write com.apple.finder CreateDesktop FALSE && killall Finder'

  # @description Shows desktop icons in Finder.
  # @example
  #   show-desktop-icons - Displays all desktop icons in Finder.
  alias show-desktop-icons='defaults write com.apple.finder CreateDesktop TRUE && killall Finder'

  # @description Flushes DNS cache.
  # @example
  #   flushdns - Flushes the DNS cache.
  alias flushdns='sudo killall -HUP mDNSResponder;sudo killall mDNSResponderHelper;sudo dscacheutil -flushcache'

  # @description Sets the desktop wallpaper.
  # @example
  #   set-wallpaper wallpaper.jpg - Sets the desktop wallpaper to the specified image file.
  # @arg $1 string The name of the image file for the wallpaper.
  function set-wallpaper {
    osascript -e 'tell application "Finder" to set desktop picture to POSIX file "$(pwd)/$1"'
  }

fi

#endregion


#region AWS

function list-instances {
  echo -e "Searching current region for instances in the $1 environment..."
  aws ec2 describe-instances --filters Name=instance-state-name,Values=running Name=env,Values=*$1* --query "Reservations[*].Instances[*].InstanceId" --output text
}

#endregion

#load private aliases if available
if [ -f ~/.bash_private_aliases ]; then
    . ~/.bash_private_aliases
fi

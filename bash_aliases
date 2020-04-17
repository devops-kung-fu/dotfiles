#!/bin/bash

export PS1="\[\033[38;5;14m\]\u\[$(tput sgr0)\]\[\033[38;5;15m\]@\[$(tput sgr0)\]\[\033[38;5;2m\]\h\[$(tput sgr0)\]\[\033[38;5;15m\]:\[$(tput sgr0)\]\[\033[38;5;11m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]\\$ \[$(tput sgr0)\]"
export LSCOLORS=ExfxcxdxBxegedabagacad
export CLICOLOR=1

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

function notavailable {
  echo "$1 not available on `lowercase \`uname\``"
}

function progressbar {
  local w=80 p=$1;  shift
  # create a string of spaces, then change them to dots
  printf -v dots "%*s" "$(( $p*$w/100 ))" ""; dots=${dots// /.};
  # print those dots on a fixed-width space plus the percentage etc. 
  printf "\r\e[K|%-*s| %3d %% %s" "$w" "$dots" "$p" "$*"; 
}

function lowercase(){
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

function os {
  INSTALLEDOS=`lowercase \`uname\``
  PASSEDOS=`lowercase $1`

  if [[ $INSTALLEDOS == $PASSEDOS ]]; then
      return 0
  fi
  return 1
}

function exists {
  if [ -x "$(command -v $1)" ]; then
    return 0
  fi
  return 1
}

function waitsec {
  secs=$1 #$(($1 * 60))
  while [ $secs -gt 0 ]; do
    printf "Waiting: $secs \033[0K\r"
    sleep 1
    : $((secs--))
  done
}

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

function aliases { # Show a list of functions and aliases
  aliases=$(grep "^function" ~/.bash_aliases | awk '{print $2}')
  echo $aliases
}

function clip {
  if os Darwin; then
    cat $1 | pbcopy
  fi
}

function clippwd {
  if os Darwin; then
    echo `pwd` |  pbcopy
  fi
}

#endregion

#region navigation

alias ..="cd .."
alias ....="cd ../../"
alias ......="cd ../../../"

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

alias cdb="cd -"
alias cdh='cd ~/'
alias h='cd ~/'

if [ $UID -ne 0 ]; then
  alias reboot='sudo reboot'
fi

function pushd () {
  command pushd "$@" > /dev/null
}

function popd () {
  command popd "$@" > /dev/null
}

#endregion

#region search

function term {
  find `pwd` -type f -print | xargs grep -o $1
}

function search {
  echo "Searching for '$1' in '`pwd`'..."
  grep -s --directories recurse --color=always $1 *
  echo "DONE!"
}

#endregion

#region files

function linecount () {
	find ./$1 -name '*.*' | xargs wc -l
}

function rmrecurdir {
  echo The following folders will be ${red} DELETED! ${reset}
  echo
  find -type d -name $1 -a -prune
  echo
  confirm && find -type d -name $1 -a -prune -exec rm -rf {} \;
}

function rr {
  if [ $# -ne 1 ]; then
    echo "rr - Removes files recursively"
    echo "Usage: rr filename"
  else
    find . -name "$1" -delete
  fi
}

#endregion

#region network

alias ipaddr="ifconfig | grep inet | grep -v inet6 | cut -d ' ' -f2"
alias listen="sudo lsof -i -P -n | grep LISTEN"

if os Linux; then
  alias ports='sudo netstat -tulpn | grep LISTEN'
  alias mailports="netstat -tulpn | grep -E -w '25|80|110|143|443|465|587|993|995|4190'"
  alias ips="/sbin/ifconfig eth0 | /bin/grep 'inet' | /usr/bin/cut -d ':' -f 2 | grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])'"
fi

function checkip {
    echo "Current External IP Address"
    curl -sb -H ifconfig.co/json | jq '.'
    echo
}

function clipip {
  tempFile=/tmp/ip.tmp
  ip=$(curl -sb -H ifconfig.co)
  echo $ip > $tempFile
  clip $tempFile
  echo "Copied external address $ip to the clipboard"
  rm $tempFile
}

function currentmac {
    echo -e "\e[1;31m"`ifconfig | awk -FHWaddr '{ print $2 }'`"\e[0m"
}

#endregion

#region git

if [ -x "$(command -v git)" ]; then
  git config --global core.editor $EDITOR
fi

alias gs='git status'
alias gb='git branch'
alias glo='git log --pretty=oneline'
alias gsl='git config --list|egrep ^submodule'
alias gls='git log --pretty="format:%h %G? %aN  %s"'
alias gsi='git submodule update --init --recursive'
alias gsu='git submodule update --recursive'
alias gsr='git submodule foreach git reset --hard'
alias gp='git pull'
alias gprune="git fetch -p && git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -d"
alias ggg='git log --oneline --graph --decorate --all'
alias gg="git log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all"
alias grl="git remote get-url --all origin"

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
function git-whoami {
	echo "git logged in as \"`git config user.name` <`git config user.email`>\""
}

function git-pull-all {
	git branch -r | grep -v '\->' | while read remote; do git branch --track "${remote#origin/}" "$remote"; done
	git fetch --all
	git pull --all
}

function git-rmtag {
  if [ $# -ne 1 ]; then
    echo Usage: $0 {tag}
  else
    echo Removing tag $1
    git tag -d $1
    git push origin :refs/tags/$1
  fi
}

function git-retag {
  TAG=`git describe --abbrev=0 --tags`
  git tag -d $TAG
  git push origin :refs/tags/$TAG
  git tag $TAG
  git push --tags
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

function git-commit-secure {
  git pull
  git add .
  git commit -S -am "$1"
  git push
}

function gcs {
  git-commit-secure $1
}

function gc {
  echo "Use the non-secure way?" && confirm
	git add .
	git commit -am "$1"
	git push
	# for remote in $(git remote);
    # do git push $remote master;
	# done
}

function git-clear {
  git pull -a > /dev/null

  local branches=$(git branch --merged | grep -v 'develop' | grep -v 'master' | grep -v 'qa' | sed 's/^\s*//')
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

  git remote prune origin
  echo $branches | xargs git branch -d
  git branch -vv
}

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

function dvolrm {
	read -p "Are you sure you want to force delete the \"$1\" docker volume? " -n 1 -r
	echo
  confirm && docker volume rm $1
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

function docker-shell {
  SHELL=$1
  IMAGE=$2
  docker run --rm -it --entrypoint=/bin/$SHELL $2
}

function docker-hub-login {
  docker login --username=$1 --password=$2
}

function docker-login {
	docker exec -it $1 $2
}

function docke-run {
	docker run --rm -it $1
}

function docker-clean {
	$(docker ps -a -q -f status=exited) | xargs L1 docker rm -v
	$(docker images -f "dangling=true" -q) | xargs L1 docker rmi
}

function docker-shell-app {
  app="/bin/bash"
  if [ ! -z "$2" ]; then
    app=$2
  fi
  echo "[+] Running $app in container $1"
  docker exec -it $1 $app
}

function docker-deep-clean {
	# Delete every Docker containers
	# Must be run first because images are attached to containers
	docker rm $(docker ps -a -q)

	# Delete every Docker image
	docker rmi $(docker images -q)
}

function docker-stop {
  echo $(docker ps -a -q -f status=running) | xargs docker stop
  echo $(docker ps -a -q -f status=exited) | xargs docker rm
}

# @description Removes all cached docker images by name
# @example
#   dockerrmi nginx - Removes any image with "NGINX" in the name
# @arg $1 string Name or partial name to match
function docker-rmi {
	docker rmi $(docker images --format '{{.Repository}}:{{.Tag}}' | grep $1)
}

alias d="docker"
alias ds="_ds"
alias de='${EDITOR} Dockerfile'
alias dl='d ps -l -q'
alias li='d image list'
alias dkl='d kill `dl` && docker rm `dl`'
alias dil='d exec -it `dl` bash'
alias dsh='d -shell-app'
alias dlog='d logs -f `dl`'
alias dcc='d ps -a -q -f status=exited | xargs L1 docker rm -v'
alias dci='d rmi $(docker images -q) --force'
alias dps='d ps'
alias dr='d -run'

alias dsa='d stop $(d ps -a -q)'
alias drma='d rm $(d ps -aq)'
alias diu='d images | awk `{print $1}` | xargs -L1 docker pull'
alias up='docker-compose up -d'
alias down='docker-compose down'

#endregin

#region kubernetes

alias k="kubectl"

function kube-dashboard-token {
  kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
}

#endregion

#region text

function trim-end {
  echo -e  $1 | sed 's/.\{"$2"\}$//'
}

function unique-lines {
  cat $1 | sort -rn | uniq -u
}

function clean-accents-dirs {
  find . -type d | tail -r | while IFS= read -r d; do 
    d_clean=`echo $d | iconv -c -f utf8 -t ascii`
    if [ "$d" = "$d_clean" ]
    then
      :
    else
      echo "[${orange}>${reset}] Moving $d to $d_clean..."
      echo "[${green}*${reset}] mv -n \"$d\" \"$d_clean\" "
    fi
  done
}

function clean-accents-files {
  find . -name "*" | while IFS= read -r f; do 
    f_clean=`echo $f | iconv -c -f utf8 -t ascii`
    if [ "$f" = "$f_clean" ]
    then
      :
    else
      echo "[${orange}>${reset}] Moving $f to $f_clean..."
      echo "[${green}*${reset}] mv -n \"$f\" \"$f_clean\" "
    fi
  done
}

function clean-accents {
  cleanaccentsdirs
  cleanaccentsfiles
}

function spaces-to-breaks {
  tr ' ' '\n' < $1
}

#endregion

#region services

function boot-log {
	if ! os Darwin ]]; then
		journalctl _PID=1
    return
	fi 
	notavailable ${FUNCNAME[0]}
}

function service-list {
	if ! os Darwin; then
		systemctl list-unit-files
	fi 
	notavailable ${FUNCNAME[0]}
}

function service-long-start {
	if ! os Darwin; then
		systemd-analyze blame
	fi 
	notavailable ${FUNCNAME[0]}
}

function service-list-systemd {
	if ! os "Darwin"; then
		systemctl list-units --type service
	fi 
	notavailable ${FUNCNAME[0]}
}

function service-list-enabled {
	if ! os "Darwin"; then
    systemctl list-units --type service | grep enabled
	fi 
	notavailable ${FUNCNAME[0]}
}

function service-status {
	#$1 is the name of the service
	if ! os "Darwin"; then
		systemctl status $1
	fi 
	notavailable ${FUNCNAME[0]}
}

function service-isactive {
	#$1 is the name of the service
	if ! os "Darwin"; then
		systemctl is-active $1
	fi 
	notavailable ${FUNCNAME[0]}
}

function service-isenabled {
	#$1 is the name of the service
	if ! os "Darwin"; then
		systemctl is-enabled $1
	fi 
	notavailable ${FUNCNAME[0]}
}

function service-edit {
	#$1 is the name of the service (no extension)
	if ! os "Darwin"; then
		micro /etc/systemd/system/$1.service
	fi 
	notavailable ${FUNCNAME[0]}
}

function service-restart {
	#$1 is the name of the service (no extension)
	if ! os "Darwin"; then
		systemctl restart $1.service
	fi 
	notavailable ${FUNCNAME[0]}
}

#endregion

#region web

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

function color-table-rgb {

  #### For 16 Million colors use \e[0;38;2;R;G;Bm each RGB is {0..255}
  echo
  echo 'Mode 2 Color Table'
  echo '------------------' && echo
  echo 
  echo 'Parameters are 3 or 4 (foreground or background)'
  #printf '\e[mR'
  echo "Some samples of colors for r;g;b. Each one may be 000..255"
  echo '\e[m%59s\n' "for the ansi option: \e[0;38;2;r;g;bm or \e[0;48;2;r;g;bm :"
  echo

  # foreground or background (only 3 or 4 are accepted)
  local fb="$1"
  [[ $fb != 3 ]] && fb=4
  local samples=(0 63 127 191 255)
  for         r in "${samples[@]}"; do
      for     g in "${samples[@]}"; do
          for b in "${samples[@]}"; do
              printf '\e[0;%s8;2;%s;%s;%sm%03d;%03d;%03d ' "$fb" "$r" "$g" "$b" "$r" "$g" "$b"
          done; printf '\e[m\n'
      done; printf '\e[m'
  done; echo # && printf 'e[m' && echo
}

function color {
  for c; do
    printf '\e[48;5;%dm%03d' $c $c
  done
  printf '\e[0m \n'
}

function color-table {
	IFS=$' \t\n'
	color {0..15}
	for ((i=0;i<6;i++)); do
    color $(seq $((i*36+16)) $((i*36+51)))
	done
	color {232..255}
}

#endregion

#region mac specific

if os Darwin; then
	alias show-files='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app'
	alias hide-files='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app'
	alias hide-desktop-icons='defaults write com.apple.finder CreateDesktop FALSE && killall Finder'
	alias show-desktop-icons='defaults write com.apple.finder CreateDesktop TRUE && killall Finder'
  alias flushdns='sudo killall -HUP mDNSResponder;sudo killall mDNSResponderHelper;sudo dscacheutil -flushcache'

	function set-wallpaper {
    osascript -e 'tell application "Finder" to set desktop picture to POSIX file "$(pwd)/$1"'
	}

  function xagree {
      sudo xcodebuild -license
  }

fi

#endregion

#load private aliases if available
if [ -f ~/.bash_private_aliases ]; then
    . ~/.bash_private_aliases
fi

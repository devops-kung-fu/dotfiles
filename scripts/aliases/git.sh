#!/bin/bash

#region git
if [ -x "$(command -v git)" ]; then
  git config --global core.editor "$EDITOR"
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
function gprune {
  git fetch -p
  git branch -vv | awk '/: gone]/{print $1}' | xargs -r git branch -d
}

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
    git branch "$1" && git checkout "$1"
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
  local token="$1"
  local org="$2"
  local host_override="${3:-github.com}"
  local connect_method="ssh_url"

  curl -s "https://${token}:@api.github.com/orgs/${org}/repos?per_page=200" \
    | jq -r ".[] | .${connect_method}" \
    | sed -e "s#github.com#${host_override}#g" \
    | xargs -r -I{} git clone {}
}


# @description Pushes a release tag to the origin remote and current branch
# @example
#   gitorade v1.0.0
# @arg string The version number for the release
function gitorade {
  if [[ $# -ne 1 ]]; then
    echo "Usage: gitorade <version>"
    return 1
  fi
  local message="Release $1"
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  git add .
  git commit -S -m "$message"
  git push origin "$branch"
  git tag -a "$1" -m "$message"
  git push origin --tags
}

# @description Removes a release tag from the origin remote and current branch
# @example
#   ungitorade v1.0.0
# @arg string The version number for the release
function ungitorade {
    if [[ $# -ne 1 ]]; then
      echo "Usage: ungitorade <version>"
      return 1
    fi
    local tag_name=$1

    git tag -d "$tag_name"
    git push origin :refs/tags/"$tag_name"
}

# @description Logs into github with either a --global
# @example
#   git-user "Example" example@example.com --g
# @arg  string User name
# @arg  string User email address
# @arg  flag --g login globally
# @stdout Path to something.
function git-user {
  local scope=$3
  if [[ -n $3 ]]; then
    scope="--global"
  fi

  if [[ -n $scope ]]; then
    git config "$scope" user.name "$1"
    git config "$scope" user.email "$2"
  else
    git config user.name "$1"
    git config user.email "$2"
  fi
}

# @description Returns the current logged in git user information
# @noargs
function git-whoami {
  echo "git logged in as \"$(git config user.name) <$(git config user.email)>\""
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
  git rm --cached "$1"
  rm -rf ".git/modules/$1"
  git commit -m "Removed submodule $1"
  rm -rf "$1"
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
  git-commit-secure "$1" && gpa
}

# @description Adds, commits, and pushes current changes WITHOUT a GPG key to origin and current branch
# @arg string The commit message
function gc {
  git add .
  git commit -am "$1"
  git push
}

# @description Check if local git branches have corresponding remote branches or if remote branches were deleted.
# @example
#   checkRemoteBranches
function checkRemoteBranches {
  git fetch -p
  local branch
  for branch in $(git branch | sed 's/^[* ]//'); do
    if git show-ref --quiet "refs/remotes/origin/$branch"; then
        echo "Branch '$branch' has a corresponding remote branch."
    else
        echo "Branch '$branch' does not have a corresponding remote branch."
        if git ls-remote --exit-code origin "$branch" >/dev/null 2>&1; then
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
function get_local_branches_not_on_remote {
  local current_branch
  current_branch=$(git symbolic-ref --short HEAD)

  local remote_name
  remote_name=$(git config "branch.$current_branch.remote")

  if [[ -z "$remote_name" ]]; then
    echo "Error: No remote associated with the current branch."
    exit 1
  fi

  git fetch "$remote_name"

  local remote_branches
  remote_branches=$(git branch -r | sed 's/^[[:space:]]*//' | sed 's/ ->.*$//')

  local local_branches
  local_branches=$(git branch | sed 's/^[[:space:]]*//' | sed 's/^* //')

  local local_branches_not_on_remote
  local_branches_not_on_remote=$(comm -23 <(echo "$local_branches" | sort) <(echo "$remote_branches" | sort | cut -d '/' -f 2-))

  if [[ -z "$local_branches_not_on_remote" ]]; then
    echo "All local branches are also present on $remote_name."
  else
    echo "Local branches not present on $remote_name:"
    echo "$local_branches_not_on_remote"
  fi
}

function git-clear {
  git pull -a > /dev/null

  local branches
  mapfile -t branches < <(git branch --merged | grep -v '\*' | sed 's/^\s*//' | grep -v 'main$')

  if [[ ${#branches[@]} -eq 0 ]]; then
    echo 'No branches to delete...'
    return
  fi

  printf '%s\n' "${branches[@]}"

  echo 'Do you want to delete these merged branches? (y/n)'
  read -r yn
  case $yn in
      [Yy]*) ;;
      *) return;;
  esac

  echo 'Deleting...'

  git fetch --prune
  git remote prune origin
  printf '%s\n' "${branches[@]}" | xargs -r -n 1 git branch -d
  git remote prune origin 
}

# @description Shows the history of a specific file
# @example
#   git-file-history README.md
# @arg string The file to show history for
function git-file-history {
  git log -p -- "$1"
}

function git-fix-commits {
  local authors_file="author-conv-file"
  export authors_file

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

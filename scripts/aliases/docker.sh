#!/bin/bash

#region docker
# @description Runs alpine:edge with host root mounted, forwarding args.
function ddisk {
  docker run --rm -it -v /:/docker alpine:edge "$@"
}

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
  read -r -p "Are you sure you want to force delete the \"$1\" Docker volume? " -n 1
  echo
  confirm && docker volume rm "$1"
}

# @description Determines if the current user is logged into Dockerhub
# @noargs
function docker-logged-in {
  local config="$HOME/.docker/config.json"
  if [[ ! -f "$config" ]]; then
    echo "Docker config not found: $config" >&2
    return 1
  fi

  if jq -re '.HttpHeaders // ""' "$config" | grep -qi darwin; then
    if jq -e '.credSstore' "$config" >/dev/null 2>&1; then
      echo "You are currently logged into Docker (Mac)"
    fi
  elif jq -e '.auths[].auth' "$config" >/dev/null 2>&1; then
    echo "You are currently logged into Docker (Linux)"
  fi
}

# @description Interactively logs into a container
# @arg $1 string The shell to use
# @arg $2 string The Docker image to run
function docker-shell {
  local shell_name="${1:-bash}"
  local image="${2:?Docker image is required}"
  docker run --rm -it --entrypoint="/bin/${shell_name}" "$image"
}

# @description Logs in to Docker Hub using the specified username and password.
# @arg $1 string Docker Hub username.
# @arg $2 string Docker Hub password.
function docker-hub-login {
  docker login --username="$1" --password="$2"
}

# @description Executes an interactive shell in a running Docker container.
# @arg $1 string Docker container name or ID.
# @arg $2 string The command to run in the container (e.g., /bin/bash).
function docker-login {
  docker exec -it "$1" "$2"
}

# @description Runs a Docker container, removing it after it stops, and opens an interactive terminal.
# @arg $1 string Docker image name.
function docker-run {
  docker run --rm -it "$1"
}

# @description Removes exited Docker containers and dangling images.
function docker-clean {
  docker ps -a -q -f status=exited | xargs -r docker rm -v
  docker images -f "dangling=true" -q | xargs -r docker rmi
}

# @description Opens an interactive shell in a running Docker container with an optional custom application.
# @arg $1 string Docker container name or ID.
# @arg $2 string (Optional) The custom application to run in the container.
function docker-shell-app {
  local app="/bin/bash"
  if [[ -n "$2" ]]; then
    app="$2"
  fi
  echo "[+] Running $app in container $1"
  docker exec -it "$1" "$app"
}

# @description Removes all stopped containers and all images.
function docker-deep-clean {
  docker container prune -f
  docker images -q | xargs -r docker rmi
}

# @description Stops all running Docker containers.
function docker-stop {
  docker ps -q | xargs -r docker stop
}

# @description Removes all cached docker images by name
# @arg $1 string Name or partial name to match
function docker-rmi {
  docker images --format '{{.Repository}}:{{.Tag}}' | grep -F -- "$1" | xargs -r docker rmi
}

# @description Bulk pulls each listed Docker image once.
function diu {
  docker images | awk '{print $1}' | xargs -r -L1 docker pull
}

alias d="docker"
alias ds="_ds"
alias de='${EDITOR} Dockerfile'
alias dl='docker ps -l -q'
alias dli='d image list'
alias dkl='docker kill $(docker ps -l -q) && docker rm $(docker ps -l -q)'
alias dil='docker exec -it $(docker ps -q -l) bash || docker exec -it $(docker ps -q -l) sh'
alias dsl='docker stop $(docker ps -q -l)'
alias dsh='docker-shell-app'
alias dlog='docker logs -f $(docker ps -l -q)'
alias dcc='d ps -a -q -f status=exited | xargs -r docker rm -v'
alias dci='d rmi $(docker images -q) --force'
alias dps='d ps'
alias dr='docker-run'
alias dsa='docker stop $(docker ps -a -q)'
alias drma='docker rm $(docker ps -aq)'
alias up='docker-compose up -d'
alias down='docker-compose down'
#endregion

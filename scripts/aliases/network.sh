#!/bin/bash

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
  local tempFile=/tmp/ip.tmp
  local ip
  ip=$(curl -sb -H ifconfig.co)
  echo "$ip" > "$tempFile"

  if os Linux; then
    if command -v xclip &>/dev/null; then
      xclip -selection clipboard "$tempFile"
      echo "Copied external address $ip to the clipboard"
    else
      echo "Error: xclip command not found. Please install xclip and try again." >&2
      rm "$tempFile"
      return 1
    fi
  elif os Darwin; then
    if command -v pbcopy &>/dev/null; then
      pbcopy < "$tempFile"
      echo "Copied external address $ip to the clipboard"
    else
      echo "Error: pbcopy command not found. Please install pbcopy and try again." >&2
      rm "$tempFile"
      return 1
    fi
  else
    echo "Error: Unsupported operating system." >&2
    rm "$tempFile"
    return 1
  fi

  rm "$tempFile"
}

# @description Displays the current MAC address of all network interfaces.
function currentmac {
  local macs
  macs=$(ifconfig | awk -FHWaddr '{ print $2 }')
  echo -e "\e[1;31m${macs}\e[0m"
}
#endregion

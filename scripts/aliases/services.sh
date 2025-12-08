#!/bin/bash

#region services
# @description Displays boot logs using journalctl or notifies that the function is not available on Darwin.
function boot-log {
  if ! os Darwin; then
    journalctl _PID=1
    return
  fi
  notavailable "${FUNCNAME[0]}"
}

# @description Lists all available systemd services or notifies that the function is not available on Darwin.
function service-list {
  if ! os Darwin; then
    systemctl list-unit-files
    return
  fi
  notavailable "${FUNCNAME[0]}"
}

# @description Displays the time taken by each service during startup using systemd-analyze blame or notifies that the function is not available on Darwin.
function service-long-start {
  if ! os Darwin; then
    systemd-analyze blame
    return
  fi
  notavailable "${FUNCNAME[0]}"
}

# @description Displays the contents of a systemd service file using systemctl cat or notifies that the function is not available on Darwin.
# @arg $1 string The name of the systemd service.
function service-cat {
  if ! os Darwin; then
    systemctl cat "$1"
    return
  fi
  notavailable "${FUNCNAME[0]}"
}

# @description Lists all running systemd services using systemctl list-units or notifies that the function is not available on Darwin.
function service-list-systemd {
  if ! os Darwin; then
    systemctl list-units --type service
    return
  fi
  notavailable "${FUNCNAME[0]}"
}

# @description Lists all enabled systemd services using systemctl list-units or notifies that the function is not available on Darwin.
function service-list-enabled {
  if ! os Darwin; then
    systemctl list-units --type service | grep enabled
    return
  fi
  notavailable "${FUNCNAME[0]}"
}

# @description Displays the status of a systemd service using systemctl status or notifies that the function is not available on Darwin.
# @arg $1 string The name of the systemd service.
function service-status {
  if ! os Darwin; then
    systemctl status "$1"
    return
  fi
  notavailable "${FUNCNAME[0]}"
}

# @description Checks if a systemd service is active using systemctl is-active or notifies that the function is not available on Darwin.
# @arg $1 string The name of the systemd service.
function service-isactive {
  if ! os Darwin; then
    systemctl is-active "$1"
    return
  fi
  notavailable "${FUNCNAME[0]}"
}

# @description Checks if a systemd service is enabled using systemctl is-enabled or notifies that the function is not available on Darwin.
# @arg $1 string The name of the systemd service.
function service-isenabled {
  if ! os Darwin; then
    systemctl is-enabled "$1"
    return
  fi
  notavailable "${FUNCNAME[0]}"
}

# @description Edits a systemd service file using micro or notifies that the function is not available on Darwin.
# @arg $1 string The name of the systemd service (no extension).
function service-edit {
  if ! os Darwin; then
    micro "/etc/systemd/system/$1.service"
    return
  fi
  notavailable "${FUNCNAME[0]}"
}

# @description Restarts a systemd service using systemctl restart or notifies that the function is not available on Darwin.
# @arg $1 string The name of the systemd service (no extension).
function service-restart {
  if ! os Darwin; then
    systemctl restart "$1.service"
    return
  fi
  notavailable "${FUNCNAME[0]}"
}
#endregion

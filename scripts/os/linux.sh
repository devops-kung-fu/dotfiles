#!/bin/bash

#region linux-specific
if os Linux; then
  # @description Updates the package list, upgrades installed packages, and removes unnecessary dependencies. Requires sudo privileges.
  function update {
    sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
  }
fi
#endregion

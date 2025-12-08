#!/bin/bash

#region kubernetes
alias k="kubectl"

# @description Retrieves the authentication token for accessing the Kubernetes Dashboard.
# @example
#   kube-dashboard-token - Displays the authentication token for the Kubernetes Dashboard.
function kube-dashboard-token {
  local secret
  secret=$(kubectl -n kubernetes-dashboard get secret | awk '/admin-user/ {print $1; exit}')
  if [[ -n "$secret" ]]; then
    kubectl -n kubernetes-dashboard describe secret "$secret"
  else
    echo "Admin user secret not found" >&2
    return 1
  fi
}
#endregion

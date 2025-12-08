#!/bin/bash

#region aws
# @description Lists active EC2 instances filtered by env substring.
# @arg $1 string Environment filter.
function list-instances {
  local env_filter="$1"
  echo -e "Searching current region for instances in the $env_filter environment..."
  aws ec2 describe-instances --filters Name=instance-state-name,Values=running Name=env,Values="*${env_filter}*" --query "Reservations[*].Instances[*].InstanceId" --output text
}
#endregion

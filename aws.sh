#!/bin/bash

set -eu

while getopts 'u:' flag; do
  case "${flag}" in
    u ) USER_ACCOUNT="$OPTARG" ;;
    \?) exit 1 ;;
  esac
done

echo "Creating user ${USER_ACCOUNT}... "
echo ""
useradd -g wheel "$USER_ACCOUNT"

echo ""
echo "Creating custom sudoers file... "
echo ""

cat << EOF > /etc/sudoers.d/100-custom-users
# Created by $USER $(date --rfc-2822)

# Group rules
%wheel ALL=(ALL) NOPASSWD: ALL

# User rules for local users
EOF
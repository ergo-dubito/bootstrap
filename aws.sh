#!/bin/bash

while getopts 'u:' flag; do
  case "${flag}" in
    u ) USER_ACCOUNT="$OPTARG" ;;
    \?) exit 1 ;;
  esac
done

echo ""
echo "--------"
echo "STARTING"
echo "--------"
echo ""

useradd -g wheel "$USER_ACCOUNT"

cat << EOF > /etc/sudoers.d/100-custom-users
# Created by $USER_ACCOUNT on $(date --rfc-2822)

# Group rules
%wheel ALL=(ALL) NOPASSWD: ALL

# User rules
EOF

echo ""
echo "--------"
echo "COMPLETE"
echo "--------"
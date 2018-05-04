#!/bin/bash

set -eu

echo -n "Creating user ${USER_ACCOUNT}... "
if sudo useradd -g wheel "$USER_ACCOUNT" >/dev/null 2>&1; then
  echo "done"
else
  echo "failed"
  exit 1
fi
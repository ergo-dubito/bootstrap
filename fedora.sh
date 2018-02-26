#!/usr/bin/env bash


TEE=$(which tee)

# =========================================================================
# Variables
# -------------------------------------------------------------------------

SUDOERS_FILE="/etc/sudoers.d/nopasswd"
SUODERS_RULE="%wheel  ALL=(ALL)  NOPASSWD: ALL"


# =========================================================================
# Packages
# -------------------------------------------------------------------------

PACKAGES=(
  git
  htop
  mosh
  ncdu
  nmap
  p7zip
  python3
  stow
  thefuck
  tldr
  tmux
  tree
  vim
  wget
  xz
)


# =========================================================================
# Functions
# -------------------------------------------------------------------------



# =========================================================================
# Main
# -------------------------------------------------------------------------

if [[ ! -e "$SUDOERS_FILE" ]]; then
  echo "$SUODERS_RULE" | sudo "$TEE" "$SUDOERS_FILE" >/dev/null
fi


#
# Install packages
#
for package in "${PACKAGES[@]}"
do
  echo -n "Installing $package..."
  if sudo dnf install -yq "$package" >/dev/null; then
    echo "done."
  else
    echo "failed."
  fi
done
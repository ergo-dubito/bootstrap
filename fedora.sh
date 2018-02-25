#!/usr/bin/env bash


TEE=$(which tee)

# =========================================================================
# Variables
# -------------------------------------------------------------------------

SUDOERS_FILE="/etc/sudoers.d/nopasswd"
SUODERS_RULE="%wheel  ALL=(ALL)  NOPASSWD: ALL"

PACKAGES=(
  git
  htop
  mosh
  nmap
  p7zip
  python3
  rename
  ssh-copy-id
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
  echo "Installing $package..."
  sudo dnf install -yq "$package" >/dev/null
done
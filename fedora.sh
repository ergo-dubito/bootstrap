#!/usr/bin/env bash


TEE=$(which tee)

# =========================================================================
# Variables
# -------------------------------------------------------------------------

SUDOERS_FILE="/etc/sudoers.d/nopasswd"

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

echo "%wheel  ALL=(ALL)  NOPASSWD: ALL" | sudo "$TEE" "$SUDOERS_FILE"


#
# Install packages
#
echo "Installing packages..."
sudo dnf install -yq "${PACKAGES[@]}"
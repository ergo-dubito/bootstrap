#!/usr/bin/env bash

# =========================================================================
# Variables
# -------------------------------------------------------------------------

SUDOERS_FILE="/etc/sudoers.d/nopasswd"
SUODERS_RULE="%wheel  ALL=(ALL)  NOPASSWD: ALL"

REPO_NEGATIVO="https://negativo17.org/repos/fedora-multimedia.repo"

TEE=$(which tee)


# =========================================================================
# Packages
# -------------------------------------------------------------------------

PACKAGES=(
  ffmpeg
  git
  HandBrake-cli
  htop
  libdvdcss
  makemkv
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


echo ""
echo "__ Installing Packages __"

#
# Install repos
#
sudo dnf config-manager --add-repo="$REPO_NEGATIVO"
sudo dnf clean all


#
# Install packages
#
for package in "${PACKAGES[@]}"
do
  echo -n "Installing $package... "
  if sudo dnf install -yq "$package" 2>/dev/null; then
    echo "done"
  else
    echo "failed"
  fi
done

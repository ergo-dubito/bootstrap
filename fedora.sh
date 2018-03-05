#!/usr/bin/env bash

# ==============================================================================
# Variables
# ==============================================================================

SUDOERS_FILE="/etc/sudoers.d/nopasswd"
SUODERS_RULE="%wheel  ALL=(ALL)  NOPASSWD: ALL"

TEE=$(which tee)

GPG_KEYS=(
  "$BOOTSTRAP_ASSETS/RPM-GPG-KEY-slaanesh"
  "$BOOTSTRAP_ASSETS/RPM-GPG-KEY-docker-ce"
  "$BOOTSTRAP_ASSETS/RPM-GPG-KEY-google-chrome"
)

REPOSITORIES=(
  "https://negativo17.org/repos/fedora-multimedia.repo"
  "https://download.docker.com/linux/fedora/docker-ce.repo"
  "$BOOTSTRAP_ASSETS/google-chrome.repo"
)

PACKAGES=(
  docker-ce
  git
  google-chrome-stable
  htop
  mosh
  ncdu
  nmap
  p7zip
  p7zip-plugins
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


# ==============================================================================
# Functions
# ==============================================================================



# ==============================================================================
# Main
# ==============================================================================

if [[ ! -e "$SUDOERS_FILE" ]]; then
  echo "$SUODERS_RULE" | sudo "$TEE" "$SUDOERS_FILE" >/dev/null
fi


#
# Install repositories
#
echo ""
echo "__ Installing Repositories __"

# Ensure dnf plugins are installed
sudo dnf -yq install dnf-plugins-core >/dev/null 2>&1

# Add repositories
echo -n "Adding repositories... "

addrepos=""
for repo in "${REPOSITORIES[@]}"
do
  addrepos="$addrepos --add-repo=$repo"
done

sudo dnf config-manager $(echo -n "$addrepos") >/dev/null
echo "done"

# Cleanup
echo -n "Cleaning up repo cache... "
sudo dnf clean all >/dev/null
sudo dnf makecache >/dev/null
echo "done"


#
# Install packages
#
echo ""
echo "__ Installing Packages __"

for package in "${PACKAGES[@]}"
do
  echo -n "Installing $package... "
  if sudo dnf install -yq "$package" >/dev/null 2>&1; then
    echo "done"
  else
    echo "failed"
  fi
done


#
# Docker
#
docker pull ntodd/video-transcoding

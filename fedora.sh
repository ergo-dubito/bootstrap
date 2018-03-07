#!/usr/bin/env bash

# ==============================================================================
# Variables
# ==============================================================================

SUDOERS_FILE="/etc/sudoers.d/nopasswd"
SUODERS_RULE="%wheel  ALL=(ALL)  NOPASSWD: ALL"

TEE=$(which tee)

GPG_KEYS=(
  "$BOOTSTRAP_ASSETS/gpg/RPM-GPG-KEY-slaanesh"
  "$BOOTSTRAP_ASSETS/gpg/RPM-GPG-KEY-docker-ce"
  "$BOOTSTRAP_ASSETS/gpg/RPM-GPG-KEY-google-chrome"
  "$BOOTSTRAP_ASSETS/gpg/RPM-GPG-KEY-puppet5"
)

REPOSITORIES=(
  "$BOOTSTRAP_ASSETS/repos.d/fedora-multimedia.repo"
  "$BOOTSTRAP_ASSETS/repos.d/docker-ce.repo"
  "$BOOTSTRAP_ASSETS/repos.d/google-chrome.repo"
  "$BOOTSTRAP_ASSETS/repos.d/puppet5.repo"
)

PACKAGES=(
  docker-ce
  ffmpeg
  git
  google-chrome-stable
  HandBrake-cli
  htop
  libmp4v2
  mkvtoolnix
  mosh
  mpv
  ncdu
  nmap
  perf
  p7zip
  p7zip-plugins
  python3
  stow
  strace
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
sudo dnf -yq install dnf-plugins-core >/dev/null

# Install GPG keys
for gpgkey in "${GPG_KEYS[@]}"
do
  echo -n "Importing $(basename "$gpgkey")... "
  sudo rpm --import "$gpgkey" >/dev/null
  echo "done"
done

# Add repositories
for repo in "${REPOSITORIES[@]}"
do
  reponame=$(basename -s .repo "$repo")
  echo -n "Adding repository $reponame... "
  sudo dnf config-manager --add-repo="$repo" >/dev/null
  echo "done"
done

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

echo -n "Performing system updates... "
sudo dnf upgrade -yq >/dev/null
echo "done"

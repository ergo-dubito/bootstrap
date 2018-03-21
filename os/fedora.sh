#!/usr/bin/env bash

# ==============================================================================
# Variables
# ==============================================================================

SUDOERS_FILE="/etc/sudoers.d/nopasswd"
SUODERS_RULE="%wheel  ALL=(ALL)  NOPASSWD: ALL"

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

function install_repos {
  _repos_import_gpgkeys
  _repos_add
  _repos_enable
  _repos_cleanup
}

function _repos_import_gpgkeys {
  for gpgkey in "${GPG_KEYS[@]}"
  do
    echo -n "Importing $(basename "$gpgkey")... "
    sudo rpm --import "$gpgkey" >/dev/null
    echo "done"
  done
}

function _repos_add {
  sudo dnf -yq install dnf-plugins-core >/dev/null

  for repo in "${REPOSITORIES[@]}"
  do
    reponame=$(basename -s .repo "$repo")
    echo -n "Adding repository $reponame... "
    sudo dnf config-manager --add-repo="$repo" >/dev/null
    echo "done"
  done
}

function _repos_enable {
  echo -n "Enabling CentOS-specific repos... "
  sudo dnf config-manager --enable docker-ce-stable-centos >/dev/null 2>&1
  sudo dnf config-manager --enable puppet5-el >/dev/null 2>&1
  echo "done"
}

function _repos_cleanup {
  echo -n "Cleaning up repo cache... "
  sudo dnf clean all >/dev/null
  sudo dnf makecache >/dev/null
  echo "done"
}

function install_packages {
  _pkgs_install
  _pkgs_upgrade
}

function _pkgs_install {
  for package in "${PACKAGES[@]}"
  do
    echo -n "Installing $package... "
    if sudo dnf install -yq "$package" >/dev/null 2>&1; then
      echo "done"
    else
      echo "failed"
    fi
  done
}

function _pkgs_upgrade {
  echo -n "Performing system updates... "
  sudo dnf upgrade -yq >/dev/null
  echo "done"
}


# ==============================================================================
# Main
# ==============================================================================

echo ""
echo "__ Configuring System __"

if [[ ! -f "$SUDOERS_FILE" ]]; then
  echo "Setting 'wheel' group to NOPASSWD mode..."
  sudo bash -c "echo '$SUODERS_RULE' > '$SUDOERS_FILE'"
fi

echo ""
echo "__ Installing Repositories __"
install_repos

echo ""
echo "__ Installing Packages __"
install_packages

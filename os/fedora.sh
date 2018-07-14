#!/usr/bin/env bash

# ==============================================================================
# Variables
# ==============================================================================

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
  bluefish
  docker-ce
  expect
  ffmpeg
  git
  google-chrome-stable
  HandBrake-cli
  htop
  libmp4v2
  mediawriter
  mkvtoolnix
  mosh
  most
  mpv
  ncdu
  nmap
  perf
  p7zip
  p7zip-plugins
  powerline-fonts
  python3
  seahorse
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
  # Ensure dnf plugins package is installed
  sudo dnf -y -q install dnf-plugins-core

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
  for repo in "${REPOSITORIES[@]}"
  do
    echo -n "Adding repository $(basename -s .repo "$repo")... "
    sudo dnf config-manager --add-repo="$repo" >/dev/null
    echo "done"
  done
}

function _repos_enable {
  echo -n "Enabling Fedora-specific repos... "
  sudo dnf config-manager --enablerepo docker-ce-stable-fedora &>/dev/null
  sudo dnf config-manager --enablerepo puppet5-el &>/dev/null
  echo "done"
}

function _repos_cleanup {
  echo -n "Cleaning up repo cache... "
  sudo dnf clean all &>/dev/null
  sudo dnf makecache &>/dev/null
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
    if sudo dnf install -y -q "$package"; then
      echo "done"
    else
      echo "failed"
    fi
  done
}

function _pkgs_upgrade {
  echo -n "Performing system updates... "
  sudo dnf upgrade -y -q &>/dev/null
  echo "done"
}


# ==============================================================================
# Main
# ==============================================================================

echo ""
echo "__ Installing Repositories __"
if [[ $EXCEPT != *"r"* ]] || [[ $EXCEPT != *"u"* ]]; then
  install_repos
elif [[ $EXCEPT != *"u"* ]]; then
  _repos_cleanup
else
  echo "Skipping repository installs... "
fi

echo ""
echo "__ Installing Packages __"
if [[ $EXCEPT != *"p"* ]] || [[ $EXCEPT != *"u"* ]]; then
  install_packages
else
  echo "Skipping package installs... "
fi

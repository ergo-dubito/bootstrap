#!/usr/bin/env bash

# ==============================================================================
# Variables
# ==============================================================================

GPG_KEYS=(
  "$BOOTSTRAP_ASSETS/gpg/RPM-GPG-KEY-docker-ce"
  "$BOOTSTRAP_ASSETS/gpg/RPM-GPG-KEY-puppet5"
  "$BOOTSTRAP_ASSETS/gpg/RPM-GPG-KEY-remi"
)

REPOSITORIES=(
  "$BOOTSTRAP_ASSETS/repos.d/docker-ce.repo"
  "$BOOTSTRAP_ASSETS/repos.d/puppet5.repo"
  "$BOOTSTRAP_ASSETS/repos.d/remi.repo"
)

PACKAGES=(
  docker-ce
  epel-release
  git
  htop
  mosh
  most
  ncdu
  nmap
  perf
  p7zip
  p7zip-plugins
  stow
  strace
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
  sudo yum -yq install yum-utils >/dev/null

  for repo in "${REPOSITORIES[@]}"
  do
    reponame=$(basename -s .repo "$repo")
    echo -n "Adding repository $reponame... "
    # TODO: add RHEL versions of repos
    echo "done"
  done
}

function _repos_enable {
  echo -n "Enabling RHEL-specific repos... "
  # TODO: add RHEL versions of repos
  echo "done"
}

function _repos_cleanup {
  echo -n "Cleaning up repo cache... "
  sudo yum clean all >/dev/null
  sudo yum makecache >/dev/null
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
    if sudo yum install -y -q "$package" >/dev/null 2>&1; then
      echo "done"
    else
      echo "failed"
    fi
  done
}

function _pkgs_upgrade {
  echo -n "Performing system updates... "
  sudo yum update -yq >/dev/null 2>&1
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
fi

echo ""
echo "__ Installing Packages __"
if [[ $EXCEPT != *"p"* ]] || [[ $EXCEPT != *"u"* ]]; then
  install_packages
else
  echo "Skipping package installs... "
fi

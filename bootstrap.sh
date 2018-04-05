#!/usr/bin/env bash

# shellcheck disable=SC2164
set -eu

# ==============================================================================
# Variables
# ==============================================================================

TRUE=0
FALSE=1

OS=""
USER_MODE="$FALSE"

DATE=$(date +%Y%m%d%H%M%S)
HOSTNAME=$(hostname)

DICT_TMP="$(mktemp)"
DICT_DIR="/usr/local/share/dict"
DICT="$DICT_DIR/words"

PASSPHRASE_FILE="$HOME/.ssh/passphrase-$DATE"
PASSPHRASE_WORDS=4
PASSPHRASE_SAVE="$FALSE"

BOOTSTRAP_REPO="https://raw.githubusercontent.com/bradleyfrank/bootstrap"
BOOTSTRAP_URL="$BOOTSTRAP_REPO/master"
BOOTSTRAP_ASSETS="$BOOTSTRAP_REPO/master/assets"

DOTFILES_HTTPS="https://github.com/bradleyfrank/dotfiles.git"
DOTFILES_GIT="git@github.com:bradleyfrank/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

STOW_URL="https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz"

# GitHub RSA SHA256 fingerprint
# https://help.github.com/articles/github-s-ssh-key-fingerprints/
GITHUB_FINGERPRINT="SHA256:nThbg6kXUpJWGl7E1IGOCspRomTxdCARLviKw6E5SY8"

PATHS=("$HOME/.local/bin" "/usr/local/bin" "/usr/bin" "/bin")
BIN_PATH="NaN"

DIRECTORIES=(
  "$HOME/Development"
  "$HOME/.ssh"
  "$HOME/.local"
  "$HOME/.config"
  "$DICT_DIR"
)


# ==============================================================================
# Packages
# ==============================================================================

PYTHON_PACKAGES=(
  powerline-status
  powerline-gitstatus
  pydf
)


# ==============================================================================
# Functions
# ==============================================================================

# ------------------------------------------------------------------------------
# Install Git hooks into dotfile repo
# ------------------------------------------------------------------------------
function add_git_hooks () {
  local githook_postmerge
  githook_postmerge="$DOTFILES_DIR/.git/hooks/post-merge"

  echo -n "Downloading git hooks... "
  if wget "$BOOTSTRAP_ASSETS/git/post-merge" -qO "$githook_postmerge"; then
    chmod u+x "$githook_postmerge"
    echo "done"
  else
    echo "failed"
  fi
}


# ------------------------------------------------------------------------------
# Clones the dotfile repo
# ------------------------------------------------------------------------------
function clone_dotfiles_repo () {
  echo -n "Cloning dotfiles repo... "

  if "$GIT" clone --recurse-submodules "$DOTFILES_HTTPS" "$DOTFILES_DIR" >/dev/null 2>&1; then
    pushd "$DOTFILES_DIR" >/dev/null 2>&1
    "$GIT" remote set-url origin "$DOTFILES_GIT"
    "$GIT" config core.fileMode false
    popd >/dev/null 2>&1
    echo "done"

    add_git_hooks
    fix_permissions
  else
    echo "failed"
    exit 1
  fi
}


# ------------------------------------------------------------------------------
# Executes the post-merge script and makes binaries executable
# ------------------------------------------------------------------------------
function fix_permissions () {
  echo -n "Fixing file permissions... "

  chmod 700 "$HOME/.ssh"

  pushd "$DOTFILES_DIR" >/dev/null 2>&1
  # shellcheck disable=SC1091
  (. ./.git/hooks/post-merge)
  chmod 750 .
  chmod uo+x ./bin/.local/bin/*
  popd >/dev/null 2>&1

  echo "done"
}


# ------------------------------------------------------------------------------
# Generate a unique, secure passphrase using custom dictionary
# ------------------------------------------------------------------------------
function generate_passphrase () {
  if [[ ! -d "$HOME"/.ssh ]]; then
    mkdir "$HOME"/.ssh
    chmod 700 "$HOME"/.ssh
  fi
  

  echo -n "Generating passphrase... "
  "$SHUF" --random-source=/dev/random -n "$PASSPHRASE_WORDS" "$DICT" | tr A-Z a-z | sed -e ':a' -e 'N' -e '$!ba' -e "s/\\n/-/g" > "$PASSPHRASE_FILE"
  echo "done"
}


# ------------------------------------------------------------------------------
# Create a SSH key with ssh-keygen
# ------------------------------------------------------------------------------
function generate_sshkey () {
  local comment
  local file
  local passphrase

  file="$HOME/.ssh/id_$1"

  if [[ ! -e "$file" ]]; then
    echo -n "Generating $1 SSH key... "

    comment="${USER}@${HOSTNAME}"
    passphrase=$(<"$PASSPHRASE_FILE" tr -d '\n')
    ssh-keygen -t "$1" -b 4096 -N "$passphrase" -C "$comment" -f "$file" >/dev/null 2>&1

    echo "done"
    PASSPHRASE_SAVE="$TRUE"
  fi
}


# ------------------------------------------------------------------------------
# Run a quick and dirty check for the Operating System
# ------------------------------------------------------------------------------
function get_operating_system () {
  echo -n "Detecting OS... "
  if type sw_vers >/dev/null 2>&1; then
    if sw_vers | grep -iq 'mac'; then
      OS="macos"
    else
      echo "failed"
      exit 1
    fi
  elif [ -f /etc/os-release ]; then
    OS=$(sed -n -e 's/^ID=//p' /etc/os-release)
  elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
  elif [ -f /etc/fedora-release ]; then
    OS="fedora"
  elif [ -f /etc/centos-release ] || [ -f /etc/redhat-release ]; then
    OS="redhat"
  else
    echo "failed"
    exit 1
  fi

  echo "${OS}"
}


# ------------------------------------------------------------------------------
# Installs a custom dictionary
# ------------------------------------------------------------------------------
function install_dict () {
  echo -n "Installing custom dictionary... "

  if [[ ! -e "$DICT" ]]; then
    if ! wget "$BOOTSTRAP_ASSETS/dictionary.7z" -qO "$DICT_TMP"; then
      echo "failed"
      exit 1
    fi

    if ! 7z x "$DICT_TMP" -o"$DICT_DIR/" >/dev/null 2>&1; then
      echo "failed"
      exit 1
    else
      mv "$DICT_DIR/dictionary" "$DICT"
      echo "done"
    fi
  fi
}


# ------------------------------------------------------------------------------
# Compile Stow from source if not installed by system
# ------------------------------------------------------------------------------
function install_stow () {
  echo -n "Installing Stow... "

  local tmp_fle
  local tmp_dir

  tmp_fle=$(mktemp)
  tmp_dir=$(mktemp -d)

  curl -L "$STOW_URL" > "$tmp_fle" 2>/dev/null
  tar -xzf "$tmp_fle" -C "$tmp_dir" --strip-components 1
  pushd "$tmp_dir" >/dev/null 2>&1
  ./configure --prefix="$HOME"/.local >/dev/null 2>&1
  make >/dev/null 2>&1
  make install >/dev/null 2>&1
  popd >/dev/null 2>&1

  echo "done"
}


# ------------------------------------------------------------------------------
# Set OS dependant variables
# ------------------------------------------------------------------------------
function set_variables () {
  if [[ "$OS" == "macos" ]]; then
    PIP="pip3"
    SHUF="gshuf"
  else
    PIP="pip"
    SHUF="shuf"
  fi
}


# ------------------------------------------------------------------------------
# Download and source OS-specific script as a sub-shell
# ------------------------------------------------------------------------------
function source_remote_file () {
  f=$(mktemp)
  curl -o "$f" -s -L "$BOOTSTRAP_URL/os/$OS.sh"
  # shellcheck source=/dev/null
  (. "$f")
}


# ------------------------------------------------------------------------------
# Create an empty file and chmod it
# ------------------------------------------------------------------------------
function touch_file () {
  if [[ ! -f "$1" ]]; then
    echo -n "Creating file $1... "
    if touch "$1"; then
      chmod "$2" "$1"
      echo "done"
    else
      echo "failed"
      exit 1
    fi
  fi
}


# ------------------------------------------------------------------------------
# Dirty version of `which` cause $PATH can't be trusted yet
# ------------------------------------------------------------------------------
function whichever () {
  BIN_PATH="NaN"

  for this_path in "${PATHS[@]}"
  do
    if [[ -x "$this_path"/"$1" ]]; then
      BIN_PATH="$this_path"
      break
    fi
  done
}


# ==============================================================================
# Main
# ==============================================================================

while getopts 'hu' flag; do
  case "${flag}" in
    h )
      echo "bootstrap.sh - sets up system and configures user profile"
      echo ""
      echo "Usage: bootstrap.sh [-hs]"
      echo ""
      echo "Options:"
      echo "-h    print help menu and exit"
      echo "-u    user mode (skips configs that require root privileges)"
      exit 0
      ;;
    u ) USER_MODE="$TRUE" ;;
    \?) exit 1 ;;
  esac
done


echo ""
echo "__ Starting Bootstrap __"


# ------------------------------------------------------------------------------
# Misc items
# ------------------------------------------------------------------------------
for directory in "${DIRECTORIES[@]}"
do
  if [[ ! -d "$directory" ]]; then mkdir "$directory"; fi
done


# ------------------------------------------------------------------------------
# Load OS-specific script
# ------------------------------------------------------------------------------
get_operating_system
source_remote_file
set_variables


# ------------------------------------------------------------------------------
# Set paths for various packages
# ------------------------------------------------------------------------------
echo ""
echo "__ Finding Executable Paths __"

#
# pip
#
echo -n "Looking for $PIP... "
whichever "$PIP"

if [[ "$BIN_PATH" != "NaN" ]]; then
  PIP="$BIN_PATH/$PIP"
  echo "found"
else
  echo "failed"
  exit 1
fi

#
# git
#
echo -n "Looking for git... "
whichever "git"

if [[ "$BIN_PATH" != "NaN" ]]; then
  GIT="$BIN_PATH/git"
  echo "found"
else
  echo "failed"
  exit 1
fi

#
# stow
#
echo -n "Looking for stow... "
whichever "stow"

if [[ "$BIN_PATH" != "NaN" ]]; then
  STOW="$BIN_PATH/stow"
  echo "found"
else
  echo "failed"
  exit 1
fi

#
# shuf
#
echo -n "Looking for $SHUF... "
whichever "$SHUF"

if [[ "$BIN_PATH" != "NaN" ]]; then
  SHUF="$BIN_PATH/$SHUF"
  echo "found"
else
  echo "failed"
  exit 1
fi


# ------------------------------------------------------------------------------
# Install Python packages
# ------------------------------------------------------------------------------
echo ""
echo "__ Installing Python Packages __"

for pypkg in "${PYTHON_PACKAGES[@]}"
do
  echo -n "Installing $pypkg... "
  if "$PIP" install -U --user "$pypkg" -qqq 2>/dev/null; then
    echo "done"
  else
    echo "failed"
  fi
done


# ------------------------------------------------------------------------------
# Clone dotfiles repo
# ------------------------------------------------------------------------------
echo ""
echo "__ Installing Dotfile Customizations __"

pushd "$HOME" >/dev/null 2>&1
if [[ ! -d "$DOTFILES_DIR" ]]; then mkdir "$DOTFILES_DIR"; fi
pushd "$DOTFILES_DIR" >/dev/null 2>&1

if ! git status >/dev/null 2>&1; then
  popd >/dev/null 2>&1
  clone_dotfiles_repo
else
  echo -n "Updating repo... "
  if "$GIT" checkout master >/dev/null 2>&1; then
    if "$GIT" pull >/dev/null 2>&1; then
      add_git_hooks
      fix_permissions
      echo "done"
    else
      echo "failed"
    fi
  else
    echo "failed"
  fi
  popd >/dev/null 2>&1
fi

popd >/dev/null 2>&1


# ------------------------------------------------------------------------------
# Stow packages
# ------------------------------------------------------------------------------
pushd "$DOTFILES_DIR" >/dev/null 2>&1
shopt -s nullglob

if git branch --list | grep -q "$HOSTNAME" >/dev/null 2>&1; then
  "$GIT" checkout master >/dev/null 2>&1
  stow_packages=(*/)
  for pkg in "${stow_packages[@]}"; do
    _pkg=$(echo "$pkg" | cut -d '/' -f 1)
    echo -n "Stowing $_pkg... "
    "$STOW" -d "$DOTFILES_DIR" -t "$HOME" "$_pkg"
    echo "done"
  done
else
  "$GIT" checkout -b "$HOSTNAME" >/dev/null 2>&1
  stow_packages=(*/)
  for pkg in "${stow_packages[@]}"; do
    _pkg=$(echo "$pkg" | cut -d '/' -f 1)
    echo -n "Stowing $_pkg... "
    "$STOW" -d "$DOTFILES_DIR" -t "$HOME" --adopt "$_pkg"
    echo "done"
  done
  "$GIT" add -A >/dev/null 2>&1
  "$GIT" commit -m "Default dotfiles for $HOSTNAME." >/dev/null 2>&1
  "$GIT" checkout master >/dev/null 2>&1
fi

popd >/dev/null 2>&1


# ------------------------------------------------------------------------------
# Various SSH configurations
# ------------------------------------------------------------------------------
echo ""
echo "__ Configuring SSH __"

# Set some variables
authkeys="$DOTFILES_DIR/ssh/.ssh/authorized_keys"
known_hosts="$HOME/.ssh/known_hosts"

ssh_create_files=("$authkeys" "$known_hosts")
sshkeys=("rsa" "ed25519")

# Generate a temporary secure passphrase
install_dict
generate_passphrase

# Loop through keys to generate
for sshkey in "${sshkeys[@]}"; do
  generate_sshkey "$sshkey"
done

# Save or delete temporary passphrase
if [[ "$PASSPHRASE_SAVE" -eq "$FALSE" ]]; then
  rm -f "$PASSPHRASE_FILE"
else
  chmod 400 "$PASSPHRASE_FILE"
fi

# Create required SSH files
for ssh_file in "${ssh_create_files[@]}"; do
  touch_file "$ssh_file" "0600"
done

# Add GitHub to known_hosts
keyscan=$(ssh-keyscan github.com 2>/dev/null)
fingerprint=$(ssh-keygen -lf <(echo "$keyscan") | cut -d ' ' -f 2)

if [[ "$fingerprint" == "$GITHUB_FINGERPRINT" ]]; then
  key="$(echo "$keyscan" | cut -d ' ' -f 3)"
  if ! grep -qr "$key" "$known_hosts" 2>/dev/null; then
    echo -n "Adding GitHub SSH key to known_hosts... "
    echo "$keyscan" >> "$known_hosts"
    echo "done"
  fi
else
  echo "Error: GitHub SSH key fingerprints do not match."
  exit 1
fi

# Add public keys to authorized_keys
pushd "$HOME"/.ssh >/dev/null 2>&1

commit="$FALSE"
shopt -s nullglob
keys=(*.pub)

for key in "${keys[@]}"; do
  publickey=$(<"$HOME"/.ssh/"$key" tr -d '\n')

  if ! grep -rq "$publickey" "$authkeys"; then
    echo -n "Adding $key... "
    echo "$publickey" >> "$authkeys"
    echo "done"
    commit="$TRUE"
  fi
done

popd >/dev/null 2>&1

if [[ "$commit" -eq "$TRUE" ]]; then
  pushd "$DOTFILES_DIR" >/dev/null 2>&1
  "$GIT" add "$authkeys" >/dev/null 2>&1
  "$GIT" commit -m "Added keys to authorized_keys for $HOSTNAME." >/dev/null
  popd >/dev/null 2>&1
fi


# ------------------------------------------------------------------------------
# Exit
# ------------------------------------------------------------------------------
echo ""
echo "__ Finishing Up __"

if [[ "$PASSPHRASE_SAVE" -eq "$TRUE" ]]; then
  echo " * SSH Passphrase saved to $PASSPHRASE_FILE"
fi

if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
  echo " * Add id_ed25519 key to GitHub"
else
  echo " * Add id_rsa key to GitHub"
fi

echo " * Push dotfile repo updates"

if [[ "$OS" == "macos" ]]; then
  echo " * Run post-bootstrap: curl -fsSL https://bradleyfrank.github.io/bootstrap/post/macos.sh | bash"
fi

echo ""
exit 0
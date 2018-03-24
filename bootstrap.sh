#!/usr/bin/env bash

set -e
set -o nounset

# ==============================================================================
# Variables
# ==============================================================================

TRUE=0
FALSE=1

OS=""
CONFIG_SYSTEM="$FALSE"

DATE=$(date +%Y%m%d%H%M%S)
HOSTNAME=$(hostname)

DEV_DIR="$HOME/Development"

DICT="$HOME/.ssh/dictionary"
PASSPHRASE_TMP="$(mktemp)"
PASSPHRASE_FILE="$HOME/.ssh/passphrase-$DATE"
PASSPHRASE_WORDS=4
PASSPHRASE_SAVE="$FALSE"

BOOTSTRAP_REPO="https://raw.githubusercontent.com/bradleyfrank/bootstrap"
BOOTSTRAP_URL="$BOOTSTRAP_REPO/master"
BOOTSTRAP_ASSETS="$BOOTSTRAP_REPO/master/assets"

DOTFILES_HTTPS="https://github.com/bradleyfrank/dotfiles.git"
DOTFILES_GIT="git@github.com:bradleyfrank/dotfiles.git"
DOTFILES_LOC="$HOME/.dotfiles"

STOW_URL="https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz"

# GitHub RSA SHA256 fingerprint
# https://help.github.com/articles/github-s-ssh-key-fingerprints/
GITHUB_FINGERPRINT="SHA256:nThbg6kXUpJWGl7E1IGOCspRomTxdCARLviKw6E5SY8"

SED=$(which sed)
TR=$(which tr)
SHUF=$(which shuf)

PATHS=("$HOME/.local/bin" "/usr/local/bin" "/usr/bin" "/bin")
BIN_PATH=""


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
  githook_postmerge="$DOTFILES_LOC/.git/hooks/post-merge"

  whichever "wget"
  WGET="$BIN_PATH/wget"

  echo -n "Downloading git hooks... "
  if "$WGET" "$BOOTSTRAP_ASSETS/git/post-merge" -qO "$githook_postmerge"; then
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

  "$GIT" clone "$DOTFILES_HTTPS" "$DOTFILES_LOC" >/dev/null 2>&1

  pushd "$DOTFILES_LOC" >/dev/null
  "$GIT" remote set-url origin "$DOTFILES_GIT"
  "$GIT" config core.fileMode false
  popd >/dev/null

  add_git_hooks
  fix_permissions

  echo "done"
}


# ------------------------------------------------------------------------------
# Executes the post-merge script and makes binaries executable
# ------------------------------------------------------------------------------
function fix_permissions () {
  echo -n "Fixing file permissions... "
  pushd "$DOTFILES_LOC" >/dev/null
  # shellcheck disable=SC1091
  (. ./.git/hooks/post-merge)
  chmod 750 .
  chmod uo+x ./bin/.local/bin/keychain
  popd >/dev/null
  echo "done"
}


# ------------------------------------------------------------------------------
# Generate a unique, secure passphrase using custome dictionary
# ------------------------------------------------------------------------------
function generate_passphrase () {
  if [[ "$OS" == "macos" ]]; then
    whichever "gshuf"
    SHUF="$BIN_PATH/gshuf"
  fi

  if [[ ! -d "$HOME"/.ssh ]]; then
    mkdir "$HOME"/.ssh
    chmod 700 "$HOME"/.ssh
  fi

  if [[ ! -e "$DICT" ]]; then
    "$WGET" "$BOOTSTRAP_ASSETS/dictionary.7z" -qO "$PASSPHRASE_TMP"
    7z x "$PASSPHRASE_TMP" -o"$HOME"/.ssh/ >/dev/null 2>&1
  fi

  echo -n "Generating passphrase... "
  "$SHUF" --random-source=/dev/random -n "$PASSPHRASE_WORDS" "$DICT" | "$TR" A-Z a-z | "$SED" -e ':a' -e 'N' -e '$!ba' -e "s/\\n/-/g" > "$PASSPHRASE_TMP"
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
    passphrase=$(<"$PASSPHRASE_FILE" "$TR" -d '\n')
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
    OS=$("$SED" -n -e 's/^ID=//p' /etc/os-release)
  elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si | "$TR" '[:upper:]' '[:lower:]')
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
# Compile Stow from source if not installed by system
# ------------------------------------------------------------------------------
function install_stow () {
  echo -m "Installing Stow... "

  local tmp_fle
  local tmp_dir

  tmp_fle=$(mktemp)
  tmp_dir=$(mktemp -d)

  curl -L "$STOW_URL" > "$tmp_fle" 2>/dev/null
  tar -xzf "$tmp_fle" -C "$tmp_dir" --strip-components 1
  pushd "$tmp_dir" >/dev/null
  ./configure --prefix="$HOME"/.local >/dev/null
  make >/dev/null 2>&1
  make install >/dev/null 2>&1
  popd >/dev/null

  echo "done"
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

while getopts 'hs' flag; do
  case "${flag}" in
    h )
      echo "bootstrap.sh - sets up system and configures user profile"
      echo ""
      echo "Usage: bootstrap.sh [-hs]"
      echo ""
      echo "Options:"
      echo "-h    print help menu and exit"
      echo "-s    configure system (requires sudo access)"
      exit 0
      ;;
    s ) CONFIG_SYSTEM="$TRUE" ;;
    \?) exit 1 ;;
  esac
done


echo ""
echo "__ Starting Bootstrap __"


# ------------------------------------------------------------------------------
# Create environment
# ------------------------------------------------------------------------------
if [[ ! -d "$DEV_DIR" ]]; then
  echo -n "Making dev environment... "
  mkdir "$DEV_DIR"
  echo "done"
fi


# ------------------------------------------------------------------------------
# Load OS-specific script
# ------------------------------------------------------------------------------
get_operating_system
source_remote_file


# ------------------------------------------------------------------------------
# Set paths for various packages
# ------------------------------------------------------------------------------
echo ""
echo "__ Finding Executable Paths __"

whichever "pip3"
if [[ "$BIN_PATH" != "NaN" ]]; then
  PIP="$BIN_PATH/pip3"
else
  whichever "pip"
  if "$BIN_PATH" != "NaN"; then
    PIP="$BIN_PATH/pip"
  else
    echo "Error: \`pip\` not found."
    exit 1
  fi
fi

echo "Found \`pip\` at $PIP"

whichever "git"
if [[ "$BIN_PATH" != "NaN" ]]; then
  GIT="$BIN_PATH/git"
else
  echo "Error: \`git\` not found."
  exit 1
fi

echo "Found \`git\` at $GIT"

whichever "stow"
if [[ "$BIN_PATH" != "NaN" ]]; then
  STOW="$BIN_PATH/stow"
else
  echo "Error: \`stow\` not found."
  exit 1
fi

echo "Found \`stow\` at $STOW"


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

if [[ ! -d "$DOTFILES_LOC" ]]; then
  clone_dotfiles_repo
else
  pushd "$DOTFILES_LOC" >/dev/null
  if ! git status >/dev/null 2>&1; then
    popd >/dev/null
    rm -rf "$DOTFILES_LOC"
    clone_dotfiles_repo
  else
    echo -n "Updating repo... "
    "$GIT" checkout master >/dev/null 2>&1
    if "$GIT" pull >/dev/null 2>&1; then
      echo "done"
      add_git_hooks
      fix_permissions
    else
      echo "failed (but no problem)"
    fi
    popd >/dev/null
  fi
fi


# ------------------------------------------------------------------------------
# Stow packages
# ------------------------------------------------------------------------------
pushd "$DOTFILES_LOC" >/dev/null
shopt -s nullglob

if git branch --list | grep -q "$HOSTNAME"; then
  "$GIT" checkout master >/dev/null 2>&1
  stow_packages=(*/)
  for pkg in "${stow_packages[@]}"; do
    _pkg=$(echo "$pkg" | cut -d '/' -f 1)
    echo -n "Stowing $_pkg... "
    "$STOW" -d "$DOTFILES_LOC" -t "$HOME" "$_pkg"
    echo "done"
  done
else
  "$GIT" checkout -b "$HOSTNAME"
  stow_packages=(*/)
  for pkg in "${stow_packages[@]}"; do
    _pkg=$(echo "$pkg" | cut -d '/' -f 1)
    echo -n "Stowing $_pkg... "
    "$STOW" -d "$DOTFILES_LOC" -t "$HOME" --adopt "$_pkg"
    echo "done"
  done
  "$GIT" add -A >/dev/null
  "$GIT" commit -m "Default dotfiles for $HOSTNAME." >/dev/null
  "$GIT" checkout master >/dev/null
fi

popd >/dev/null


# ------------------------------------------------------------------------------
# Various SSH configurations
# ------------------------------------------------------------------------------
echo ""
echo "__ Configuring SSH __"

# Set some variables
authkeys="$DOTFILES_LOC/ssh/.ssh/authorized_keys"
known_hosts="$HOME/.ssh/known_hosts"

ssh_create_files=("$authkeys" "$known_hosts")
sshkeys=("rsa" "ed25519")

# Generate a temporary secure passphrase
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
pushd "$HOME"/.ssh >/dev/null

commit="$FALSE"
shopt -s nullglob
keys=(*.pub)

for key in "${keys[@]}"; do
  publickey=$(<"$HOME"/.ssh/"$key" "$TR" -d '\n')

  if ! grep -rq "$publickey" "$authkeys"; then
    echo -n "Adding $key... "
    echo "$publickey" >> "$authkeys"
    echo "done"
    commit="$TRUE"
  fi
done

popd >/dev/null

if [[ "$commit" -eq "$TRUE" ]]; then
  pushd "$DOTFILES_LOC" >/dev/null
  "$GIT" add "$authkeys" >/dev/null
  "$GIT" commit -m "Added keys to authorized_keys for $HOSTNAME." >/dev/null
  popd >/dev/null
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
echo ""
exit 0
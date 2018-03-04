#!/usr/bin/env bash

set -e
set -o nounset


# =========================================================================
# Variables
# -------------------------------------------------------------------------

OS=""
HOSTNAME=$(hostname)

DATE=$(date +%Y%m%d%H%M%S)

DEV_DIR="$HOME/Development"
PASSPHRASE_FILE="$HOME/.ssh/passphrase"
DICT="/usr/share/dict/words"

STOW_URL="https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz"

BOOTSTRAP_URL="https://raw.githubusercontent.com/bradleyfrank/bootstrap/master"
DOTFILES_HTTPS="https://github.com/bradleyfrank/dotfiles.git"
DOTFILES_GIT="git@github.com:bradleyfrank/dotfiles.git"
DOTFILES_LOC="$HOME/.dotfiles"

SED=$(which sed)
TR=$(which tr)
SHUF=$(which shuf)

TRUE=0
FALSE=1

PATHS=("$HOME/.local/bin" "/usr/local/bin" "/usr/bin" "/bin")
BIN_PATH=""


# =========================================================================
# Packages
# -------------------------------------------------------------------------

PYTHON_PACKAGES=(
  powerline-status
  powerline-gitstatus
  pydf
)


# =========================================================================
# Functions
# -------------------------------------------------------------------------

function clone_dotfiles_repo () {
  echo -n "Cloning dotfiles repo... "
  "$GIT" clone "$DOTFILES_HTTPS" "$DOTFILES_LOC" >/dev/null 2>&1
  pushd "$DOTFILES_LOC" >/dev/null
  "$GIT" remote set-url origin "$DOTFILES_GIT"
  "$GIT" config core.fileMode false
  popd >/dev/null
  echo "done"

  fix_permissions
}


function fix_permissions () {
  echo -n "Fixing permissions in dotfiles repo... "
  chmod 600 "$DOTFILES_LOC"/ssh/.ssh/config
  chmod uo+x "$DOTFILES_LOC"/bin/.local/bin/keychain
  echo "done"
}


function generate_passphrase () {
  if [[ "$OS" == "macos" ]]; then
    whichever "gshuf"
    SHUF="$BIN_PATH/gshuf"
  fi

  if [[ ! -d "$HOME"/ssh ]]; then
    mkdir "$HOME"/ssh
    chmod 700 "$HOME"/ssh
  fi

  if [[ -f "$PASSPHRASE_FILE" ]]; then
    mv "$PASSPHRASE_FILE"{,."$DATE"}
  fi

  "$SHUF" --random-source=/dev/random -n 5 "$DICT" | "$TR" A-Z a-z | "$SED" -e ':a' -e 'N' -e '$!ba' -e "s/\\n/-/g" > "$PASSPHRASE_FILE"
}


function generate_sshkey () {
  local comment
  local file
  local passphrase

  comment="${USER}@${HOSTNAME}"
  file="$HOME/.ssh/id_$1"
  passphrase=$(<"$PASSPHRASE_FILE" "$TR" -d '\n')

  ssh-keygen -t "$1" -b 4096 -N "$passphrase" -C "$comment" -f "$file" >/dev/null 2>&1
}


function get_operating_system () {
  if type sw_vers >/dev/null 2>&1; then
    if sw_vers | grep -iq 'mac'; then
      OS="macos"
    else
      echo "Error: OS unable to be determined."
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
    echo "Error: OS not supported."
    exit 1
  fi

  echo "Detected OS: ${OS}"
}


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
  make && make install >/dev/null
  popd >/dev/null

  echo "done"
}


function source_remote_file () {
  f=$(mktemp)
  curl -o "$f" -s -L "$BOOTSTRAP_URL/$OS.sh"
  (. "$f")
}


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


# =========================================================================
# Main
# -------------------------------------------------------------------------

echo ""
echo "__ Starting Bootstrap __"


#
# Create environment
#
if [[ ! -d "$DEV_DIR" ]]; then
  echo -n "Making dev environment... "
  mkdir "$DEV_DIR"
  echo "done"
fi


#
# Load OS-specific script
#
get_operating_system
source_remote_file


#
# Set paths for various packages
#
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


#
# Create SSH keys
#
echo ""
echo "__ Checking For SSH Keys __"

echo -n "Generating secure passphrase... "
generate_passphrase
echo "done"
keep_passphrase="$FALSE"

if [[ ! -e "$HOME/.ssh/id_rsa" ]]; then
  echo -n "Generating rsa SSH key... "
  generate_sshkey "rsa"
  keep_passphrase="$TRUE"
  echo "done"
fi

if [[ ! -e "$HOME/.ssh/id_ed25519" ]]; then
  echo -n "Generating ed25519 SSH key... "
  generate_sshkey "ed25519"
  keep_passphrase="$TRUE"
  echo "done"
fi

if [[ $keep_passphrase -eq "$FALSE" ]]; then
  rm -f "$PASSPHRASE_FILE"
else
  chmod 400 "$PASSPHRASE_FILE"
fi


#
# Install Python packages
#
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


#
# Clone dotfiles repo
#
echo ""
echo "__ Installing Dotfile Customizations __"

if [[ ! -d "$DOTFILES_LOC" ]]; then
  clone_dotfiles_repo
else
  rm -rf "$HOME"/.dotfiles
  clone_dotfiles_repo
fi


#
# Stow packages
#
pushd "$DOTFILES_LOC" >/dev/null
shopt -s nullglob

if git branch --list | grep -q "$HOSTNAME"; then
  stow_packages=(*/)
  for pkg in "${stow_packages[@]}"; do
    $_pkg=$(echo "$pkg" | cut -d '/' -f 1)
    echo -n "Stowing $_pkg... "
    "$STOW" -d "$DOTFILES_LOC" -t "$HOME" "$_pkg"
    echo "done"
  done
else
  "$GIT" checkout -b "$HOSTNAME"
  stow_packages=(*/)
  for pkg in "${stow_packages[@]}"; do
    $_pkg=$(echo "$pkg" | cut -d '/' -f 1)
    echo -n "Stowing $_pkg... "
    "$STOW" -d "$DOTFILES_LOC" -t "$HOME" --adopt "$_pkg"
    echo "done"
  done
  "$GIT" add -A
  "$GIT" commit -m "Default dotfiles for $HOSTNAME."
  "$GIT" checkout master
fi

popd >/dev/null


#
# Exit
#
exit 0
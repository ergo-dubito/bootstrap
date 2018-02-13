#!/usr/bin/env bash

set -e
set -o nounset


# =========================================================================
# Variables
# -------------------------------------------------------------------------

OS=""
HOSTNAME=$(hostname)

DEV_DIR="$HOME/Development"
PASSPHRASE_FILE="$HOME/.ssh/passphrase"
DICT="/usr/share/dict/words"

STOW_URL="https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz"

DOTFILES_HTTPS="https://github.com/bradleyfrank/dotfiles.git"
DOTFILES_GIT="git@github.com:bradleyfrank/dotfiles.git"
DOTFILES_LOC="$HOME/.dotfiles"

SED=$(which sed)
TR=$(which tr)
SHUF=$(which shuf)

TRUE=0
FALSE=1

PATHS=("/usr/bin" "/bin" "/usr/local/bin" "$HOME/.local/bin")
BIN_PATH=""


# =========================================================================
# Functions
# -------------------------------------------------------------------------

function download_source_files () {
  
}

function generate_passphrase () {
  if [[ "$OS" == "macos" ]]; then
    which_ "gshuf"
    SHUF="$BIN_PATH/gshuf"
  fi

  "$SHUF" --random-source=/dev/random -n 5 "$DICT" | "$TR" A-Z a-z | "$SED" -e ':a' -e 'N' -e '$!ba' -e "s/\\n/-/g" > "$PASSPHRASE_FILE"
  chmod 400 "$PASSPHRASE_FILE"
}


function generate_sshkey () {
  # $1 = key type
  local passphrase
  passphrase=$(<"$PASSPHRASE_FILE" "$TR" -d '\n')
  ssh-keygen -t "$1" -b 4096 -N "$passphrase" -C "${USER}@${HOSTNAME}"
}


function get_operating_system () {
  if type sw_vers >/dev/null 2>&1; then
    if sw_vers | grep -Eq '[m|M]ac'; then
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

  echo "Set operating system as... ${OS}"
}


function install_stow () {
  echo "Installing Stow..."

  local tmp_fle
  local tmp_dir

  tmp_fle=$(mktemp)
  tmp_dir=$(mktemp -d)

  curl -L "$STOW_URL" > "$tmp_fle" 2>/dev/null
  tar -xzf "$tmp_fle" -C "$tmp_dir" --strip-components 1
  pushd "$tmp_dir" >/dev/null
  ./configure --prefix="$HOME"/.local >/dev/null
  make install >/dev/null
  popd >/dev/null
}


function which_ () {
  local bin
  local found

  bin="$1"
  found=1

  for this_path in "${PATHS[@]}"
  do
    if [[ -x "$this_path"/"$bin" ]]; then
      BIN_PATH="$this_path"
      found=0
      break
    fi
  done

  if [[ $found -eq 1 ]]; then
    echo "Error: $bin was not found on the system."
    exit 1
  fi
}


# =========================================================================
# Main
# -------------------------------------------------------------------------

echo "Starting bootstrap..."


#
# Create environment
#
if [[ ! -d "$DEV_DIR" ]]; then mkdir "$DEV_DIR"; fi


#
# Load OS-specific script
#
get_operating_system
. "$OS".sh


#
# Set paths for various packages
#
which_ "pip3"
PIP="$BIN_PATH/pip3"
which_ "git"
GIT="$BIN_PATH/git"
which_ "stow"
STOW="$BIN_PATH/stow"


#
# Create SSH keys
#
generate_passphrase
keep_passphrase="$TRUE"

if [[ ! -e "$HOME/.ssh/id_rsa" ]]; then
  echo "Generating rsa SSH key..."
  generate_sshkey "rsa"
  keep_passphrase="$FALSE"
fi

if [[ ! -e "$HOME/.ssh/id_ed25519" ]]; then
  echo "Generating ed25519 SSH key..."
  generate_sshkey "ed25519"
  keep_passphrase="$FALSE"
fi

if [[ $keep_passphrase -eq "$FALSE" ]]; then
  rm -f "$PASSPHRASE_FILE"
fi


#
# Install Powerline
#
"$PIP" install --user powerline-status powerline-gitstatus


#
# Clone dotfiles repo
#
"$GIT" clone "$DOTFILES_HTTPS" "$DOTFILES_LOC"
pushd "$DOTFILES_LOC" >/dev/null
"$GIT" remote set-url origin "$DOTFILES_GIT"
"$GIT" config core.fileMode false
popd >/dev/null


#
# Stow packages
#
pushd "$DOTFILES_LOC" >/dev/null
shopt -s nullglob
stow_packages=(*/)
for pkg in "${stow_packages[@]}"; do
  "$STOW" -d "$DOTFILES_LOC" -t "$HOME" "$pkg"
done
popd >/dev/null

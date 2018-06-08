#!/usr/bin/env bash

# shellcheck disable=SC2164
set -eu

# ==============================================================================
# Variables
# ==============================================================================


#
# Internal
#
TRUE=0
FALSE=1

EXCEPT=""

OS=""
DATE=$(date +%Y%m%d%H%M%S)
HOSTNAME=$(hostname)

DICT_TMP="$(mktemp)"
DICT_DIR="$HOME/.local/share/dict"
DICT="$DICT_DIR/words"

BASH_DOTFILES_SCRIPT="$HOME/.local/bin/generate-bash-startup"

PASSPHRASE_FILE="$HOME/.ssh/passphrase-$DATE"
PASSPHRASE_WORDS=4
PASSPHRASE_SAVE=$FALSE

PATHS=("$HOME/.local/bin" "/usr/local/bin" "/usr/bin" "/bin")
BIN_PATH="NaN"

#
# Local development structure
#
# ├── Development
# │   ├── Clients
# │   ├── Home
# │   ├── Projects
# │   └── Snippets
# ├── .config
# │   └── dotfiles
# ├── .local
# │   ├── bin
# │   ├── etc
# │   ├── include
# │   ├── lib
# │   ├── opt
# │   ├── share
# │   │   ├── dict
# │   │   │   └── doc
# │   │   ├── doc
# │   │   ├── dotfiles
# │   │   └── man
# │   │       ├── man1
# │   │       ├── man2
# │   │       ├── man3
# │   │       ├── man4
# │   │       ├── man5
# │   │       ├── man6
# │   │       ├── man7
# │   │       ├── man8
# │   │       └── man9
# │   └── var
# └── .ssh
#

DIRECTORIES=(
  "$HOME/Development/{Clients,Home,Projects,Snippets}"
  "$HOME/.config/dotfiles"
  "$HOME/.local/{bin,etc,include,lib,opt,share/{bash,doc,man/man{1..9}},var}"
  "$HOME/.ssh"
  "$DICT_DIR"
)


#
# External
#
GH_URL="https://github.com"
GH_RAW="https://raw.githubusercontent.com"

BOOTSTRAP_REPO="$GH_RAW/bradleyfrank/bootstrap"
BOOTSTRAP_URL="$BOOTSTRAP_REPO/master"
BOOTSTRAP_ASSETS="$BOOTSTRAP_REPO/master/assets"

DOTFILES_HTTPS="https://github.com/bradleyfrank/dotfiles.git"
DOTFILES_GIT="git@github.com:bradleyfrank/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

STOW_URL="https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz"

GIT_REPOS=(
  "$GH_URL/chriskempson/tomorrow-theme.git"
)


# ==============================================================================
# Packages
# ==============================================================================

PYTHON_PACKAGES=(
  powerline-status
  powerline-gitstatus
  pycodestyle
  pydf
  pylint
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
# Builds the ~/.local and ~/Development trees
# ------------------------------------------------------------------------------
function build_local_tree () {
  for directory in "${DIRECTORIES[@]}"
  do
    if [[ ! -d "$directory" ]]; then mkdir -p "$directory"; fi
  done
}


# ------------------------------------------------------------------------------
# Clones the dotfile repo
# ------------------------------------------------------------------------------
function clone_dotfiles_repo () {
  echo -n "Cloning dotfiles repo... "

  if "$GIT" clone "$DOTFILES_HTTPS" "$DOTFILES_DIR" &>/dev/null; then
    pushd "$DOTFILES_DIR" &>/dev/null
    "$GIT" submodule update --init --recursive &>/dev/null
    if [[ $EXCEPT != *"g"* ]]; then
      "$GIT" remote set-url origin "$DOTFILES_GIT"
    fi
    "$GIT" config core.fileMode false
    popd &>/dev/null
    echo "done"

    add_git_hooks
    fix_permissions
  else
    echo "failed"
    exit 1
  fi
}


# ------------------------------------------------------------------------------
# Clones miscellaneous repos
# ------------------------------------------------------------------------------
function clone_repos () {
  local repo_name=""
  local repo_owner=""
  local repo_dir=""

  for repo in "${GIT_REPOS[@]}"
  do
    repo_name=$(basename "$repo")
    repo_owner=$(echo "$repo" | awk -F '/' '{print $4}')
    repo_dir="$HOME/Development/Projects/${repo_owner}__${repo_name%.*}"

    echo -n "Cloning repo $repo_name... "
    if "$GIT" clone "$repo" "$repo_dir" &>/dev/null; then
      echo "done"
    else
      echo "failed"
    fi
  done
}


# ------------------------------------------------------------------------------
# Executes the post-merge script and makes binaries executable
# ------------------------------------------------------------------------------
function fix_permissions () {
  echo -n "Fixing file permissions... "

  chmod 700 "$HOME"/.ssh

  pushd "$DOTFILES_DIR" &>/dev/null
  # shellcheck disable=SC1091
  (. ./.git/hooks/post-merge)
  chmod 750 .
  chmod uo+x ./bin/.local/bin/*
  popd &>/dev/null

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
  "$SHUF" --random-source=/dev/random -n "$PASSPHRASE_WORDS" "$DICT" | tr '[:upper:]' '[:lower:]' | sed -e ':a' -e 'N' -e '$!ba' -e "s/\\n/-/g" > "$PASSPHRASE_FILE"
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

    comment="$USER@$HOSTNAME"
    passphrase=$(< "$PASSPHRASE_FILE" tr -d '\n')

    ssh-keygen -t "$1" -b 4096 -N "$passphrase" -C "$comment" -f "$file" &>/dev/null

    echo "done"
    PASSPHRASE_SAVE=$TRUE
  fi
}


# ------------------------------------------------------------------------------
# Run a quick and dirty check for the Operating System
# ------------------------------------------------------------------------------
function get_operating_system () {
  echo -n "Detecting OS... "

  case "$(uname -s)" in
    Darwin) OS="macos" ;;
    Linux)
      if [ -f /etc/fedora-release ]; then
        OS="fedora"
      elif [ -f /etc/centos-release ]; then
        OS="centos"
      elif [ -f /etc/redhat-release ]; then
        OS="redhat"
      else
        echo "failed"
        exit 1
      fi
      ;;
    *)
      echo "failed"
      exit 1
      ;;
  esac

  echo "$OS"
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

    if ! 7z x "$DICT_TMP" -o"$DICT_DIR/" &>/dev/null; then
      echo "failed"
      exit 1
    else
      mv "$DICT_DIR/dictionary" "$DICT"
      echo "done"
    fi
  else
    echo "done"
  fi
}


# ------------------------------------------------------------------------------
# Compile Stow from source if not installed by system
# ------------------------------------------------------------------------------
function install_stow () {
  whichever "stow"
  if [[ "$BIN_PATH" == "NaN" ]]; then
    echo -n "Installing Stow... "

    local tmp_fle
    local tmp_dir

    tmp_fle=$(mktemp)
    tmp_dir=$(mktemp -d)

    curl -L "$STOW_URL" > "$tmp_fle" 2>/dev/null
    tar -xzf "$tmp_fle" -C "$tmp_dir" --strip-components 1
    pushd "$tmp_dir" &>/dev/null
    ./configure --prefix="$HOME"/.local &>/dev/null
    make &>/dev/null
    make install &>/dev/null
    popd &>/dev/null

    echo "done"
  fi
}


# ------------------------------------------------------------------------------
# Set OS dependant variables
# ------------------------------------------------------------------------------
function set_variables () {
  if [[ "$OS" == "macos" ]]; then
    PIP="pip3"
    SHUF="gshuf"
  elif [[ "$OS" == "fedora" ]]; then
    PIP="pip3"
    SHUF="shuf"
  else
    PIP="pip"
    SHUF="shuf"
  fi
}


# ------------------------------------------------------------------------------
# Download and source OS-specific script as a sub-shell
# ------------------------------------------------------------------------------
function source_remote_file () {
  local script="$BOOTSTRAP_URL/os/$OS.sh"

  if curl --output /dev/null --silent --head --fail "$script"; then
    f=$(mktemp)
    curl -o "$f" -s -L "$script"
    # shellcheck source=/dev/null
    (. "$f")
  else
    echo "OS script not found, skipping... "
  fi
}


# ------------------------------------------------------------------------------
# Stows all packages in the dotfiles repo
# ------------------------------------------------------------------------------
function stow_all () {
  local flags="$1"
  shopt -s nullglob
  stow_packages=(*/)

  for pkg in "${stow_packages[@]}"; do
    _pkg=$(echo "$pkg" | cut -d '/' -f 1)
    echo -n "Stowing $_pkg... "
    "$STOW" -d "$DOTFILES_DIR" -t "$HOME" "$flags" "$_pkg"
    echo "done"
  done
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
    if [[ -x "$this_path/$1" ]]; then
      BIN_PATH="$this_path"
      break
    fi
  done
}


# ==============================================================================
# Main
# ==============================================================================

while getopts 'htux:' flag; do
  case "$flag" in
    h )
      echo "bootstrap.sh - sets up system and configures user profile"
      echo ""
      echo "Usage: bootstrap.sh -h | -t | -u | -x [gprsu]"
      echo ""
      echo "Options:"
      echo "-h    print help menu and exit"
      echo "-t    dumb terminal mode; implies -x gprsu"
      echo "-u    user mode;          implies -x pru"
      echo "-x    except mode: skip the following actions(s):"
      echo "      g    adding ssh remote origin to dotfiles repo [MacOS, Linux]"
      echo "      p    installing system packages [Linux]"
      echo "      r    adding repos [Linux]"
      echo "      s    generating SSH keys [MacOS, Linux]"
      echo "      u    any sudo command [Linux]"
      echo "      y    installing python packages [MacOS, Linux]"
      exit 0
      ;;
    t ) EXCEPT="gprsu" ;;
    u ) EXCEPT="pru" ;;
    x ) EXCEPT="$OPTARG" ;;
    \?) exit 1 ;;
  esac
done


echo ""
echo "__ Starting Bootstrap __"


# ------------------------------------------------------------------------------
# Initializing
# ------------------------------------------------------------------------------

# Find the OS we're running on
get_operating_system

# Make required directory structure ahead of stowing packages
build_local_tree

# Execute per-OS instructions (packages, settings, etc.)
source_remote_file

# Set various per-OS variables
set_variables

# Install stow if not present on the system
install_stow

# ------------------------------------------------------------------------------
# Set paths for various packages
# ------------------------------------------------------------------------------
echo ""
echo "__ Finding Executable Paths __"

# pip
echo -n "Looking for $PIP... "
whichever "$PIP"

if [[ "$BIN_PATH" != "NaN" ]]; then
  PIP="$BIN_PATH/$PIP"
  echo "found"
else
  # Not fatal; just skip installing Python packages
  PIP="NaN"
  echo "failed"
fi

# git
echo -n "Looking for git... "
whichever "git"

if [[ "$BIN_PATH" != "NaN" ]]; then
  GIT="$BIN_PATH/git"
  echo "found"
else
  echo "failed"
  exit 1
fi

# stow
echo -n "Looking for stow... "
whichever "stow"

if [[ "$BIN_PATH" != "NaN" ]]; then
  STOW="$BIN_PATH/stow"
  echo "found"
else
  echo "failed"
  exit 1
fi

# shuf
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

if [[ "$PIP" == "NaN" ]] || [[ "$EXCEPT" == *"y"* ]]; then
  echo "Skipping Python packages... "
else
  for pypkg in "${PYTHON_PACKAGES[@]}"
  do
    echo -n "Installing $pypkg... "
    if "$PIP" install -U --user "$pypkg" -qqq 2>/dev/null; then
      echo "done"
    else
      echo "failed"
    fi
  done
fi


# ------------------------------------------------------------------------------
# Clone dotfiles repo
# ------------------------------------------------------------------------------
echo ""
echo "__ Installing Dotfile Customizations __"

pushd "$HOME" &>/dev/null
if [[ ! -d "$DOTFILES_DIR" ]]; then mkdir "$DOTFILES_DIR"; fi
pushd "$DOTFILES_DIR" &>/dev/null

if ! git status &>/dev/null; then
  popd &>/dev/null
  clone_dotfiles_repo
else
  echo -n "Updating repo... "
  if "$GIT" checkout master &>/dev/null; then
    if "$GIT" pull &>/dev/null; then
      echo "done"
      add_git_hooks
      fix_permissions
    else
      echo "failed"
    fi
  else
    echo "failed"
  fi
  popd &>/dev/null
fi

popd &>/dev/null


# ------------------------------------------------------------------------------
# Stow packages
# ------------------------------------------------------------------------------
pushd "$DOTFILES_DIR" &>/dev/null

if git branch -a | grep -qE "$HOSTNAME" &>/dev/null; then
  # For idempotency: local hostname branch already exists
  "$GIT" checkout master &>/dev/null
  stow_all ""
else
  # Create a local branch for this host; then adopt current configs
  "$GIT" checkout -b "$HOSTNAME" &>/dev/null
  stow_all "--adopt"

  "$GIT" add -A &>/dev/null
  if git commit --dry-run &>/dev/null; then
    # Only commit if there are changes to commit.
    "$GIT" commit -m "Default dotfiles for $HOSTNAME." &>/dev/null
  fi
  "$GIT" checkout master &>/dev/null
  # Reset submodules to dotfiles-specified commit
  "$GIT" submodule foreach git checkout . &>/dev/null
fi

popd &>/dev/null


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
commit=$FALSE

if [[ "$EXCEPT" != *"s"* ]]; then
  # Generate a temporary secure passphrase
  install_dict
  generate_passphrase

  # Loop through keys to generate
  for sshkey in "${sshkeys[@]}"; do
    generate_sshkey "$sshkey"
  done

  # Save or delete temporary passphrase
  if [[ "$PASSPHRASE_SAVE" -eq $FALSE ]]; then
    rm -f "$PASSPHRASE_FILE"
  else
    chmod 400 "$PASSPHRASE_FILE"
  fi

  # Create required SSH files
  for ssh_file in "${ssh_create_files[@]}"; do
    touch_file "$ssh_file" "0600"
  done

  # Add public keys to authorized_keys
  pushd "$HOME"/.ssh &>/dev/null
  shopt -s nullglob
  keys=(*.pub)

  for key in "${keys[@]}"; do
    publickey=$(< "$HOME/.ssh/$key" tr -d '\n')

    if ! grep -rq "$publickey" "$authkeys"; then
      echo -n "Adding $key... "
      echo "$publickey" >> "$authkeys"
      echo "done"
      commit=$TRUE
    fi
  done

  popd &>/dev/null

  if [[ "$commit" -eq $TRUE ]]; then
    pushd "$DOTFILES_DIR" &>/dev/null
    "$GIT" add "$authkeys" &>/dev/null
    "$GIT" commit -m "Added $HOSTNAME keys to authorized_keys." >/dev/null
    popd &>/dev/null
  fi
else
  echo "Skipping SSH key creation... "
fi


# ------------------------------------------------------------------------------
# Post-bootstrap
# ------------------------------------------------------------------------------
echo ""
echo "__ Finishing Up __"

# Clone Git repos for various development resources
clone_repos

# Generate .bashrc and .bash_profile
echo -n "Generating .bashrc and .bash_profile... "
if [[ -x "$BASH_DOTFILES_SCRIPT" ]]; then
  if "$BASH_DOTFILES_SCRIPT"; then
    echo "done"
  else
    echo "failed"
  fi
fi


# ------------------------------------------------------------------------------
# Display results
# ------------------------------------------------------------------------------
echo ""
echo "__ Results __"

if [[ "$PASSPHRASE_SAVE" -eq $TRUE ]]; then
  echo " * SSH Passphrase saved to $PASSPHRASE_FILE"
fi

if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
  echo " * Add id_ed25519 key to GitHub"
elif [[ -f "$HOME/.ssh/id_rsa.pub" ]]; then
  echo " * Add id_rsa key to GitHub"
fi

if [[ "$OS" == "macos" ]]; then
  echo " * Run post-bootstrap"
fi

echo ""
exit 0

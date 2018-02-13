#!/usr/bin/env bash


# =========================================================================
# Variables
# -------------------------------------------------------------------------

BREW_URL="https://raw.githubusercontent.com/Homebrew/install/master/install"
DEFAULTS="/usr/bin/defaults write"

PACKAGES=(
  bash-completion2
  coreutils
  git
  heroku
  markdown
  mosh
  nmap
  p7zip
  python3
  rename
  ruby
  ssh-copy-id
  stow
  thefuck
  tldr
  tmux
  tree
  vim
  wget
  xz
)

CASKS=(
  1password
  docker
  dropbox
  firefox
  google-chrome
  keepingyouawake
  macdown
  slack
  virtualbox
  vlc
)

FONTS=(
  font-inconsolidata
  font-roboto
  font-clear-sans
)


# =========================================================================
# Functions
# -------------------------------------------------------------------------

function get_package_status () {
  package="$1"
  cask="$2"
  brew "$cask" info "$package" 2>&1 | grep -Eq '^Not installed$'
}


function get_user_shell () {
  dscl . -read "$HOME" | grep -E '^UserShell' | awk '{print $2}'
}


# =========================================================================
# Main
# -------------------------------------------------------------------------

#
# Install Xcode
#
if [[ "$(xcode-select -v >/dev/null 2>&1)" -ne "0" ]]; then
  echo "Installing Xcode..."
  xcode-select --install
fi


#
# Install Homebrew
#
if [[ ! -x "$(which brew)" ]]; then
  echo "Installing Homebrew..."
  ruby -e "$(curl -fsSL ${BREW_URL})" >/dev/null
fi


#
# Update homebrew recipes
#
echo "Refreshing Homebrew..."
brew update >/dev/null


#
# Install packages
#
echo "Installing packages..."
for package in "${PACKAGES[@]}"
do
  if get_package_status "$package" ""; then
    echo " - installing $package"
    brew install "$package" >/dev/null
  elif brew outdated "$package" | grep -q "$package"; then
    echo " - upgrading $package"
    brew upgrade "$package"
  fi
done


#
# Install casks
#
echo "Installing casks..."
brew tap caskroom/cask
for cask in "${CASKS[@]}"
do
  if get_package_status "$package" "cask"; then
    brew cask install "$cask" >/dev/null
  fi
done


#
# Install fonts
#
echo "Installing fonts..."
brew tap caskroom/fonts
for font in "${FONTS[@]}"
do
  if get_package_status "$font" "cask"; then
    brew cask install "$font" >/dev/null
  fi
done


#
# Perform cleanup
#
echo "Cleaning up..."
brew cleanup


#
# Upgrade to Bash 4
#
if [ "$(get_user_shell)" != "/usr/local/bin/bash" ]; then
  echo "Upgrading Bash..."
  if [[ "$(grep -q '/usr/local/bin/bash' /etc/shells)" -ne 0 ]]; then
    sudo bash -c "echo '/usr/local/bin/bash' >> /etc/shells"
  fi
  echo -n "Setting default shell... "
  chsh -s /usr/local/bin/bash "$(whoami)"
  get_user_shell
fi


#
# MacOS system defaults
#
echo "Configuring system defaults..."

# ==== App Settings ====

# Prevent Time Machine from prompting to use new hard drives as backup volume
"$DEFAULTS" com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Automatically quit printer app once the print jobs complete
"$DEFAULTS" com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Enable the debug menu in Disk Utility
defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
defaults write com.apple.DiskUtility advanced-image-options -bool true


# ==== Desktop Settings ====

# Set to auto-hide
"$DEFAULTS" com.apple.dock autohide -bool true

# Convert to taskbar
"$DEFAULTS" com.apple.dock static-only -bool true

# Hot corner (bottom-left): show desktop
"$DEFAULTS" com.apple.dock wvous-bl-corner -int 4
"$DEFAULTS" com.apple.dock wvous-bl-modifier -int 0

# Hot corner (bottom-right): screen saver
"$DEFAULTS" com.apple.dock wvous-br-corner -int 5
"$DEFAULTS" com.apple.dock wvous-br-modifier -int 0

# Hot corner (top-left): mission control
"$DEFAULTS" com.apple.dock wvous-tl-corner -int 2
"$DEFAULTS" com.apple.dock wvous-tl-modifier -int 0

# Hot corner (top-right): application windows
"$DEFAULTS" com.apple.dock wvous-tr-corner -int 3
"$DEFAULTS" com.apple.dock wvous-tr-modifier -int 0


# ==== Filesystem Settings ====

# Avoid creating .DS_Store files on network volumes
"$DEFAULTS" com.apple.desktopservices DSDontWriteNetworkStores -bool true


# ==== Finder Settings ====

# Show filename extensions by default
"$DEFAULTS" NSGlobalDomain AppleShowAllExtensions -bool true

# Hide icons for hard drives, servers, and removable media on the desktop"
"$DEFAULTS" com.apple.finder ShowExternalHardDrivesOnDesktop -bool false

# Show status bar by default
"$DEFAULTS" com.apple.finder ShowStatusBar -bool true

# Show Finder breadcrumb menu
"$DEFAULTS" com.apple.finder ShowPathbar -bool true

# Disable the warning when changing a file extension
"$DEFAULTS" com.apple.finder FXEnableExtensionChangeWarning -bool false

# Default view style
"$DEFAULTS" com.apple.finder FXPreferredViewStyle -string "clmv"


# ==== I/O Settings ====

# Enable tap-to-click
"$DEFAULTS" com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
"$DEFAULTS" com.apple.AppleMultitouchtrackpad Clicking -bool true
"$DEFAULTS" -currentHost NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Two finger tap to right-click
"$DEFAULTS" com.apple.driver.AppleBluetoothMultitouch.trackpad trackpadRightClick -bool true

# Enable hand resting
"$DEFAULTS" com.apple.AppleMultitouchtrackpad trackpadHandResting -bool true

# Pinch to zoom
"$DEFAULTS" com.apple.driver.AppleBluetoothMultitouch.trackpad trackpadPinch -bool true

# Two finger rotate
"$DEFAULTS" com.apple.driver.AppleBluetoothMultitouch.trackpad trackpadRotate -bool true

# Two finger horizontal swipe between pages
"$DEFAULTS" NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool true

# Three finger horizontal swipe between pages
"$DEFAULTS" -currentHost NSGlobalDomain com.apple.trackpad.threeFingerHorizSwipeGesture -int 1
"$DEFAULTS" com.apple.driver.AppleBluetoothMultitouch.trackpad trackpadThreeFingerHorizSwipeGesture -int 1
"$DEFAULTS" com.apple.AppleMultitouchtrackpad                  trackpadThreeFingerHorizSwipeGesture -int 1

# Show Notification Center with two finger swipe from fight edge
"$DEFAULTS" -currentHost NSGlobalDomain com.apple.trackpad.twoFingerFromRightEdgeSwipeGesture -int 3
"$DEFAULTS" com.apple.AppleMultitouchtrackpad                  trackpadTwoFingerFromRightEdgeSwipeGesture -int 3
"$DEFAULTS" com.apple.driver.AppleBluetoothMultitouch.trackpad trackpadTwoFingerFromRightEdgeSwipeGesture -int 3

# Smart zoom
"$DEFAULTS" com.apple.driver.AppleBluetoothMultitouch.trackpad trackpadTwoFingerDoubleTapGesture -int 1

# Three finger tap to look up
"$DEFAULTS" com.apple.driver.AppleBluetoothMultitouch.trackpad trackpadThreeFingerTapGesture -int 2


# ==== Safari Settings ====

# Enable the Debug menu
"$DEFAULTS" com.apple.Safari IncludeInternalDebugMenu -bool true

# Enable the Develop menu
"$DEFAULTS" com.apple.Safari IncludeDevelopMenu -bool true

# Enable the Web Inspector
"$DEFAULTS" com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
"$DEFAULTS" com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true


# ==== System Settings ====

# Check for software updates daily
"$DEFAULTS" com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Require password as soon as screensaver or sleep mode starts
"$DEFAULTS" com.apple.screensaver askForPassword -int 1

# Grace period for requiring password to unlock
"$DEFAULTS" com.apple.screensaver askForPasswordDelay -int 5


# ==== Terminal Settings ====

"$DEFAULTS" com.apple.Terminal "Default Window Settings" -string "Novel Custom"
"$DEFAULTS" com.apple.Terminal "Startup Window Settings" -string "Novel Custom"
"$DEFAULTS" write com.apple.terminal StringEncodings -array 4
"$DEFAULTS" com.apple.terminal FontAntialias -bool true
"$DEFAULTS" com.apple.terminal ShowActiveProcessInTitle -bool false
"$DEFAULTS" com.apple.terminal columnCount -float 100.00
#!/usr/bin/env bash

# ==============================================================================
# Variables
# ==============================================================================

BREW_URL="https://raw.githubusercontent.com/Homebrew/install/master/install"
DEFAULTS="/usr/bin/defaults write"

PACKAGES=(
  bash-completion2
  bash-git-prompt
  coreutils
  git
  heroku
  markdown
  mosh
  ncdu
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


# ==============================================================================
# Functions
# ==============================================================================

function install_homebrew {
  _xcode_install
  _brew_install
}


function _xcode_install {
  if ! type xcode-select; then
    echo -n "Installing Xcode... "
    if xcode-select --install; then
      echo "done"
    else
      echo "failed"
      exit 1
    fi
  fi
}


function _brew_install {
  if ! type brew >/dev/null 2>&1; then
    echo -n "Installing Homebrew... "
    if ruby -e "$(curl -fsSL ${BREW_URL})" >/dev/null 2>&1; then
      echo "done"
    else
      echo "failed"
      exit 1
    fi
  fi
}


function install_packages {
  _brew "update" "Updating"
  _pkgs_install
  _cask_install
  _brew "cleanup" "Cleanup up"
}


function _brew {
  echo -n "$2 Homebrew... "
  if brew "$1" >/dev/null 2>&1; then
    echo "done"
  else
    echo "failed"
  fi
}


function _pkgs_install {
  for package in "${PACKAGES[@]}"
  do
    if brew info "$package" 2>&1 | grep -Eq '^Not installed$'; then
      echo -n "Installing $package... "
      if brew install "$package" >/dev/null 2>&1; then
        echo "done"
      else
        echo "failed"
        exit 1
      fi
    elif brew outdated "$package" 2>&1 | grep -q "$package"; then
      echo -n "Upgrading $package... "
      if brew upgrade "$package" >/dev/null 2>&1; then
        echo "done"
      else
        echo "failed"
        exit 1
      fi
    else
      echo "Skipping $package... "
    fi
  done
}


function _cask_install {
  if brew tap caskroom/cask >/dev/null 2>&1; then
    echo "done"
  else
    echo "failed"
    exit 1
  fi

  for cask in "${CASKS[@]}"
  do
    if brew cask info "$cask" 2>&1 | grep -Eq '^Not installed$'; then
      echo -n "Installing cask $cask... "
      if brew cask install "$cask" >/dev/null 2>&1; then
        echo "done"
      else
        echo "failed"
        exit 1
      fi
    else
      echo "Skipping $cask... "
    fi
  done
}


function _font_install {
  echo "Installing fonts..."
  brew tap caskroom/fonts
  for font in "${FONTS[@]}"
  do
    if get_package_status "$font" "cask"; then
      brew cask install "$font" >/dev/null
    fi
  done
}


function upgrade_bash {
  local user_shell
  user_shell=$(dscl . -read "$HOME" | grep -E '^UserShell' | awk '{print $2}')

  if [ "$user_shell" != "/usr/local/bin/bash" ]; then
    if [[ "$(grep -q '/usr/local/bin/bash' /etc/shells)" -ne 0 ]]; then
      sudo bash -c "echo '/usr/local/bin/bash' >> /etc/shells"
    fi
    echo -n "Setting default shell... "
    chsh -s /usr/local/bin/bash "$(whoami)"
    echo "done"
  else
    echo "Bash is up-to-date."
  fi
}


# ==============================================================================
# Main
# ==============================================================================

echo ""
echo "__ Installing Homebrew __"
install_homebrew


echo ""
echo "__ Installing Homebrew __"
install_homebrew


echo ""
echo "__ Upgrading Bash __"
upgrade_bash


echo ""
echo "__ Configuring System __"

# ==== App Settings ====
echo -n "App settings... "

# Prevent Time Machine from prompting to use new hard drives as backup volume
"$DEFAULTS" com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Automatically quit printer app once the print jobs complete
"$DEFAULTS" com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Enable the debug menu in Disk Utility
defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
defaults write com.apple.DiskUtility advanced-image-options -bool true

echo "done"


# ==== Desktop Settings ====
echo -n "Desktop settings... "

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

echo "done"


# ==== Filesystem Settings ====
echo -n "Filesystem settings... "

# Avoid creating .DS_Store files on network volumes
"$DEFAULTS" com.apple.desktopservices DSDontWriteNetworkStores -bool true

echo "done"


# ==== Finder Settings ====
echo -n "Finder settings... "

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

echo "done"


# ==== I/O Settings ====
echo -n "I/O settings... "

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

echo "done"


# ==== Safari Settings ====
echo -n "Safari settings... "

# Enable the Debug menu
"$DEFAULTS" com.apple.Safari IncludeInternalDebugMenu -bool true

# Enable the Develop menu
"$DEFAULTS" com.apple.Safari IncludeDevelopMenu -bool true

# Enable the Web Inspector
"$DEFAULTS" com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
"$DEFAULTS" com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

echo "done"


# ==== System Settings ====
echo -n "System settings... "

# Check for software updates daily
"$DEFAULTS" com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Require password as soon as screensaver or sleep mode starts
"$DEFAULTS" com.apple.screensaver askForPassword -int 1

# Grace period for requiring password to unlock
"$DEFAULTS" com.apple.screensaver askForPasswordDelay -int 5

echo "done"


# ==== Terminal Settings ====
echo -n "Terminal settings... "

"$DEFAULTS" com.apple.Terminal "Default Window Settings" -string "Novel Custom"
"$DEFAULTS" com.apple.Terminal "Startup Window Settings" -string "Novel Custom"
"$DEFAULTS" write com.apple.terminal StringEncodings -array 4
"$DEFAULTS" com.apple.terminal FontAntialias -bool true
"$DEFAULTS" com.apple.terminal ShowActiveProcessInTitle -bool false
"$DEFAULTS" com.apple.terminal columnCount -float 100.00

echo "done"
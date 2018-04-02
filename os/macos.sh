#!/usr/bin/env bash

# ==============================================================================
# Variables
# ==============================================================================

BREW_URL="https://raw.githubusercontent.com/Homebrew/install/master/install"

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
  appcleaner
  bartender
  cyberduck
  docker
  fantastical
  firefox
  google-chrome
  imazing-mini
  istat-menus
  keepingyouawake
  keka
  macdown
  osxfuse
  slack
  spotify
  textmate
  transmit
  unrarx
  virtualbox
  vlc
  xquartz
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
  if ! type xcode-select >/dev/null 2>&1; then
    echo -n "Installing Xcode... "
    if xcode-select --install >/dev/null 2>&1; then
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
    echo -n "Setting default shell... "
    # Also see plugins/macos.sh for /etc/shells edit.
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
echo "__ Installing Packages __"
install_packages


echo ""
echo "__ Upgrading Bash __"
upgrade_bash


echo ""
echo "__ Configuring System __"

# ==== App Settings ====
echo -n "App settings... "

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Enable the debug menu in Disk Utility
defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
defaults write com.apple.DiskUtility advanced-image-options -bool true

# Show Mail attachments as icons
defaults write com.apple.mail DisableInlineAttachmentViewing -bool yes

echo "done"


# ==== Desktop Settings ====
echo -n "Desktop settings... "

# Set Dock to auto-hide
defaults write com.apple.dock autohide -bool true

# Convert Dock to taskbar
defaults write com.apple.dock static-only -bool true

# Disable bouncing Dock icons
defaults write com.apple.dock no-bouncing -bool true

# Hide desktop icons
defaults write com.apple.finder CreateDesktop -bool false

# Set Dock size
defaults write com.apple.dock tilesize -int 43

# Save screenshots to ~/Downloads
defaults write com.apple.screencapture location ~/Downloads

# Save screenshots as PNG
defaults write com.apple.screencapture type -string "png"

# Hot corner (bottom-left): show desktop
defaults write com.apple.dock wvous-bl-corner -int 4
defaults write com.apple.dock wvous-bl-modifier -int 0

# Hot corner (bottom-right): screen saver
defaults write com.apple.dock wvous-br-corner -int 5
defaults write com.apple.dock wvous-br-modifier -int 0

# Hot corner (top-left): mission control
defaults write com.apple.dock wvous-tl-corner -int 2
defaults write com.apple.dock wvous-tl-modifier -int 0

# Hot corner (top-right): application windows
defaults write com.apple.dock wvous-tr-corner -int 3
defaults write com.apple.dock wvous-tr-modifier -int 0

killall Dock
echo "done"


# ==== Filesystem Settings ====
echo -n "Filesystem settings... "

# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

echo "done"


# ==== Finder Settings ====
echo -n "Finder settings... "

# Show filename extensions by default
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Hide icons for hard drives, servers, and removable media on the desktop"
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false

# Show status bar by default
defaults write com.apple.finder ShowStatusBar -bool true

# Show Finder breadcrumb menu
defaults write com.apple.finder ShowPathbar -bool true

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Default view style
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Unhide user library
chflags nohidden ~/Library

# Set default location for new windows
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Downloads/"

# Disable creation of .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

echo "done"


# ==== Interface Settings ====
echo -n "Interface settings... "

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

echo "done"


# ==== I/O Settings ====
echo -n "I/O settings... "

# Enable tap-to-click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.AppleMultitouchtrackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Two finger tap to right-click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad trackpadRightClick -bool true

# Enable hand resting
defaults write com.apple.AppleMultitouchtrackpad trackpadHandResting -bool true

# Pinch to zoom
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad trackpadPinch -bool true

# Two finger rotate
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad trackpadRotate -bool true

# Two finger horizontal swipe between pages
defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool true

# Three finger horizontal swipe between pages
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 1
defaults write com.apple.AppleMultitouchtrackpad TrackpadThreeFingerHorizSwipeGesture -int 1

# Show Notification Center with two finger swipe from fight edge
defaults write com.apple.AppleMultitouchtrackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3

# Smart zoom
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad trackpadTwoFingerDoubleTapGesture -int 1

# Three finger tap to look up
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad trackpadThreeFingerTapGesture -int 2

# Set very low key repeat rates
defaults write NSGlobalDomain InitialKeyRepeat -int 25
defaults write NSGlobalDomain KeyRepeat -int 1

echo "done"


# ==== Safari Settings ====
echo -n "Safari settings... "

# Enable the Debug menu
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

# Enable the Develop menu
defaults write com.apple.Safari IncludeDevelopMenu -bool true

# Enable the Web Inspector
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

echo "done"


# ==== System Settings ====
echo -n "System settings... "

# Check for software updates daily
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Set screensaver idle time
defaults -currentHost write com.apple.screensaver idleTime 300

# Require password as soon as screensaver or sleep mode starts
defaults write com.apple.screensaver askForPassword -int 1

# Grace period for requiring password to unlock
defaults write com.apple.screensaver askForPasswordDelay -int 5

# Require admin to make System Preference changes
sysprefs=$(mktemp)
security authorizationdb read system.preferences > "$sysprefs" 2>/dev/null /usr/libexec/PlistBuddy -c "Set :shared false" "$sysprefs"
security authorizationdb write system.preferences < "$sysprefs" 2>/dev/null

echo "done"


# ==== Terminal Settings ====
echo -n "Terminal settings... "

# Default profile
defaults write com.apple.Terminal "Default Window Settings" -string "Solarized Dark"
defaults write com.apple.Terminal "Startup Window Settings" -string "Solarized Dark"

# Make new tabs open in default directory
defaults write com.apple.Terminal NewTabWorkingDirectoryBehavior -int 1

# Set default Shell to updated Bash
defaults write com.apple.Terminal Shell -string "/usr/local/bin/bash"

echo "done"
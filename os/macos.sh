#!/usr/bin/env bash

# ==============================================================================
# Variables
# ==============================================================================

BREW_URL="https://raw.githubusercontent.com/Homebrew/install/master/install"

PACKAGES=(
  awscli
  bash-completion2
  bash-git-prompt
  binutils
  cabextract
  coreutils
  diffutils
  findutils
  gawk
  git
  git-flow
  glances
  gnu-sed
  gnu-tar
  gnu-which
  grep
  gzip
  heroku
  hh
  less
  make
  markdown
  mas
  mosh
  most
  ncdu
  nmap
  p7zip
  python3
  rename
  rpm2cpio
  rsync
  ruby
  shellcheck
  shfmt
  ssh-copy-id
  stow
  thefuck
  tldr
  tmux
  tree
  vim
  watch
  wget
  xz
  youtube-dl
)

FONTS=(
  font-clear-sans
  font-inconsolidata
  font-roboto
  font-source-code-pro
  font-source-code-pro-for-powerline
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
  _brew "update" "Updating Homebrew"
  _pkgs_install
  _font_install
  _brew "cleanup" "Cleaning up Homebrew"
}


function _brew {
  echo -n "$2... "
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
      fi
    elif brew outdated "$package" 2>&1 | grep -q "$package"; then
      echo -n "Upgrading $package... "
      if brew upgrade "$package" >/dev/null 2>&1; then
        echo "done"
      else
        echo "failed"
      fi
    else
      echo "Skipping $package... "
    fi
  done
}


function _font_install {
  brew tap caskroom/fonts

  for font in "${FONTS[@]}"
  do
    if brew cask info "$font" 2>&1 | grep -Eq '^Not installed$'; then
      echo -n "Installing font $font... "
      if brew cask install "$font" >/dev/null 2>&1; then
        echo "done"
      else
        echo "failed"
      fi
    fi
  done
}


function set_macos_defaults {
  _defaults_app
  _defaults_desktop
  _defaults_filesystem
  _defaults_interface
  _defaults_io
  _defaults_system

  killall Dock
}


function _defaults_app {
  echo -n "App settings... "

  # ==== Time Machine ====

  # Prevent Time Machine from prompting to use new hard drives as backup volume
  defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

  # ==== Disk Utility ====

  # Enable the debug menu in Disk Utility
  defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
  defaults write com.apple.DiskUtility advanced-image-options -bool true

  # ==== Mail ====

  # Show most recent messages at the top
  defaults write com.apple.mail ConversationViewSortDescending -int 1

  # ==== Safari ====

  # Enable the Debug menu
  defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

  # Enable the Develop menu
  defaults write com.apple.Safari IncludeDevelopMenu -bool true

  # Enable the Web Inspector
  defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
  defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

  # Disable Safari autofills
  defaults write com.apple.safari autofillfromaddressbook -bool false
  defaults write com.apple.safari autofillpasswords -bool false
  defaults write com.apple.safari autofillcreditcarddata -bool false
  defaults write com.apple.safari autofillmiscellaneousforms -bool false

  # ==== Terminal ====

  # Make new tabs open in default directory
  defaults write com.apple.Terminal NewTabWorkingDirectoryBehavior -int 1

  # Set default Shell to updated Bash
  defaults write com.apple.Terminal Shell -string "/usr/local/bin/bash"

  # ==== TextEdit ====

  # Use Plain Text Mode as Default
  defaults write com.apple.TextEdit RichText -int 0

  echo "done"
}


function _defaults_desktop {
  echo -n "Desktop settings... "

  # Show filename extensions by default
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true

  # Disable creation of .DS_Store files on network volumes
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

  # ==== Finder ====

  # Hide icons for hard drives, servers, and removable media on the desktop"
  defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
  defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
  defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false
  defaults write com.apple.finder ShowMountedServersOnDesktop -bool false

  # Show status bar by default
  defaults write com.apple.finder ShowStatusBar -bool true

  # Show Finder breadcrumb menu
  defaults write com.apple.finder ShowPathbar -bool true

  # Disable the warning before emptying the Trash
  defaults write com.apple.finder WarnOnEmptyTrash -bool false

  # Disable the warning when changing a file extension
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

  # Avoid creating .DS_Store files on network volumes
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

  # Default view style
  defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

  # Unhide user library
  chflags nohidden ~/Library

  # Set default location for new windows
  defaults write com.apple.finder NewWindowTarget -string "PfLo"
  defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Downloads/"

  # Hide desktop icons
  defaults write com.apple.finder CreateDesktop -bool false

  # ==== Dock ====

  # Set Dock to auto-hide
  defaults write com.apple.dock autohide -bool true

  # Convert Dock to taskbar
  defaults write com.apple.dock static-only -bool true

  # Disable bouncing Dock icons
  defaults write com.apple.dock no-bouncing -bool true

  # Set Dock size
  defaults write com.apple.dock tilesize -int 43

  # ==== Screenshots ====

  # Save screenshots to ~/Downloads
  defaults write com.apple.screencapture location ~/Downloads

  # Save screenshots as PNG
  defaults write com.apple.screencapture type -string "png"

  # ==== Expose ====

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

  # Disable automatically rearranging Spaces
  defaults write com.apple.dock mru-spaces -bool false

  echo "done"
}


function _defaults_interface {
  echo -n "Interface settings... "

  # Expand save panel by default
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

  # Quit printer app after print jobs complete
  defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

  echo "done"
}


function _defaults_io {
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
}


function _defaults_system {
  echo -n "System settings... "

  # ==== Security Settings ====

  # Require password as soon as screensaver or sleep mode starts
  defaults write com.apple.screensaver askForPassword -int 1

  # Grace period for requiring password to unlock
  defaults write com.apple.screensaver askForPasswordDelay -int 5

  # ==== System Updates ====

  # Check for software updates daily
  defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

  # ==== Power Settings ====

  # Set screensaver idle time
  defaults -currentHost write com.apple.screensaver idleTime 300

  # Put display to sleep after 5 Minutes of inactivity
  sudo pmset displaysleep 5

  # Put Computer to Sleep after 15 Minutes of Inactivity
  sudo pmset sleep 15

  # Set System Sleep Idle Time to 60 Minutes
  sudo systemsetup -setcomputersleep 60

  echo "done"
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
echo "__ Configuring System __"
set_macos_defaults

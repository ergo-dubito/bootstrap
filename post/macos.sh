#!/usr/bin/env bash

# ==============================================================================
# Variables
# ==============================================================================

_HOSTNAME="Brads-Mac"

MAS_APPS=(
  # 1Blocker
  1107421413
  # OneDrive
  823766827
  # Deliveries
  924726344
  # Evernote
  406056744
  # Pixelmator
  407963104
  # Reeder 3
  880001334
  # Twitterific
  1289378661
  # The Unarchiver
  425424353
)

CASKS=(
  1password
  appcleaner
  bartender
  coda
  docker
  fantastical
  firefox
  google-backup-and-sync
  google-chrome
  imazing-mini
  istat-menus
  keepingyouawake
  keka
  macdown
  osxfuse
  plexamp
  sip
  slack
  spotify
  textmate
  transmit
  tripmode
  unrarx
  virtualbox
  vlc
  xquartz
)


# ==============================================================================
# Main
# ==============================================================================

while getopts 'hn:' flag; do
  case "${flag}" in
    h )
      echo "macos.sh - configures system resources that require sudo access"
      echo ""
      echo "Usage: macos.sh [-hn]"
      echo ""
      echo "Options:"
      echo "-h    print help menu and exit"
      echo "-n    sets hostname"
      exit 0
      ;;
    n ) _HOSTNAME="$OPTARG" ;;
    \?) exit 1 ;;
  esac
done


#
# Install HomeBrew casks
#
echo "Installing Homebrew casks... "

brew tap caskroom/cask
for cask in "${CASKS[@]}"
do
  if brew cask info "$cask" 2>&1 | grep -Eq '^Not installed$'; then
    brew cask install "$cask"
  fi
done


#
# Install Mac App Store apps
#
for app in "${MAS_APPS[@]}"
do
  mas install "$app"
done


#
# Require admin to make System Preference changes
#
echo "Securing System Preferences... "

sysprefs=$(mktemp)
security authorizationdb read system.preferences > "$sysprefs" 2>/dev/null
/usr/libexec/PlistBuddy -c "Set :shared false" "$sysprefs"
security authorizationdb write system.preferences < "$sysprefs" 2>/dev/null


#
# Add Bash 4 to global shell conf
#
echo "Adding Bash 4 to available shells... "

if ! grep -q '/usr/local/bin/bash' /etc/shells; then
  sudo bash -c "echo '/usr/local/bin/bash' >> /etc/shells"
fi


#
# Set hostname
#
echo "Setting hostname to ${_HOSTNAME}... "

sudo scutil --set HostName "${_HOSTNAME}.local"
sudo scutil --set LocalHostName "${_HOSTNAME}"
sudo scutil --set ComputerName "${_HOSTNAME}"
sudo dscacheutil -flushcache


#
# Start locate daemon
#
echo "Starting locate daemon... "

sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist


#
# Configure power settings
#
echo "Modifying power settings... "

sudo pmset displaysleep 30
sudo systemsetup -setcomputersleep Never


#
# Enable firewall
#
echo "Enabling the firewall... "

if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -q "disabled"; then
  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
fi


#
# Enable FileVault
#
echo "Enabling FileVault... "

if ! fdesetup isactive; then
  sudo fdesetup enable
fi
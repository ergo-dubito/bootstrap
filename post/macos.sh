#!/bin/bash

MAS_APPS=(
  # 1Blocker
  1107421413
  # OneDrive
  823766827
  # Deliveries
  924726344
  # Evernote
  406056744
  # Microsoft Remote Desktop
  715768417
  # PasteBot
  1179623856
  # Pixelmator
  407963104
  # Reeder 3
  880001334
  # Twitterific
  1289378661
  # The Unarchiver
  425424353
  # Bumbpr
  1166066070
)

CASKS=(
  1password
  anaconda
  anaconda2
  appcleaner
  bartender
  box-sync
  coda
  docker
  fantastical
  fedora-media-writer
  firefox
  gmvault
  google-backup-and-sync
  google-chrome
  imazing-mini
  istat-menus
  keepassx
  keepingyouawake
  keka
  macdown
  musicbrainz-picard
  osxfuse
  plexamp
  pycharm
  sourcetree
  spotify
  textmate
  transmit
  tripmode
  typora
  unrarx
  vlc
  xquartz
)


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
echo "Installing Mac App Store apps... "

for app in "${MAS_APPS[@]}"
do
  mas install "$app"
done

#!/usr/bin/env bash

# Ensure the script is run as root
if [[ "$USER" != "root" ]]; then
  echo "Must be run with sudo/root."
  exit 1
fi

# Require admin to make System Preference changes
sysprefs=$(mktemp)
security authorizationdb read system.preferences > "$sysprefs" 2>/dev/null
/usr/libexec/PlistBuddy -c "Set :shared false" "$sysprefs"
security authorizationdb write system.preferences < "$sysprefs" 2>/dev/null

# Add Bash 4 to global shell conf
if ! grep -q '/usr/local/bin/bash' /etc/shells; then
  bash -c "echo '/usr/local/bin/bash' >> /etc/shells"
fi

# Set hostname
scutil --set HostName Brads-Mac.local
scutil --set LocalHostName Brads-Mac
scutil --set ComputerName Brads-Mac

dscacheutil -flushcache

# Start locate daemon
launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist

# Configure power settings
pmset displaysleep 30
systemsetup -setcomputersleep Never

# Enable firewall
if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -q "disabled"; then
  /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
fi

# Enable FileVault
if ! fdesetup isactive; then
  fdesetup enable
fi
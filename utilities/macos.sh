#!/usr/bin/env bash

# Run this script as root

# Set hostname
scutil --set HostName Brads-Mac.local
scutil --set LocalHostName Brads-Mac
scutil --set ComputerName Brads-Mac

dscacheutil -flushcache

# Configure power settings
pmset displaysleep 30
systemsetup -setcomputersleep Never

# Enable firewall
/usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Enable FileVault
fdesetup enable
#!/bin/bash

#region mac-specific
if os Darwin; then
  # @description Shows hidden files in Finder.
  alias show-files='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder /System/Library/CoreServices/Finder.app'

  # @description Hides hidden files in Finder.
  alias hide-files='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder /System/Library/CoreServices/Finder.app'

  # @description Hides desktop icons in Finder.
  alias hide-desktop-icons='defaults write com.apple.finder CreateDesktop FALSE && killall Finder'

  # @description Shows desktop icons in Finder.
  alias show-desktop-icons='defaults write com.apple.finder CreateDesktop TRUE && killall Finder'

  # @description Flushes DNS cache.
  alias flushdns='sudo killall -HUP mDNSResponder;sudo killall mDNSResponderHelper;sudo dscacheutil -flushcache'

  # @description Sets the desktop wallpaper.
  # @arg $1 string The name of the image file for the wallpaper.
  function set-wallpaper {
    osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$(pwd)/$1\""
  }
fi
#endregion

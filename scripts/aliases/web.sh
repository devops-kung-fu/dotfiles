#!/bin/bash

#region web
# @description Downloads a website for offline viewing using wget with mirroring.
# @arg $1 string The URL of the website to be downloaded.
function webvacuum {
  wget --mirror         \
    --convert-links     \
    --html-extension    \
    --wait=2            \
    -o log              \
    "$1"
}
#endregion

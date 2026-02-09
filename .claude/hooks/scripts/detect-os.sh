#!/bin/bash
# Detect operating system
# Returns: macos, linux, windows, or unknown

os_name=$(uname -s)

case "$os_name" in
  Darwin*)
    echo "macos"
    ;;
  Linux*)
    echo "linux"
    ;;
  CYGWIN*|MINGW*|MSYS*)
    echo "windows"
    ;;
  *)
    echo "unknown"
    ;;
esac

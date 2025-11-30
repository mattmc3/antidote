#!/bin/sh

BUNDLE_ID="$1"
[ -n "$1" ] || exit 1

# Determine antidote's home.
if [ -z "$ANTIDOTE_HOME" ]; then
  # Figure out the OS type
  if [ -z "$ANTIDOTE_OSTYPE" ]; then
    if [ -n "$OSTYPE" ]; then
      ANTIDOTE_OSTYPE="$OSTYPE"
    else
      ANTIDOTE_OSTYPE="$(uname -s | tr '[:upper:]' '[:lower:]')"
    fi
  fi

  case "$ANTIDOTE_OSTYPE" in
    darwin*)
      ANTIDOTE_HOME="$HOME/Library/Caches/antidote"
      ;;
    cygwin*|msys*)
      ANTIDOTE_HOME="${LOCALAPPDATA:-$LocalAppData}"
      case "$ANTIDOTE_HOME" in
        *\\*) ANTIDOTE_HOME="$ANTIDOTE_HOME\\antidote"  ;;
        *)    ANTIDOTE_HOME="$ANTIDOTE_HOME/antidote" ;;
      esac
      if command -v cygpath >/dev/null 2>&1; then
        ANTIDOTE_HOME="$(cygpath "$ANTIDOTE_HOME")"
      fi
      ;;
    *)
      ANTIDOTE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}/antidote"
      ;;
  esac
fi

# Bundle name is the last component
BUNDLE_NAME="${BUNDLE_ID%/}" # strip trailing /
BUNDLE_NAME="${BUNDLE_NAME%.git}" # strip trailing .git
BUNDLE_NAME="${BUNDLE_NAME##*/}"

# Set the bundle type.
case "$BUNDLE_ID" in
  \$*|~*|/*)
    BUNDLE_TYPE=path
    BUNDLE_PATH="$BUNDLE_ID"
    ;;
  http://*|https://*|ssh@*|git@*)
    BUNDLE_TYPE=repo
    BUNDLE_URL="$BUNDLE_ID"
    ;;
  */*/*)
    BUNDLE_TYPE='?'
    ;;
  */*)
    BUNDLE_TYPE=repo
    BUNDLE_URL="${ANTIDOTE_GIT_SITE:-https://github.com}/$BUNDLE_ID"
    ;;
  *)
    BUNDLE_TYPE=custom
    ;;
esac

# Output variables
[ -n "$ANTIDOTE_HOME" ] && printf '%s\n' "ANTIDOTE_HOME=\"${ANTIDOTE_HOME}\""
[ -n "$BUNDLE_ID" ] && printf '%s\n' "BUNDLE_ID=\"${BUNDLE_ID}\""
[ -n "$BUNDLE_NAME" ] && printf '%s\n' "BUNDLE_NAME=\"${BUNDLE_NAME}\""
[ -n "$BUNDLE_TYPE" ] && printf '%s\n' "BUNDLE_TYPE=\"${BUNDLE_TYPE}\""
[ -n "$BUNDLE_URL" ] && printf '%s\n' "BUNDLE_URL=\"${BUNDLE_URL}\""
[ -n "$BUNDLE_PATH" ] && printf '%s\n' "BUNDLE_PATH=\"${BUNDLE_PATH}\""

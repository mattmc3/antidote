#!/bin/sh

antidote_home() {
  # Determine antidote's home.
  if [ -z "$ANTIDOTE_HOME" ]; then
    # shellcheck disable=SC3028
    ANTIDOTE_OSTYPE="${ANTIDOTE_OSTYPE:-${OSTYPE:-$(uname -s | tr '[:upper:]' '[:lower:]')}}"

    case "$ANTIDOTE_OSTYPE" in
      darwin*)
        ANTIDOTE_HOME="$HOME/Library/Caches/antidote"
        ;;
      cygwin*|msys*)
        ANTIDOTE_HOME="${LOCALAPPDATA:-$LocalAppData}/antidote"
        if command -v cygpath >/dev/null 2>&1; then
          ANTIDOTE_HOME="$(cygpath "$ANTIDOTE_HOME")"
        else
          ANTIDOTE_HOME="$(printf '%s' "$ANTIDOTE_HOME" | tr \\ /)"
        fi
        ;;
      *)
        ANTIDOTE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}/antidote"
        ;;
    esac
  fi
  printf '%s\n' "$ANTIDOTE_HOME"
}

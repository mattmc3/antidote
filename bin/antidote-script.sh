#!/bin/sh

# ANSI record separator
# RS=$(printf '\036')

# Helpers
die()  { ERR=$1; shift; warn "$@"; exit "$ERR"; }
say()  { printf '%s\n' "$@"; }
warn() { say "$@" >&2; }
emit() { printf "${INDENT}%s\n" "$@"; }

script_fpath() {
  if [ "$O_FPATH_RULE" = append ]; then
    say "\$fpath+=( \"$1\" )"
  else
    say "\$fpath=( \"$1\" \$fpath )"
  fi
}

# The first param is the bundle.
BUNDLE="$1"
if [ -z "$BUNDLE" ]; then
  die 1 "antidote: error: bundle argument expected"
fi
shift

# Replace ~/ with $HOME/
# shellcheck disable=SC2088
case "$BUNDLE" in
  '~/'*)
    BUNDLE="$HOME/${BUNDLE#'~/'}"
    ;;
esac

# Set reasonable defaults
INDENT=
SOURCE_CMD=source
O_KIND=zsh
O_FPATH_RULE=append

# Parse flags and annotation parameters.
while [ $# -gt 0 ]; do
  case "$1" in
    --skip-load-defer)
      #O_SKIP_LOAD_DEFER=1
      ;;
    *:*)
      # Extract prefix and suffix
      _prefix="${1%%:*}"
      _suffix="${1#*:}"

      # Match against known annotations.
      case "$_prefix" in
        kind)         O_KIND="$_suffix" ;;
        path)         O_PATH="$_suffix" ;;
        #branch)       O_BRANCH="$_suffix" ;;
        autoload)     O_AUTOLOAD="$_suffix" ;;
        conditional)  O_COND="$_suffix" ;;
        pre)          O_PRE="$_suffix" ;;
        post)         O_POST="$_suffix" ;;
        fpath-rule)   O_FPATH_RULE="$_suffix" ;;
        *)            warn "Unknown annotation: $_prefix" ;;
      esac
      ;;
    *)
      warn "Invalid parameter format: $1"
      ;;
  esac
  shift
done

# Validate O_KIND
case "$O_KIND" in
  autoload|clone|defer|fpath|path|zsh) ;;
  *) die 1 "antidote: error: unexpected kind value: $O_KIND" ;;
esac

# Validate O_FPATH_RULE
case "$O_FPATH_RULE" in
  append|prepend) ;;
  *) die 1 "antidote: error: unexpected fpath-rule value: $O_FPATH_RULE" ;;
esac

# Set vars
ANTIDOTE_HOME="${ANTIDOTE_HOME:-$HOME/.cache/antidote}" # TODO: Fix this
ZSH_DEFER_BUNDLE="${ZSH_DEFER_BUNDLE:-romkatv/zsh-defer}"

BUNDLE_HOME=$BUNDLE
BUNDLE_PATH="${BUNDLE_HOME}"
if [ -n "$O_PATH" ]; then
  BUNDLE_PATH="${BUNDLE_HOME}/${O_PATH}"
fi

# Extract bundle name (last path component)
BUNDLE_NAME="${BUNDLE##*/}"
BUNDLE_INIT="${BUNDLE_PATH}/${BUNDLE_NAME}.plugin.zsh"

FPATH_SCRIPT="$(script_fpath "$BUNDLE_PATH")"

# Wrap everything in a conditional.
if [ -n "$O_COND" ]; then
  emit "if $O_COND; then"
  INDENT="  "
fi

# Pre
[ -n "$O_PRE" ] && emit "$O_PRE"

# handle autoloading before sourcing
if [ -n "$O_AUTOLOAD" ]; then
  _fpath_line="$(script_fpath "$BUNDLE_PATH/$O_AUTOLOAD")"
  emit "$_fpath_line"
  emit "builtin autoload -Uz \"${BUNDLE_PATH}/${O_AUTOLOAD}\"/*(N.:t)"
fi

if [ "$O_KIND" = fpath ]; then
  emit "$FPATH_SCRIPT"
elif [ "$O_KIND" = path ]; then
  emit "export PATH=\"$BUNDLE_PATH:\$PATH\""
elif [ "$O_KIND" = autoload ]; then
  emit "$FPATH_SCRIPT"
  emit "builtin autoload -Uz "${BUNDLE_PATH}"/*(N.:t)"
elif [ "$O_KIND" = zsh ]; then
  emit "$FPATH_SCRIPT"
  if [ -f "$BUNDLE_PATH" ]; then
    # Bundle path is a file
    emit "${SOURCE_CMD} \"${BUNDLE_PATH}\""
  elif [ -f "$BUNDLE_INIT" ]; then
    # Use the bundle's .plugin.zsh file
    emit "${SOURCE_CMD} \"${BUNDLE_INIT}\""
  else
    # Fallback: source the directory (will fail, but matches old behavior)
    emit "${SOURCE_CMD} \"${BUNDLE_PATH}\""
  fi
fi

# Output variables
# [ -n "$BUNDLE" ] && say "BUNDLE: $BUNDLE"
# [ -n "$O_KIND" ] && say "O_KIND: $O_KIND"
# [ -n "$O_PATH" ] && say "O_PATH: $O_PATH"
# [ -n "$O_BRANCH" ] && say "O_BRANCH: $O_BRANCH"
# [ -n "$O_AUTOLOAD" ] && say "O_AUTOLOAD: $O_AUTOLOAD"
# [ -n "$O_COND" ] && say "O_COND: $O_COND"
# [ -n "$O_PRE" ] && say "O_PRE: $O_PRE"
# [ -n "$O_POST" ] && say "O_POST: $O_POST"
# [ -n "$O_FPATH_RULE" ] && say "O_FPATH_RULE: $O_FPATH_RULE"
# [ -n "$O_SKIP_LOAD_DEFER" ] && say "O_SKIP_LOAD_DEFER: $O_SKIP_LOAD_DEFER"




# Post
[ -n "$O_POST" ] && emit "$O_POST"

# If everything was wrapped in a conditional, end it.
INDENT=
[ -n "$O_COND" ] && emit "fi"

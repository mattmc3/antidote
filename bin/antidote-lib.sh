#!/bin/sh

# Helpers
die()  { ERR=$1; shift; warn "$@"; exit "$ERR"; }
say()  { printf '%s\n' "$@"; }
warn() { say "$@" >&2; }
emit() { printf "${INDENT}%s\n" "$@"; }

is_sourced() {
  if [ -n "$ZSH_VERSION" ]; then
    case $ZSH_EVAL_CONTEXT in *:file:*) return 0;; esac
  else  # Add additional POSIX-compatible shell names here, if needed.
    case ${0##*/} in dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 0;; esac
  fi
  return 1
}

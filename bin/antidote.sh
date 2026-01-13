#!/bin/sh
# shellcheck disable=SC2120,SC3043

# Helpers
die()    { warn "$@"; exit "${ERR:-1}"; }
say()    { printf '%s\n' "$@"; }
warn()   { say "$@" >&2; }
emit()   { printf "${INDENT}%s\n" "$@"; }
noop()   { :; }
is_cmd() { command -v "$1" >/dev/null 2>&1; }
is_cmd local || alias local=noop

# Globals
# NL=$'\n'
# TAB=$'\t'
# SEP=$'\x1F'
INDENT=

script_fpath() {
  if [ "${O_FPATH_RULE:-append}" = append ]; then
    say "\$fpath+=( \"$1\" )"
  else
    say "\$fpath=( \"$1\" \$fpath )"
  fi
}

cache_dir() {
  local result
  result="${XDG_CACHE_HOME:-$HOME/.cache}"
  case "$ANTIDOTE_OSTYPE" in
    darwin*)
      result="$HOME/Library/Caches"
      ;;
    cygwin*|msys*)
      result="${LOCALAPPDATA:-$LocalAppData}"
      if command -v cygpath >/dev/null 2>&1; then
        result="$(cygpath "$result")"
      fi
      ;;
  esac
  say "$result"
  unset result
}

# Print the OS specific temp dir.
temp_dir() {
  tmpd=/tmp
  # Use TMPDIR if it has a value and is better than /tmp
  if [ -n "$TMPDIR" ]; then
    if [ -d "$TMPDIR" ] && [ -w "$TMPDIR" ]; then
      # TMPDIR exists and is writable?
      tmpd="${TMPDIR%/}"
    elif [ ! -d /tmp ] || [ ! -w /tmp ]; then
      # Else use TMPDIR only if /tmp is unusable
      tmpd="${TMPDIR%/}"
    fi
  fi
  say "$tmpd"
}

antidote_help() {
  case "$1" in
    bundle)  say "$ANTIDOTE_BUNDLE_HELP"  ;;
    help)    say "$ANTIDOTE_HELP"         ;;
    home)    say "$ANTIDOTE_HOME_HELP"    ;;
    init)    say "$ANTIDOTE_INIT_HELP"    ;;
    list)    say "$ANTIDOTE_LIST_HELP"    ;;
    path)    say "$ANTIDOTE_PATH_HELP"    ;;
    purge)   say "$ANTIDOTE_PURGE_HELP"   ;;
    update)  say "$ANTIDOTE_UPDATE_HELP"  ;;
    *)       say "$ANTIDOTE_HELP"         ;;
  esac
}

antidote_bundle() {
  antidote_script "$@"
}

antidote_home() {
  local cachedir slash
  if [ $# -gt 0 ]; then
    die "antidote: error: unexpected '$1'."
  fi
  if [ -n "$ANTIDOTE_HOME" ]; then
    say "$ANTIDOTE_HOME"
  else
    # Use forward slashes unless everything is a backslash.
    slash='/'
    cachedir="$(cache_dir)"
    case "$cachedir" in
      *\\*)
        case "$cachedir" in
          */*) ;;
          *) slash=\\ ;;
        esac
        ;;
    esac
    say "${cachedir}${slash}antidote"
  fi
}

antidote_init() {
  say "#!/usr/bin/env zsh"
  say "function antidote {"
  say "  case \"\$1\" in"
  say "    bundle)"
  say "      source <( \"${ANTIDOTE_SCRIPT}\" \"\$@\" ) || \"${ANTIDOTE_SCRIPT}\" \"\$@\""
  say "      ;;"
  say "    *)"
  say "      \"${ANTIDOTE_SCRIPT}\" \"\$@\""
  say "      ;;"
  say "  esac"
  say "}"
}

antidote_list() {
  :
}

antidote_purge() {
  :
}

antidote_path() {
  if [ -z "$1" ]; then
    die "antidote: error: required argument 'bundle' not provided"
  fi
  bundle_info "$1"
  if [ -e "$BUNDLE_PATH" ]; then
    say "$BUNDLE_PATH"
  else
    die "antidote: error: '$1' does not exist in cloned paths"
  fi
}

antidote_update() {
  :
}

antidote_script() {
  # The first param is the bundle.
  if [ -z "$1" ]; then
    die "antidote: error: bundle argument expected"
  fi

  # Replace ~/ with $HOME/
  # shellcheck disable=SC2088
  case "$1" in
    '~/'*)
      BUNDLE="$HOME/${1#'~/'}"
      ;;
    *)
      BUNDLE="$1"
      ;;
  esac
  shift

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
    *) die "antidote: error: unexpected kind value: $O_KIND" ;;
  esac

  # Validate O_FPATH_RULE
  case "$O_FPATH_RULE" in
    append|prepend) ;;
    *) die "antidote: error: unexpected fpath-rule value: $O_FPATH_RULE" ;;
  esac

  # Set vars
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
    emit "builtin autoload -Uz \"${BUNDLE_PATH}\"/*(N.:t)"
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
}

antidote_version() {
  local ver gitsha
  ver="$ANTIDOTE_VERSION"
  if [ "$ANTIDOTE_DEBUG" != true ]; then
    gitsha="$(gitcmd -C "$ANTIDOTE_PROJDIR" rev-parse --short HEAD 2>/dev/null)"
    [ -n "$gitsha" ] && ver="$ver ($gitsha)"
  fi
  say "antidote version $ver"
}

reset_bundle_vars() {
  BUNDLE_ID=
  BUNDLE_NAME=
  BUNDLE_TYPE=
  BUNDLE_REPO=
  BUNDLE_URL=
  BUNDLE_PATH=
}

bundle_info() {
  local scrubbed last second_last
  reset_bundle_vars

  [ -n "$1" ] || return 1
  BUNDLE_ID="$1"
  scrubbed="${BUNDLE_ID%/}" # strip trailing slash
  scrubbed="${scrubbed%.git}" # strip trailing .git

  # Initialize bundle vars.
  BUNDLE_NAME="${scrubbed##*/}"

  # Set the bundle type.
  case "$BUNDLE_ID" in
    \$*|~*|/*)
      BUNDLE_TYPE=path
      BUNDLE_PATH="$BUNDLE_ID"
      ;;
    http://*|https://*|ssh@*|git@*)
      BUNDLE_TYPE=repo
      BUNDLE_URL="$BUNDLE_ID"
      scrubbed="${scrubbed#*:}"
      last="${scrubbed##*/}"
      second_last="${scrubbed%/*}"
      second_last="${second_last##*/}"
      BUNDLE_REPO="${second_last}/${last}"
      ;;
    */*/*|*:*)
      BUNDLE_TYPE='?'
      ;;
    */*)
      BUNDLE_TYPE=repo
      BUNDLE_URL="${ANTIDOTE_GIT_SITE:-https://github.com}/$BUNDLE_ID"
      BUNDLE_REPO="$BUNDLE_ID"
      ;;
    *)
      BUNDLE_TYPE=custom
      ;;
  esac

  if [ "$BUNDLE_TYPE" = repo ]; then
    BUNDLE_PATH="$ANTIDOTE_HOME/$BUNDLE_REPO"
  fi
}

debug_bundle_info() {
  bundle_info "$@"
  say "BUNDLE_ID=\"${BUNDLE_ID}\""
  say "BUNDLE_NAME=\"${BUNDLE_NAME}\""
  say "BUNDLE_TYPE=\"${BUNDLE_TYPE}\""
  say "BUNDLE_REPO=\"${BUNDLE_REPO}\""
  say "BUNDLE_URL=\"${BUNDLE_URL}\""
  say "BUNDLE_PATH=\"${BUNDLE_PATH}\""
}

gitcmd() {
  local result err
  result="$("${ANTIDOTE_GITCMD}" "$@" 2>&1)"
  err=$?
  if [ "$err" -ne 0 ]; then
    if [ -n "$result" ]; then
      warn "antidote: unexpected git error on command 'git $*'."
      warn "antidote: error details:"
      warn "$result"
      return $err
    fi
  fi
  say "$result"
}

antidote() {
  local cmd
  : "${ANTIDOTE_HOME:="$(antidote_home)"}"

  case "${1:-?}" in
    -h|--help)
      antidote_help "$@"
      return
      ;;
    -v|--version)
      antidote_version
      return
      ;;
    --debug)
      ANTIDOTE_DEBUG=true
      shift
      ;;
    \?)
      antidote_help "$@"
      exit
      ;;
  esac

  cmd="$1"
  if is_cmd "antidote_${cmd}"; then
    shift
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
      antidote_help "$cmd"
    else
      "antidote_${cmd}" "$@"
    fi
  elif [ "$ANTIDOTE_DEBUG" = true ]; then
    if [ "$1" = bundle_info ]; then
      shift
      debug_bundle_info "$@"
    fi
  else
    die "antidote: error: expected command but got \"$1\"."
  fi
}

# Set antidote variables.
ANTIDOTE_VERSION=2.0.0
ANTIDOTE_SCRIPT="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
ANTIDOTE_PROJDIR="${ANTIDOTE_SCRIPT%/*/*}"

# shellcheck disable=SC3028
: "${ANTIDOTE_OSTYPE:=${OSTYPE:-$(uname -s | tr '[:upper:]' '[:lower:]')}}"
: "${ANTIDOTE_GIT_SITE:=https://github.com}"
: "${ANTIDOTE_DEFER_REPO:=https://github.com/romkatv/zsh-defer}"
: "${ANTIDOTE_DEBUG:=false}"
: "${ANTIDOTE_COMPATIBILITY_MODE:=}"
: "${ANTIDOTE_GITCMD:=git}"

ANTIDOTE_HELP=$(
cat <<'EOS'
antidote - the cure to slow zsh plugin management

Usage: antidote [<flags>] <command> [<args> ...]

Flags:
  -h, --help           Show context-sensitive help
  -v, --version        Show application version

Commands:
  help      Show documentation
  load      Statically source all bundles from the plugins file
  bundle    Clone bundle(s) and generate the static load script
  install   Clone a new bundle and add it to your plugins file
  update    Update antidote and its cloned bundles
  purge     Remove a cloned bundle
  home      Print where antidote is cloning bundles
  list      List cloned bundles
  path      Print the path of a cloned bundle
  init      Initialize the shell for dynamic bundles
EOS
)

ANTIDOTE_BUNDLE_HELP=$(
cat <<'EOS'
Usage: antidote bundle [<bundles>...]

Clones a bundle and prints its source line.

Flags:
  -h, --help   Show context-sensitive help.

Args:
  [<bundles>]  Bundle list.
EOS
)

ANTIDOTE_HOME_HELP=$(
cat <<'EOS'
Usage: antidote home

Prints where antidote is cloning bundles.

Flags:
  -h, --help   Show context-sensitive help.
EOS
)

ANTIDOTE_INIT_HELP=$(
cat <<'EOS'
Usage: antidote init

Initializes the shell so antidote can load bundles dynmically.

Flags:
  -h, --help   Show context-sensitive help.
EOS
)

ANTIDOTE_LIST_HELP=$(
cat <<'EOS'
Usage: antidote list [-d|--details] [-bcprsu]

Lists all currently installed bundles

Flags:
  -h, --help     Show context-sensitive help.
  -d, --detail   Show full bundle details.

Format flags:
  -b             Bundle's branch.
  -c             Bundle's last commit date.
  -p             Bundle's path.
  -r             Bundle's short repo name.
  -s             Bundle's SHA.
  -u             Bundle's URL.
EOS
)

ANTIDOTE_PATH_HELP=$(
cat <<'EOS'
Usage: antidote path <bundle>

Prints the path of a currently cloned bundle.

Flags:
  -h, --help   Show context-sensitive help.

Args:
  <bundle>     The Bundle path to print.
EOS
)

ANTIDOTE_PURGE_HELP=$(
cat <<'EOS'
Usage: antidote purge <bundle>

Purges a bundle from your computer.

Flags:
  -h, --help   Show context-sensitive help.

Args:
  <bundle>     The bundle to be purged.
EOS
)

ANTIDOTE_UPDATE_HELP=$(
cat <<'EOS'
Usage: antidote update [-b|--bundles] [-s|--self]
       antidote update <bundle>

Updates cloned bundle(s) and antidote itself.

Flags:
  -h, --help     Show context-sensitive help.
  -s, --self     Update antidote.
  -b, --bundles  Update bundles.

Args:
  <bundle>     The bundle to be updated.
EOS
)

# Run antidote!
antidote "$@"

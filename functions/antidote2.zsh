#!/usr/bin/env zsh
# shellcheck disable=SC2120,SC2296

ANTIDOTE_VERSION=2.0.0-beta

if [[ -n "$BASH_VERSION" ]]; then
  shopt -s nullglob
elif [[ -n "$ZSH_VERSION" ]]; then
  setopt NULL_GLOB
fi

: "${OSTYPE:="$(uname -s | tr '[:upper:]' '[:lower:]')"}"
: "${ANTIDOTE_DEFAUT_GITSITE:=https://github.com}"
ANTIDOTE_DEBUG=false
NL=$'\n'
TAB=$'\t'
typeset -g REPLY=
typeset -ga reply=()

# Helper functions
_isfunc() { typeset -f "${1}" >/dev/null 2>&1 ;}
_iscmd()  { command -v "${1}" >/dev/null 2>&1 ;}

##? Check shell version requirements
_check_shell_version() {
  if [[ -n "$ZSH_VERSION" ]]; then
    builtin autoload -Uz is-at-least
    if ! is-at-least 5.4.2; then
      printf >&2 '%s\n' "Unsupported Zsh version '$ZSH_VERSION'. Expecting Zsh >=5.4.2."
      exit 1
    fi
  elif [[ -n "$BASH_VERSION" ]]; then
    if [[ "${BASH_VERSION%%.*}" -lt 4 ]]; then
      printf >&2 '%s\n' "Unsupported Bash version '$BASH_VERSION'. Expecting Bash >=4.0."
      exit 1
    fi
  else
    shellname=$(ps -p $$ -oargs= | awk 'NR=1{print $1}')
    printf >&2 '%s\n' "antidote: Expecting zsh or bash. Found '$shellname'."
    exit 1
  fi
}
_check_shell_version

##? Cross-shell method of getting the absolute path.
_abspath() {
  local filename parentdir
  filename="${1}"
  parentdir="$(dirname "${filename}")"

  [[ -e "${filename}" ]] || return 1
  if [[ -d "${filename}" ]]; then
    printf '%s\n' "$(cd "${filename}" && pwd)"
  elif [[ -d "${parentdir}" ]]; then
    printf '%s\n' "$(cd "${parentdir}" && pwd)/$(basename "${filename}")"
  fi
}

# Get script path in a Bash/Zsh compatible way, falling back to $0
# shellcheck disable=SC2296
SCRIPT_PATH="$(_abspath "${BASH_SOURCE[0]:-${(%):-%N}}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

_shellver() {
  if [[ -n "$ZSH_VERSION" ]]; then
    printf '%s\n' "zsh ${ZSH_VERSION}"
  elif [[ -n "$BASH_VERSION" ]]; then
    printf '%s\n' "bash ${BASH_VERSION}"
  else
    printf >&2 '%s\n' "antidote: unknown shell"
  fi
}


##? Print TMPDIR by OS.
_tempdir() {
  REPLY=
  local tmpd
  if [[ -n "$TMPDIR" && (( -d "$TMPDIR" && -w "$TMPDIR" ) || ! ( -d /tmp && -w /tmp )) ]]; then
    tmpd="${TMPDIR%/}"
  else
    tmpd="/tmp"
  fi
  REPLY="$tmpd"
  [[ "$ANTIDOTE_DEBUG" != true ]] || printf '%s\n' "$REPLY"
}

##? Collect <redirected or piped| input.
_collect_args() {
  local arg line
  reply=()
  for arg in "$@"; do
    arg="${arg//\\n/$NL}"
    while IFS= read -r line || [[ -n "$line" ]]; do
      reply+=("$line")
    done < <(printf '%s' "$arg")
  done
  if [[ ! -t 0 ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      reply+=("$line")
    done
  fi
  [[ "$ANTIDOTE_DEBUG" != true ]] || printf '%s\n' "${reply[@]}"
}

##? Get the default cache directory by OS.
_cachedir() {
  REPLY=
  local result
  if [[ "${OSTYPE}" == darwin* ]]; then
    result="$HOME/Library/Caches"
  elif [[ "${OSTYPE}" == cygwin* || "${OSTYPE}" == msys* ]]; then
    result="${LOCALAPPDATA:-$LocalAppData}"
    if _iscmd cygpath; then
      result="$(cygpath "$result")"
    fi
  fi
  [[ -n "$result" ]] || result="${XDG_CACHE_HOME:-$HOME/.cache}"

  if [[ -n "$1" ]]; then
    if [[ $result == *\\* ]] && [[ $result != */* ]]; then
      result+="\\$1"
    else
      result+="/$1"
    fi
  fi
  REPLY="$result"
  [[ "$ANTIDOTE_DEBUG" != true ]] || printf '%s\n' "$REPLY"
}

##? # Use shell's lexer for word splitting rules
_parse_kvpairs() {
  reply=()
  local str="$*"
  str="${str//\$/\\\$}"
  eval "set -- $str"
  reply=("$@")
}

##? Parse bundles into an associative array.
_parse_bundles() {
  reply=()
  _collect_args "$@" >/dev/null
  local -a bundles=( "${reply[@]}" )
  reply=()
  local -a kvpairs=() results=()
  local pair key value bundle lineno=0
  local -A parsed_bundle=()

  for bundle in "${bundles[@]}"; do
    (( lineno += 1 ))

    bundle="${bundle%%\#*}"                        # Remove anything after the first '#'
    bundle="${bundle#"${bundle%%[![:space:]]*}"}"  # Trim leading spaces
    bundle="${bundle%"${bundle##*[![:space:]]}"}"  # Trim trailing spaces

    # Skip empty bundles
    [[ -n "$bundle" ]] || continue

    # 1st field gets a 'name:' prefix so we can treat everything as key:val pairs
    bundle="name:${bundle}"

    # Split line into key-value pairs with quoting
    parsed_bundle=()
    parsed_bundle[lineno]="$lineno"

    _parse_kvpairs "${bundle}"
    kvpairs=("${reply[@]}")

    for pair in "${kvpairs[@]}"; do
      key="${pair%%:*}"  # Extract key (before first ':')
      if [[ "$pair" == *:* ]]; then
        value="${pair#*:}"  # Extract value (after first ':')
      else
        value=""
      fi
      parsed_bundle[$key]="$value"
    done

    results+=( "$(declare -p parsed_bundle)" )
  done
  reply=("${results[@]}")
  printf '%s\n' "${reply[@]}"
}

##? Get the details of all cloned repos
_repo_details() {
  reply=()
  local bundle_dir repo_details antidote_home
  local -A repo_detail=()
  antidote_home="$(antidote_home)"
  for bundle_dir in "${antidote_home}"/*/*/.git; do
    bundle_dir="$(git -C "$bundle_dir/.." rev-parse --show-toplevel)"
    repo_detail[path]="$bundle_dir"
    repo_detail[url]="$(git -C "$bundle_dir" config remote.origin.url)"
    repo_detail[repo]="$(basename "$(dirname "$bundle_dir")")/$(basename "$bundle_dir")"
    repo_detail[branch]="$(git -C "$bundle_dir" branch --show-current)"
    repo_detail[sha]="$(git -C "$bundle_dir" rev-parse HEAD)"
    repo_detail[date]="$(git -C "$bundle_dir" log -1 --format=%cd --date=short)"
    reply+=( "$(declare -p repo_detail)" )
  done
  printf '%s\n' "${reply[@]}"
}

##? Get the antidote version.
_antidote_version() {
  local ver gitsha
  ver="$ANTIDOTE_VERSION"
  gitsha="$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null)"
  [[ -z "$gitsha" ]] || ver="$ver ($gitsha)"
  printf '%s\n' "antidote version $ver"
}

##? Print help for antidote or one of its subcommands.
antidote_help() {
  local -a antidote_usage=(
    "antidote - the cure to slow zsh plugin management"
    ""
    "usage: antidote [<flags>] <command> [<args> ...]"
    ""
    "Flags:"
    "  -h, --help           Show context-sensitive help"
    "  -v, --version        Show application version"
    ""
    "Commands:"
    "  help [<command>]"
    "    Show documentation"
    ""
    "  bundle <bundles>..."
    "    Clone bundle(s) and generate the static load script"
    ""
    "  update"
    "    Update antidote and its cloned bundles"
    ""
    "  home"
    "    Print where antidote is cloning bundles"
    ""
    "  purge <bundle>"
    "    Remove a cloned bundle"
    ""
    "  list"
    "    List cloned bundles"
    ""
    "  path <bundle>"
    "    Print the path of a cloned bundle"
    ""
    "  init"
    "    Initialize the shell for dynamic bundles"
  )
  printf '%s\n' "${antidote_usage[@]}"
}

##? Print home directory for antidote.
antidote_home() {
  local result

  case "${1}" in
    -h|--help)
      antidote_help home
      return 0
      ;;
  esac

  if [[ -n "$ANTIDOTE_HOME" ]]; then
    result="$ANTIDOTE_HOME"
  else
    _cachedir antidote >/dev/null
    result="$REPLY"; REPLY=
  fi
  printf '%s\n' "$result"
}

##? Initialize the shell for dynamic bundles.
antidote_init() {
  printf '#!/usr/bin/env zsh\n'
  printf 'antidote2() {\n'
  printf '  case "$1" in\n'
  printf '    bundle)\n'
  printf '      source <( "%s" bundle "$@" ) || "%s" bundle "$@"\n' "$SCRIPT_PATH" "$SCRIPT_PATH"
  printf '      ;;\n'
  printf '    *)\n'
  printf '      "%s" "$@"\n' "$SCRIPT_PATH"
  printf '      ;;\n'
  printf '  esac\n'
  printf '}\n'
  printf '_antidote2() {\n'
  printf '  IFS='\'' '\'' read -A reply <<< "help bundle update home purge list init"\n'
  printf '}\n'
  printf 'compctl -K _antidote2 antidote2\n'
}

##? List cloned bundles.
antidote_list() {
  reply=()
  local -A repo_detail=()
  local -a repo_details=()
  local formatstr outstr deetstr

  case "${1}" in
    -f|--format)
      shift
      formatstr="$1"
      (( $# > 0 )) && shift
      ;;
    --)
      shift
      ;;
    -*)
      printf >&2 '%s\n' "unknown flag '${1}'"
      return 1
      ;;
  esac

  _repo_details >/dev/null
  repo_details=("${reply[@]}")
  for deetstr in "${repo_details[@]}"; do
    [[ -n "$deetstr" ]] || continue

    # Turn the typeset repr into an assoc_arr
    repo_detail=()
    eval "$deetstr"

    if [[ -n "$formatstr" ]]; then
      outstr="$formatstr"
      if [[ -n "$ZSH_VERSION" ]]; then
        outstr=${outstr:gs/%b/${repo_detail[branch]}}
        outstr=${outstr:gs/%d/${repo_detail[date]}}
        outstr=${outstr:gs/%p/${repo_detail[path]}}
        outstr=${outstr:gs/%r/${repo_detail[repo]}}
        outstr=${outstr:gs/%s/${repo_detail[sha]}}
        outstr=${outstr:gs/%u/${repo_detail[url]}}
      else
        outstr="${outstr//%b/${repo_detail[branch]}}"
        outstr="${outstr//%d/${repo_detail[date]}}"
        outstr="${outstr//%p/${repo_detail[path]}}"
        outstr="${outstr//%r/${repo_detail[repo]}}"
        outstr="${outstr//%s/${repo_detail[sha]}}"
        outstr="${outstr//%u/${repo_detail[url]}}"
      fi
      printf '%s\n' "$outstr"
    else
      printf '%s\n' "${repo_detail[repo]}"
      printf '%s\n' "=================================================="
      printf '%12s: %s\n' "Repo (%r)" "${repo_detail[repo]}"
      printf '%12s: %s\n' "Path (%p)" "${repo_detail[path]}"
      printf '%12s: %s\n' "URL (%u)" "${repo_detail[url]}"
      printf '%12s: %s\n' "Branch (%b)" "${repo_detail[branch]}"
      printf '%12s: %s\n' "SHA (%s)" "${repo_detail[sha]}"
      printf '%12s: %s\n' "Date (%d)" "${repo_detail[date]}"
      printf '\n'
    fi
  done
}

##? Main dispatch function.
antidote_main() {
  local cmd

  case "${1}" in
    ''|help|-h|--help)
      antidote_help "${2:-antidote}"
      return 0
      ;;
    -v|--version)
      _antidote_version
      return 0
      ;;
    -d|--debug)
      shift
      ANTIDOTE_DEBUG=true
      ;;
    --)
      shift
      ;;
    -*)
      printf >&2 '%s\n' "unknown flag '${1}', try --help"
      return 1
      ;;
  esac

  # Allow running any function if we're in debug mode
  if [[ "$ANTIDOTE_DEBUG" == true ]] && [[ "$1" == run ]]; then
    shift
    cmd="$1"
    shift
    "${cmd}" "$@"
    return $?
  fi

  if _isfunc "antidote_${1}"; then
    cmd="${1}"; shift
    "antidote_${cmd}" "$@"
    return $?
  else
    printf >&2 '%s\n' "command not found '${1}'"
    return 1
  fi
}

antidote_main "$@"

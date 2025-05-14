#!/usr/bin/env zsh
# shellcheck disable=SC2120,SC2296

ANTIDOTE_VERSION=2.0.0

# This script supports both Bash and Zsh
if [[ -n "$BASH_VERSION" ]]; then
  shopt -s nullglob
  shopt -s globstar
  if [[ "${BASH_VERSION%%.*}" -lt 4 ]]; then
    printf >&2 '%s\n' "antidote: Unsupported Bash version '$BASH_VERSION'. Expecting Bash >=4.0."
    exit 1
  fi
elif [[ -n "$ZSH_VERSION" ]]; then
  setopt NULL_GLOB EXTENDED_GLOB NO_MONITOR PIPEFAIL
  builtin autoload -Uz is-at-least
  if ! is-at-least 5.4.2; then
    printf >&2 '%s\n' "antidote: Unsupported Zsh version '$ZSH_VERSION'. Expecting Zsh >=5.4.2."
    exit 1
  fi
else
  shellname=$(ps -p $$ -oargs= | awk 'NR=1{print $1}')
  printf >&2 '%s\n' "antidote: Expecting zsh or bash. Found '$shellname'."
  exit 1
fi

# Set variables
: "${ANTIDOTE_DEFAUT_GITSITE:=https://github.com}"
: "${ANTIDOTE_OSTYPE:=${OSTYPE:-$(uname -s | tr '[:upper:]' '[:lower:]')}}"
: "${ANTIDOTE_DEBUG:=false}"
: "${ANTIDOTE_GITCMD:=git}"

NL=$'\n'
#TAB=$'\t'
#typeset -g REPLY=
#typeset -ga reply=()

# Helper functions
_isfunc() { typeset -f "${1}" >/dev/null 2>&1 ;}
_iscmd()  { command -v "${1}" >/dev/null 2>&1 ;}

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

##? Display the version of the shell running antidote.
_shellver() {
  if [[ -n "$ZSH_VERSION" ]]; then
    printf '%s\n' "zsh ${ZSH_VERSION}"
  elif [[ -n "$BASH_VERSION" ]]; then
    printf '%s\n' "bash ${BASH_VERSION}"
  else
    printf >&2 '%s\n' "antidote: Unknown shell"
  fi
}

##? Print TMPDIR by OS.
_tempdir() {
  local result tmpd
  if [[ -n "$TMPDIR" && (( -d "$TMPDIR" && -w "$TMPDIR" ) || ! ( -d /tmp && -w /tmp )) ]]; then
    tmpd="${TMPDIR%/}"
  else
    tmpd="/tmp"
  fi
  result="$tmpd"
  typeset -g REPLY="$result"
  [[ "$ANTIDOTE_DEBUG" != true ]] || printf '%s\n' "$result"
}

##? Collect <redirected or piped| input.
_collect_args() {
  local arg line
  local -a results=()

  for arg in "$@"; do
    arg="${arg//\\n/$NL}"
    while IFS= read -r line || [[ -n "$line" ]]; do
      results+=("$line")
    done < <(printf '%s' "$arg")
  done
  if [[ ! -t 0 ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      results+=("$line")
    done
  fi
  typeset -ga reply=("${results[@]}")
  [[ "$ANTIDOTE_DEBUG" != true ]] || printf '%s\n' "${results[@]}"
}

##? Get the default cache directory by OS.
_cachedir() {
  local result
  if [[ "${ANTIDOTE_OSTYPE}" == darwin* ]]; then
    result="$HOME/Library/Caches"
  elif [[ "${ANTIDOTE_OSTYPE}" == cygwin* || "${ANTIDOTE_OSTYPE}" == msys* ]]; then
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
  typeset -g REPLY="$result"
  [[ "$ANTIDOTE_DEBUG" != true ]] || printf '%s\n' "$result"
}

##? # Use shell's lexer for word splitting rules
_parse_kvpairs() {
  local str="$*"
  str="${str//\$/\\\$}"
  eval "set -- $str"
  typeset -ga reply=("$@")
}

##? Parse bundles into an associative array.
_parse_bundles() {
  _collect_args "$@" >/dev/null
  local -a bundles=( "${reply[@]}" )
  unset reply
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
  typeset -ga reply=("${results[@]}")
  printf '%s\n' "${results[@]}"
}

##? Convert git URLs to user/repo format
_url2repo() {
  local repo url
  url="${1%.git}"    # strip trailing .git
  repo="${url##*:}"  # strip from left up to last ':'
  repo="$(basename "$(dirname "$repo")")/$(basename "$repo")"
  if [[ "$repo" != */* ]] || [[ "$repo" == */*/* ]]; then
    printf >&2 'antidote: Unable to convert URL to short repo '%s'.\n' "$1"
    return 1
  fi
  printf '%s\n' "$repo"
}

##? Get the details of all cloned repos
_repo_details() {
  local bundle_dir repo_details antidote_home url repo
  local -a results=()
  local -A repo_detail=()
  antidote_home="$(antidote_home)"
  for bundle_dir in "${antidote_home}"/**/.git; do
    declare -A repo_detail=()
    bundle_dir="$("${ANTIDOTE_GITCMD}" -C "$bundle_dir/.." rev-parse --show-toplevel 2>/dev/null)"
    url="$("${ANTIDOTE_GITCMD}" -C "$bundle_dir" config remote.origin.url 2>/dev/null)"
    repo="$(_url2repo "$url" 2>/dev/null)"

    repo_detail[path]="$bundle_dir"
    repo_detail[url]="$url"
    repo_detail[repo]="$repo"
    repo_detail[branch]="$("${ANTIDOTE_GITCMD}" -C "$bundle_dir" branch --show-current 2>/dev/null)"
    repo_detail[sha]="$("${ANTIDOTE_GITCMD}" -C "$bundle_dir" rev-parse HEAD 2>/dev/null)"
    repo_detail[date]="$("${ANTIDOTE_GITCMD}" -C "$bundle_dir" log -1 --format=%cd --date=short 2>/dev/null)"
    results+=( "$(declare -p repo_detail)" )
  done
  typeset -ga reply=("${results[@]}")
  [[ "$ANTIDOTE_DEBUG" != true ]] || printf '%s\n' "${results[@]}"
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
    result="$REPLY"
    unset REPLY
  fi
  printf '%s\n' "$result"
}

# shellcheck disable=SC2016
##? Initialize the shell for dynamic bundles.
antidote_init() {
  printf '%s\n' '#!/usr/bin/env zsh'
  printf '%s\n' 'antidote2() {'
  printf        '  case "%s" in\n' '$1'
  printf '%s\n' '    bundle)'
  printf        '      source <( "%s" bundle "%s" ) || "%s" bundle "%s"\n' "$SCRIPT_PATH" '$@' "$SCRIPT_PATH" '$@'
  printf '%s\n' '      ;;'
  printf '%s\n' '    *)'
  printf        '      "%s" "$@"\n' "$SCRIPT_PATH"
  printf '%s\n' '      ;;'
  printf '%s\n' '  esac'
  printf '%s\n' '}'
  printf '%s\n' '_antidote2() {'
  printf '%s\n' '  IFS='\'' '\'' read -A reply <<< "help bundle update home purge list init"'
  printf '%s\n' '}'
  printf '%s\n' 'compctl -K _antidote2 antidote2'
}

##? List cloned bundles.
antidote_list() {
  local -A repo_detail=()
  local -a repo_details=() formatargs=() output=()
  local arg formatstr deetstr

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
      printf >&2 '%s\n' "antidote: unknown flag '${1}'"
      return 1
      ;;
  esac

  _repo_details >/dev/null
  repo_details=("${reply[@]}")
  unset reply

  for deetstr in "${repo_details[@]}"; do
    [[ -n "$deetstr" ]] || continue

    # Turn the typeset repr into an assoc_arr
    repo_detail=()
    eval "$deetstr"

    formatargs=()
    for arg in "$@"; do
      case "$arg" in
        '%b')  formatargs+=("${repo_detail[branch]}") ;;
        '%d')  formatargs+=("${repo_detail[date]}")   ;;
        '%p')  formatargs+=("${repo_detail[path]}")   ;;
        '%r')  formatargs+=("${repo_detail[repo]}")   ;;
        '%s')  formatargs+=("${repo_detail[sha]}")    ;;
        '%u')  formatargs+=("${repo_detail[url]}")    ;;
        *)     formatargs+=("$arg")                   ;;
      esac
    done

    if [[ -n "$formatstr" ]]; then
      # shellcheck disable=SC2059
      output+=( "$(printf "${formatstr}" "${formatargs[@]}")" )
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
  (( ${#output} == 0 )) || printf '%s\n' "${output[@]}" | sort
}

##? Get the path to a bundle
_bundletype() {
  local result
  local bundle="$1"

  # Try to expand '~' prefix
  # shellcheck disable=SC2088
  if [[ $bundle == '~/'* ]]; then
    bundle="${HOME}/${bundle#\~/*}"
  fi

  # Determine the bundle type.
  if [[ -e "$bundle" ]]; then
    [[ -f $bundle ]] && result="file" || result="dir"
  elif [[ -z "$bundle" ]] || [[ "$bundle" =~ ^[[:space:]]*$ ]]; then
    result=empty
  else
    case "$bundle" in
      /*)       result="path"     ;;
      '$'*)     result="path"     ;;
      *://*)    result="url"      ;;
      *@*:*/*)  result="sshurl"   ;;
      *:*)      result="?"        ;;
      *@*)      result="?"        ;;
      */*/*)    result="relpath"  ;;
      */)       result="relpath"  ;;
      */*)      result="repo"     ;;
      *)        result="word"     ;;
    esac
  fi

  typeset -g REPLY="$result"
  printf '%s\n' "$result"
}

##? Print the path of a cloned bundle.
# antidote_path() {
#   local bundle
#   if (( $# == 0 )); then
#     printf >&2 '%s\n' "antidote path: required argument 'bundle' not provided."
#     return 1
#   fi
#   for bundle in "$@"; do

#   done
# }

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
      [[ -n "$ZSH_VERSION" ]] && setopt WARN_CREATE_GLOBAL WARN_NESTED_VAR
      ;;
    --)
      shift
      ;;
    -*)
      printf >&2 '%s\n' "antidote: unknown flag '${1}', try --help"
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
    printf >&2 '%s\n' "antidote: command not found '${1}'"
    return 1
  fi
}

antidote_main "$@"

#!/usr/bin/env zsh
# shellcheck disable=SC2120,SC2296,SC2034

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
: "${ANTIDOTE_GIT_SITE:=https://github.com}"
: "${ANTIDOTE_OSTYPE:=${OSTYPE:-$(uname -s | tr '[:upper:]' '[:lower:]')}}"
: "${ANTIDOTE_DEBUG:=false}"
: "${ANTIDOTE_COMPATIBILITY_MODE:=}"

NL=$'\n'
TAB=$'\t'
if [[ $TERM = *256color* || $TERM = *rxvt* ]]; then
  FG_GREEN=$'\033[32m'
  FG_BLUE=$'\033[34m'
  FG_YELLOW=$'\033[33m'
  NORMAL=$'\033[0m'
fi

# Global shared
# typeset -g REPLY=
# typeset -ga reply=()
# typeset -gA repo_properties

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

##? Get the name of the bundle directory
_bundledir() {
  local bundle_type result repo_user repo_name
  local bundle="$1" gitsite="${ANTIDOTE_GIT_SITE:-https://github.com}" ret=0
  gitsite="${gitsite%/}"
  bundle_type="$(_bundletype "$bundle")"

  case "$bundle_type" in
    repo|url|sshurl) : ;;
    *) return 1 ;;
  esac

  if [[ "$ANTIDOTE_COMPATIBILITY_MODE" == antibody ]]; then
    # antibody reqs a URL to determine the dir, so we can't use the simple repo form
    [[ "$bundle_type" == repo ]] && bundle="${gitsite}/${bundle}"
    result="$(
      printf '%s\n' "$bundle" |
      sed -e "s|@|-AT-|g"    \
          -e "s|:|-COLON-|g" \
          -e "s|/|-SLASH-|g"
    )" || return 1
  else
    if [[ "$bundle_type" == repo ]]; then
      result="${bundle}"
    else
      # Reminder: '#' strips from the left, '%' from the right
      bundle="${bundle%.git}"   # strip trailing .git
      repo_name="${bundle##*/}" # keep the repo name
      bundle="${bundle%/*}"     # strip the repo name

      if [[ "$bundle_type" == sshurl ]]; then
        repo_user="${bundle##*:}"
      else
        repo_user="${bundle##*/}"
      fi
      [[ -n "$repo_user" ]] && [[ -n "$repo_name" ]] || return 1
      result="${repo_user}/${repo_name}"
    fi
  fi
  printf '%s\n' "$result"
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
  printf '%s\n' "$result"
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

##? git wrapper
_git() {
  local result ret
  result="$("${ANTIDOTE_GIT:-git}" "$@" 2>&1)"
  ret=$?
  if (( ret > 0 )); then
    if [[ -n "$result" ]]; then
      printf >&2 "antidote: unexpected git error on command 'git %s'.\n" "$*"
      printf >&2 "antidote: error details:\n"
      printf >&2 "%s\n" "$result"
      return $ret
    fi
  fi
  printf '%s\n' "$result"
}

##? Make a temp file or directory.
_mktemp() {
  local -a o_dir=() o_suffix=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d)  o_dir+=("$1");     shift ;;
      -s)  o_suffix+=("$1");  shift ;;
      --)  shift;             break ;;
      -*)  o_badopt+=("$1");  break ;;
      *)   break ;;
    esac
  done
  if (( $#o_badopt > 0 )); then
    printf >&2 "antidote: bad option: '%s'.\n" "${o_badopt[-1]}"
    return 1
  fi

  local tmpbase pattern

  # Set the appropriate temp directory
  tmpbase="$(_tempdir)"

  # Create the pattern with PID
  pattern="antidote.$$"

  # Add suffix if provided with -s
  if (( $#o_suffix )) && [[ -n "${o_suffix[-1]}" ]]; then
    pattern="${pattern}.${o_suffix[-1]}"
  fi

  # Add random chars
  pattern="${pattern}.XXXXXXXXXX"

  # Create temp directory or file
  if (( $#o_dir )); then
    mktemp -d "${tmpbase}/${pattern}"
  else
    mktemp "${tmpbase}/${pattern}"
  fi
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

    _wordsplit "${bundle}" >/dev/null
    kvpairs=("${reply[@]}")
    unset reply

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

##? # Use shell's lexer for word splitting rules
_wordsplit() {
  local str="$*"
  str="${str//\$/\\\$}"
  eval "set -- $str"
  typeset -ga reply=("$@")
  printf '%s\n' "${reply[@]}"
}

##? Get the details of all cloned repos
_repo_details() {
  local bundle_dir bundle_root repo_details antidote_home url repo branch sha date errcount
  local -a results=()
  local -A repo_properties=()
  antidote_home="$(antidote_home)"
  for bundle_dir in "${antidote_home}"/**/.git; do
    repo_properties=()

    bundle_root="$(_git -C "$bundle_dir/.." rev-parse --show-toplevel)" || return 1
    url="$(_git -C "$bundle_root" config remote.origin.url)" || return 1
    branch="$(_git -C "$bundle_root" rev-parse --abbrev-ref HEAD)" || return 1
    sha="$(_git -C "$bundle_root" rev-parse HEAD)" || return 1
    date="$(_git -C "$bundle_root" log -1 --format=%cd --date=short)" || return 1
    repo="$(_url2repo "$url" 2>/dev/null)"

    repo_properties[path]="$bundle_root"
    repo_properties[url]="$url"
    repo_properties[branch]="$branch"
    repo_properties[sha]="$sha"
    repo_properties[date]="$date"
    repo_properties[repo]="$repo"
    results+=( "$(declare -p repo_properties)" )
  done
  typeset -ga reply=("${results[@]}")
  [[ "$ANTIDOTE_DEBUG" != true ]] || printf '%s\n' "${results[@]}"
}

##? Repeat a string (s) n times, optionally joined with j
_repeat() {
  local i n="$1" s="$2" j="$3"
  for (( i = 0; i < n; i++ )); do
    (( i > 0 )) && printf '%s' "$j"
    printf '%s' "$s"
  done
  printf '\n'
}

##? Safe rm wrapper
_rm() {
  # Call me paranoid, but I want to be really certain antidote will never rm something
  # it shouldn't. This function wraps rm to double check that any paths being removed
  # are valid. If it's not in your $HOME or $TMPDIR, we need to block it.
  local p tmpdir
  local -a rmflags

  while (( $# )); do
    case "$1" in
      --)  shift; break     ;;
      -*)  rmflags+=("$1")  ;;
      *)   break            ;;
    esac
    shift
  done
  (( $# > 0 )) || return 1

  tmpdir="$(_tempdir)"
  for p in "$@"; do
    p="$(_abspath "$p")"
    if [[ "$p" != "$HOME"/* ]] && [[ "$p" != "$tmpdir"/* ]]; then
      printf >&2 "antidote: Blocked attempt to rm path: '%s'." "$p"
      return 1
    fi
  done

  rm "${rmflags[@]}" -- "$@"
}

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

  # Set the appropriate temp directory (cargo cult code from p10k)
  if [[ -n "$TMPDIR" && (( -d "$TMPDIR" && -w "$TMPDIR" ) || ! ( -d /tmp && -w /tmp )) ]]; then
    tmpd="${TMPDIR%/}"
  else
    tmpd="/tmp"
  fi
  result="$tmpd"
  printf '%s\n' "$result"
}

##? Convert git URLs to user/repo format
_url2repo() {
  local str

  str="${1%/}"       # strip trailing /
  str="${str%.git}"  # strip trailing .git

  # strip the domain
  if [[ "$str" == *://*/*/* ]]; then
    str="${str#*://*/}"
  elif [[ "$str" == git@*:*/* ]]; then
    str="${str#git@*:}"
  else
    return 1
  fi

  # make sure whatever is left is repo_user/repo_name
  [[ "$str" == */* ]] && [[ "$str" != */*/* ]] || return 1
  printf '%s\n' "$str"
}

##? Get the antidote version.
_antidote_version() {
  local ver gitsha
  ver="$ANTIDOTE_VERSION"
  gitsha="$(git -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null)"
  [[ -z "$gitsha" ]] || ver="$ver ($gitsha)"
  printf '%s\n' "antidote version $ver"
}

# Cleanup function to ensure we don't leave temp files behind.
_antidote_update_cleanup() {
  [[ -d "$__antidote_update_tmpdir" ]] && _rm -rf -- "$__antidote_update_tmpdir"
  unset __antidote_update_tmpdir
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
    result="$(_cachedir antidote)"
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
  local -A repo_properties=()
  local -a repo_details=() formatargs=() output=()
  local arg formatstr deetstr

  local -a o_format=() fmtcodes=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--path)    fmtcodes+=("%p");  shift ;;
      -r|--repo)    fmtcodes+=("%r");  shift ;;
      -u|--url)     fmtcodes+=("%u");  shift ;;
      -b|--branch)  fmtcodes+=("%b");  shift ;;
      -d|--date)    fmtcodes+=("%d");  shift ;;
      -s|--sha)     fmtcodes+=("%s");  shift ;;
      -f|--format)
        o_format+=("$1")
        shift
        (( $# > 0 )) && o_format+=("$1") && shift
        ;;
      --)  shift;             break ;;
      -*)  o_badopt+=("$1");  break ;;
      *)                      break ;;
    esac
  done
  if (( $#o_badopt > 0 )); then
    printf >&2 "antidote list: bad option: '%s'.\n" "${o_badopt[-1]}"
    return 1
  elif (( $#o_format > 0 )) && (( $#fmtcodes > 0 )); then
    printf >&2 "antidote list: -f/--format flag is mutually exclusive with other flags.\n"
    return 1
  fi
  if (( ${#o_format} > 0 )); then
    formatstr="${o_format[-1]}"
    fmtcodes=("$@")
  elif (( ${#fmtcodes} > 0 )); then
    formatstr="$( _repeat "${#fmtcodes}" "%s" "$TAB" )"
  fi

  _repo_details >/dev/null
  repo_details=("${reply[@]}")
  unset reply

  for deetstr in "${repo_details[@]}"; do
    [[ -n "$deetstr" ]] || continue

    # Turn the typeset repr into an assoc_arr
    repo_properties=()
    eval "$deetstr"

    formatargs=()
    for arg in "${fmtcodes[@]}"; do
      case "$arg" in
        '%b')  formatargs+=("${repo_properties[branch]}") ;;
        '%d')  formatargs+=("${repo_properties[date]}")   ;;
        '%p')  formatargs+=("${repo_properties[path]}")   ;;
        '%r')  formatargs+=("${repo_properties[repo]}")   ;;
        '%s')  formatargs+=("${repo_properties[sha]}")    ;;
        '%u')  formatargs+=("${repo_properties[url]}")    ;;
        *)     formatargs+=("$arg")                   ;;
      esac
    done

    if [[ -n "$formatstr" ]]; then
      # shellcheck disable=SC2059
      output+=( "$(printf "${formatstr}" "${formatargs[@]}")" )
    else
      printf '%s\n' "${repo_properties[repo]}"
      printf '%s\n' "=================================================="
      printf '%12s: %s\n' "Repo (%r)" "${repo_properties[repo]}"
      printf '%12s: %s\n' "Path (%p)" "${repo_properties[path]}"
      printf '%12s: %s\n' "URL (%u)" "${repo_properties[url]}"
      printf '%12s: %s\n' "Branch (%b)" "${repo_properties[branch]}"
      printf '%12s: %s\n' "SHA (%s)" "${repo_properties[sha]}"
      printf '%12s: %s\n' "Date (%d)" "${repo_properties[date]}"
      printf '\n'
    fi
  done
  (( ${#output} == 0 )) || printf '%s\n' "${output[@]}" | sort
}

##? Print the path of a cloned bundle.
antidote_path() {
  local bundle_dir bundle_path ret=0

  if (( $# == 0 )); then
    printf >&2 '%s\n' "antidote path: required argument 'bundle' not provided."
    return 1
  fi

  # Figure out the bundle directory.
  bundle_dir="$(_bundledir "$1")" || ret=1
  [[ "$ret" -eq 0 ]] && bundle_path="$(antidote_home)/${bundle_dir}"

  # If we haven't errored and we have a valid directory, print it.
  if [[ "$ret" -eq 0 ]] && [[ -n "${bundle_dir}" ]] && [[ -d "${bundle_path}/.git" ]]; then
    printf '%s\n' "$bundle_path"
  else
    printf >&2 "antidote path: error: '%s' does not exist in cloned paths\n" "$1"
    return 1
  fi
}

##? Update cloned bundles.
antidote_update() {
  local -a o_self=() o_bundles=() o_badopt=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -s|--self)    o_self+=("$1");    shift ;;
      -b|--bundles) o_bundles+=("$1"); shift ;;
      --)           shift;             break ;;
      -*)           o_badopt+=("$1");  break ;;
      *)                               break ;;
    esac
  done
  if (( $#o_badopt > 0 )); then
    printf >&2 "antidote: bad option: '%s'.\n" "${o_badopt[-1]}"
    return 1
  fi

  local loadable_check_path tmpfile
  if (( $#o_bundles )) || ! (( $#o_self )); then
    print "Updating bundles..."
    local bundledir url repo

    # Remove zcompiled files
    _rm -rf "$(antidote_home)"/**/*.zwc

    # remove check file
    loadable_check_path="$(antidote_home)/.antidote.load"
    [[ -r "$loadable_check_path" ]] && _rm -- "$loadable_check_path"

    # Setup temporary directory and tracking
    local tmpfile tmpdir
    tmpdir="$(_mktemp -d -s update)"

    # Set trap to ensure tempdir cleanup on exit, interrupt, etc.
    # (EXIT is special, 2=INT, 15=TERM, 1=HUP)
    typeset -g __antidote_update_tmpdir="$tmpdir"
    trap __antidote_update_cleanup EXIT 2 15 1

    # We can save the date on update!
    # git config --local antidote.lastUpdated "$(date "+%Y-%m-%d %H:%M:%S %z")"
    # git config --get antidote.lastUpdated

    # Update bundles
    for bundledir in $(antidote_list --path); do
      url="$(git -C "$bundledir" config remote.origin.url)"
      printf "antidote: checking for updates: '%s'" "$url"
      repo="$(_url2repo "$url")"
    done
  fi
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


##? Convert a repo format (user/repo) to URL
# _repo2url() {
#   [[ "$(_bundletype "$1")" == repo ]] || return 1
#   local gitsite="${ANTIDOTE_GIT_SITE:-https://github.com}"
#   gitsite="${gitsite%/}"
#   printf '%s/%s\n' "$gitsite" "$1"
# }

##? Convert a git URL to a bundle path
# _url2path() {
#   local url result
#   url="$1"
#   _isurl "$url" || return 1

#   if [[ "$ANTIDOTE_COMPATIBILITY_MODE" == antibody ]]; then
#     result="$(
#       printf '%s\n' "$url" |
#       sed -e "s|@|-AT-|g"    \
#           -e "s|:|-COLON-|g" \
#           -e "s|/|-SLASH-|g"
#     )" || return 1
#   else
#     result="$(_url2repo "$url")" || return 1
#   fi
#   printf '%s/%s\n' "$(antidote_home)" "$result"
# }

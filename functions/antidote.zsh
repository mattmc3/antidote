#!/usr/bin/env zsh

# Helpers
die()    { warn "$@"; exit "${ERR:-1}"; }
say()    { printf '%s\n' "$@"; }
warn()   { say "$@" >&2; }
#emit()   { printf "${INDENT}%s\n" "$@"; }
#noop()   { :; }
#is_cmd() { command -v "$1" >/dev/null 2>&1; }
#is_cmd local || alias local=noop
# Check whether a string represents "true" (1, y, yes, t, true, o, on).
is_true() {
  [[ -n "$1" && "$1:l" == (1|y(es|)|t(rue|)|o(n|)) ]]
}
builtin autoload -Uz is-at-least

# git helpers.
git_() {
  local result err
  result="$("${ANTIDOTE_GIT_CMD:-git}" "$@" 2>&1)"
  err=$?
  if [ "$err" -ne 0 ]; then
    if [ -n "$result" ]; then
      warn "antidote: unexpected git error on command 'git $*'."
      if [ -n "$result" ]; then
        warn "antidote: error details:"
        warn "$result"
      fi
      return $err
    fi
  fi
  say "$result"
}
git_basedir()  { git_ -C "$1" rev-parse --show-toplevel; }
git_url()      { git_ -C "$1" config remote.origin.url; }
git_branch()   { git_ -C "$1" rev-parse --abbrev-ref HEAD; }
git_sha()      { git_ -C "$1" rev-parse HEAD; }
git_shortsha() { git_ -C "$1" rev-parse --short HEAD; }
git_repodate() { git_ -C "$1" log -1 --format=%cI; } # or --format=%cd --date=short;

if [[ $ANTIDOTE_TESTING == true ]]; then
  git_shortsha() { say "abcd123" }
fi

parse() {
  local line lineno arg argno
  local -a args

  lineno=1
  while IFS= read -r line; do
    # (z): use shell wordsplitting rules
    # (Q): remove one level of quotes
    args=(${(Q)${(z)line}})
    argno=1
    for arg in $args; do
      [[ $arg == \#* ]] && break
      if (( argno == 1 )); then
        printf '__lineno__:%s%s__bundle__:%s' "$lineno" "$TAB" "$arg"
      else
        printf '%s%s' "$TAB" "$arg"
      fi
      (( argno++ ))
    done
    [[ $argno -gt 1 ]] && printf '\n'
    (( lineno++ ))
  done
}

version() {
  local ver="$ANTIDOTE_VERSION"
  local gitsha=$(git_shortsha ${ANTIDOTE_ZSH:h:h})
  [[ -z "$gitsha" ]] || ver="$ver ($gitsha)"
  say "antidote version $ver"
}

usage() {
  say "$ANTIDOTE_HELP"
}

supports_color() {
  [[
    "$COLORTERM" == truecolor ||
    "$COLORTERM" == 24bit ||
    "$TERM" == *256color* ||
    "$TERM" == *rxvt*
  ]]
}

tourl() {
  local bundle=$1
  local url=$bundle
  if [[ $bundle != *://* && $bundle != git@*:*/* ]]; then
    url=${ANTIDOTE_GIT_SITE}/$bundle
  fi
  say $url
}

bundle_type() {
  local bundle=$1

  # Try to expand path bundles with '$' and '~' prefixes so that we get a more
  # granular result than 'path'.
  if [[ $bundle == '~/'* ]]; then
    bundle=${~bundle}
  elif [[ $bundle == '$'* ]]; then
    bundle=${(e)bundle}
  fi

  # Determine the bundle type.
  local result
  if [[ -e "$bundle" ]]; then
    [[ -f $bundle ]] && result=file || result=dir
  elif [[ -z "${bundle// }" ]]; then
    result=empty
  else
    case "$bundle" in
      (/|~|'$')*)  result=path     ;;
      *://*)       result=url      ;;
      *@*:*/*)     result=sshurl   ;;
      *(:|@)*)     result='?'      ;;
      */*/*)       result=relpath  ;;
      */)          result=relpath  ;;
      */*)         result=repo     ;;
      *)           result=word     ;;
    esac
  fi
  say $result
}

bundle_name() {
  #local MATCH MBEGIN MEND; local -a match mbegin mend  # appease 'warn_create_global'
  local bundle=$1
  local bundle_type="$(bundle_type $bundle)"
  if [[ "$bundle_type" == (url|sshurl) ]] ; then
    bundle=${bundle%.git}
    bundle=${bundle:gs/\:/\/}
    local parts=(${(ps./.)bundle})
    say ${parts[-2]}/${parts[-1]}
  else
    # Replace ~ and $HOME with \$HOME
    bundle=${bundle/#\~\//\$HOME/}
    bundle=${bundle/#$HOME/\$HOME}
    say "$bundle"
  fi
}

initfiles() {
  local dir
  local -a initfiles=()
  dir=${1:A}
  initfiles=($dir/${dir:A:t}.plugin.zsh(N))
  [[ $#initfiles -gt 0 ]] || initfiles=($dir/*.plugin.zsh(N))
  [[ $#initfiles -gt 0 ]] || initfiles=($dir/*.zsh(N))
  [[ $#initfiles -gt 0 ]] || initfiles=($dir/*.sh(N))
  [[ $#initfiles -gt 0 ]] || initfiles=($dir/*.zsh-theme(N))
  say ${(u)initfiles[@]}
  (( $#initfiles )) || return 1
}

get_cachedir() {
  local result
  if [[ "${ANTIDOTE_OSTYPE}" == darwin* ]]; then
    result=$HOME/Library/Caches
  elif [[ "${ANTIDOTE_OSTYPE}" == (cygwin|msys)* ]]; then
    result=${LOCALAPPDATA:-$LocalAppData}
    if type cygpath > /dev/null; then
      result=$(cygpath "$result")
    fi
  elif [[ -n "$XDG_CACHE_HOME" ]]; then
    result=$XDG_CACHE_HOME
  else
    result=$HOME/.cache
  fi

  if [[ -n "$1" ]]; then
    if [[ $result == *\\* ]] && [[ $result != */* ]]; then
      result+="\\$1"
    else
      result+="/$1"
    fi
  fi
  say $result
}

# Print the OS specific temp dir.
temp_dir() {
  local tmpd=/tmp
  # Use TMPDIR if it has a value and is better than /tmp
  if [ -n "$ANTIDOTE_TMPDIR" ]; then
    if [ -d "$ANTIDOTE_TMPDIR" ] && [ -w "$ANTIDOTE_TMPDIR" ]; then
      # TMPDIR exists and is writable?
      tmpd="${ANTIDOTE_TMPDIR%/}"
    elif [ ! -d /tmp ] || [ ! -w /tmp ]; then
      # Else use TMPDIR only if /tmp is unusable
      tmpd="${ANTIDOTE_TMPDIR%/}"
    fi
  fi
  say "$tmpd"
}

del() {
  local -a rmflags rmpaths
  local p tmpdir

  while (( $# )); do
    case "$1" in
      --)  shift; break   ;;
      -*)  rmflags+=($1)  ;;
      *)   break          ;;
    esac
    shift
  done

  (( $# > 0 )) || return 1

  tmpdir=$(temp_dir)
  for p in $@; do
    p="${p:a}"
    if [[ "$p" != ${HOME}/* ]] && [[ "$p" != ${tmpdir}/* ]]; then
      die "antidote: Blocked attempt to rm path: '$p'."
    fi
  done

  rm ${rmflags[@]} -- "$@"
}

### Create a cross-platform temporary directory/file for antidote.
# usage: maketmp [-d] [-f suffix]
#   -d   Create a directory rather than a file
#   -s   Use this for the temp file/dir
# Returns the path of created temp directory/file.
maketmp() {
  local -a o_dir o_suffix
  zparseopts ${ZPARSEOPTS} -- d=o_dir s:=o_suffix

  # Set the appropriate temp directory (cargo cult code from p10k)
  local tmpbase=$(temp_dir)

  # Create the pattern with PID
  local pattern="antidote.$$"

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

collect_input() {
  local -a input=()
  if (( $# > 0 )); then
    input=("${(s.\n.)${@}}")
  elif [[ ! -t 0 ]]; then
    local data
    while IFS= read -r data || [[ -n "$data" ]]; do
      input+=("$data")
    done
  fi
  printf '%s\n' "${input[@]}"
}

bundle_dir() {
  # If the bundle is a repo/URL, then by default we use the legacy antibody format:
  # `$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions`
  # With `zstyle ':antidote:bundle' use-friendly-names on`, we can simplify to
  # `$ANTIDOTE_HOME/zsh-users/zsh-autosuggestions`
  # If the bundle is a file, use its parent directory.
  # Otherwise, just assume the bundle is a directory.
  local MATCH MBEGIN MEND; local -a match mbegin mend  # appease 'warn_create_global'

  local bundle=$1
  local bundle_type="$(bundle_type $bundle)"

  # handle repo bundle paths
  if [[ "$bundle_type" == (repo|url|sshurl) ]] && [[ ! -e "$bundle" ]]; then
    if is_true $ANTIDOTE_COMPATIBILITY_MODE; then
      # sanitize URL for safe use as a dir name
      # ex: $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions
      local url=$(tourl $bundle)
      url=${url%.git}
      url=${url:gs/\@/-AT-}
      url=${url:gs/\:/-COLON-}
      url=${url:gs/\//-SLASH-}
      say $ANTIDOTE_HOME/$url
    else
      # user/repo format
      # ex: $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions
      bundle=${bundle%.git}
      bundle=${bundle:gs/\:/\/}
      local parts=( ${(ps./.)bundle} )
      if [[ $#parts -gt 1 ]]; then
        say $ANTIDOTE_HOME/${parts[-2]}/${parts[-1]}
      else
        say $ANTIDOTE_HOME/$bundle
      fi
    fi
  elif [[ -f "$bundle" ]]; then
    say ${bundle:A:h}
  else
    say ${bundle}
  fi
}

### Print where antidote is cloning bundles.
#
# usage: antidote home [-h|--help]
#
# Can be overridden by setting `$ANTIDOTE_HOME`.
#
antidote_home() {
  local result
  if [[ -n "$ANTIDOTE_HOME" ]]; then
    result=$ANTIDOTE_HOME
  else
    result=$(get_cachedir antidote)
  fi
  say $result
}

### Initialize the shell for dynamic bundles.
#
# usage: antidote init [-h|--help]
#        source <(antidote init)
#
# This function changes how the `antidote` command works by sourcing the results of
# `antidote bundle` instead of just generating the Zsh script.
#
antidote_init() {
  say "#!/usr/bin/env zsh"
  say "function antidote {"
  say "  case \"\$1\" in"
  say "    bundle)"
  say "      source <( antidote-main \$@ ) || antidote-main \$@"
  say "      ;;"
  say "    *)"
  say "      antidote-main \$@"
  say "      ;;"
  say "  esac"
  say "}"
}

antidote_path() {
  local bundle bundledir
  local -a results=()
  local -a bundles=("${(@f)$(collect_input "$@")}")
  if (( $#bundles == 0 )); then
    die "antidote: error: required argument 'bundle' not provided, try --help"
  fi
  for bundle in $bundles; do
    if [[ $bundle == '$'* ]]; then
      bundle="${(e)bundle}"
    fi
    bundledir=$(bundle_dir $bundle)
    if [[ ! -d $bundledir ]]; then
      die "antidote: error: $bundle does not exist in cloned paths"
    else
      results+=("$bundledir")
    fi
  done
  say $results
}

antidote() {
  local o_help o_version o_debug
  zparseopts ${ZPARSEOPTS} -- \
    i=o_internal  -internal=i \
    d=o_debug     -debug=d    \
    h=o_help      -help=h     \
    v=o_version   -version=v  ||
    return 1

  if (( ${#o_debug} )) || (( ${#o_internal} )); then
    ANTIDOTE_DEBUG=true
    if (( ${#o_debug} )) || [[ "$ANTIDOTE_TESTING" == true ]]; then
      setopt WARN_CREATE_GLOBAL WARN_NESTED_VAR
    fi
  fi

  if (( ${#o_version} )); then
    version
    return 0
  fi

  # elif (( ${#o_help} )); then
  #   antidote_help "$@"
  #   return 0

  if [[ ${#} -eq 0 ]]; then
    # antidote_help
    return 2
  fi

  local cmd=$1; shift
  if [[ "$ANTIDOTE_DEBUG" == true ]] && [[ "$cmd" == run ]]; then
    cmd="$1"
    shift
    "${cmd}" "$@"
    return $?
  elif (( $+functions[antidote_${cmd}] )); then
    "antidote_${cmd}" "$@"
    return $?
  else
    ERR=2 die "command not found '$cmd'."
  fi
}

# Vars
0=${(%):-%x}
ANTIDOTE_ZSH="${0:A}"
ZPARSEOPTS=( -D -M )
is-at-least 5.8 && ZPARSEOPTS+=( -D -M -F )
TAB="$(printf '\t')"
ANTIDOTE_COMPATIBILITY_MODE=${ANTIDOTE_COMPATIBILITY_MODE:-false}
ANTIDOTE_DEBUG=false
ANTIDOTE_GIT_SITE=${ANTIDOTE_GIT_SITE:-https://github.com}
if [[ -z "$ANTIDOTE_HOME" ]]; then
  ANTIDOTE_HOME=$(get_cachedir antidote)
fi
ANTIDOTE_OSTYPE=${ANTIDOTE_OSTYPE:-OSTYPE}
ANTIDOTE_TESTING=${ANTIDOTE_TESTING:-false}
ANTIDOTE_TMPDIR=${ANTIDOTE_TMPDIR:-TMPDIR}
ANTIDOTE_VERSION="1.10.1"

ANTIDOTE_HELP=$(
cat <<'EOS'
antidote - the cure to slow zsh plugin management

usage: antidote [<flags>] <command> [<args> ...]

flags:
  -h, --help           Show context-sensitive help
  -v, --version        Show application version

commands:
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

antidote "$@"

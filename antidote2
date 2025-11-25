#!/usr/bin/env zsh

# Script path vars.
SCRIPT_PATH="${${(%):-%N}:a}"
SCRIPT_DIR="${SCRIPT_PATH:h}"
SCRIPT_NAME="${SCRIPT_PATH:t}"

# Make sure we're using a supported version of Zsh.
if [[ -n "$ZSH_VERSION" ]]; then
  builtin autoload -Uz is-at-least
  if ! is-at-least 5.4.2; then
    print -ru2 -- "$SCRIPT_NAME: Unsupported Zsh version '$ZSH_VERSION'. Expecting Zsh >=5.4.2."
    exit 1
  fi
  setopt NULL_GLOB NO_BANG_HIST EXTENDED_GLOB NO_MONITOR PIPEFAIL
  zmodload -i zsh/datetime 2>/dev/null || true
else
  shellname=$(ps -p $$ -oargs= | awk 'NR=1{print $1}')
  print -ru2 -- "$SCRIPT_NAME: Expecting zsh or bash. Found '$shellname'."
  exit 1
fi

# Set antidote variables.
ANTIDOTE_VERSION=2.0.0
: "${ANTIDOTE_USE:=}"
: "${ANTIDOTE_GIT_SITE:=https://github.com}"
: "${ANTIDOTE_DEFER_REPO:=https://github.com/romkatv/zsh-defer}"
: "${ANTIDOTE_OSTYPE:=${OSTYPE:-$(uname -s | tr '[:upper:]' '[:lower:]')}}"
: "${ANTIDOTE_DEBUG:=false}"
: "${ANTIDOTE_COMPATIBILITY_MODE:=}"

# -D : Delete flags from the param array once they are detected
# -M : Map a flag to alternative names (useful for defining -s(hort) and --long options)
# -F : Fail if a flad is provided that was not defined in the zparseops spec (added in 5.8)
ANTIDOTE_ZPARSEOPTS=(-D -M)
is-at-least 5.8 && ANTIDOTE_ZPARSEOPTS+=(-F)

# Set variables.
NL=$'\n'
TAB=$'\t'
#SEP=$'\x1F'

# Util functions.
die()  { local ec=$1; shift; warn "$@"; exit "$ec"; }
warn() { printf '%s: %s\n' "$SCRIPT_NAME" "$*" >&2; }
say()  { printf '%s\n' "$@"; }
# is_func() { typeset -f "${1}" >/dev/null 2>&1 ; }
# is_cmd()  { command -v "${1}" >/dev/null 2>&1 ; }
is_true() { [[ -n "$1" ]] && "${1:l}" == (1|y(es|)|t(rue|)|o(n|)) ]]; }

# Trim string.
str_trim() {
  # Trim leading and trailing spaces using parameter expansion.
  printf '%s' "${${1##[[:space:]]##}%%[[:space:]]##}"
}

epoch() {
  if [[ -n "$EPOCHREALTIME" ]]; then
    printf '%s\n' "$EPOCHREALTIME"
  else
    printf '%s.000000\n' "$EPOCHSECONDS"
  fi
}

to_human_time() {
  local start=${1:-$(epoch)}
  local end=${2:-$(epoch)}
  local diff_ms_f diff_ms min sec ms sign=""

  if (( end < start )); then
    sign="-"
    local tmp=$start; start=$end; end=$tmp
  fi

  diff_ms_f=$(( (end - start) * 1000 + 0.5 ))
  diff_ms=${diff_ms_f%.*}

  min=$(( diff_ms / 60000 ))
  sec=$(( (diff_ms / 1000) % 60 ))
  ms=$(( diff_ms % 1000 ))

  # Format mm:ss.mmm with zero padding.
  printf "%s%02d:%02d.%03d\n" "$sign" $min $sec $ms
}

# Get the default cache directory by OS.
cache_dir() {
  local result
  if [[ "${ANTIDOTE_OSTYPE}" == darwin* ]]; then
    result="$HOME/Library/Caches"
  elif [[ "${ANTIDOTE_OSTYPE}" == (cygwin|msys)* ]]; then
    result="${LOCALAPPDATA:-$LocalAppData}"
    if (( $+commands[cygpath] )); then
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
  say "$result"
}

# Collect <redirected or piped> input.
collect_args() {
  local -a results=()

  # Process arguments (split on newlines)
  if (( $# > 0 )); then
    results=("${(f@)${(j:\n:)@}}")
  fi

  # Read from stdin if not a terminal
  if [[ ! -t 0 ]]; then
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
      results+=("$line")
    done
  fi

  typeset -ga reply=("${results[@]}")
  [[ "$ANTIDOTE_DEBUG" != true ]] || say "${reply[@]}"
}

# Safe rm wrapper.
del() {
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

  tmpdir="$(temp_dir)"
  for p in "$@"; do
    p="${p:a}"
    if [[ "$p" != "$HOME"/* ]] && [[ "$p" != "$tmpdir"/* ]]; then
      warn "Blocked attempt to rm path: '$p'."
      return 1
    fi
  done

  rm "${rmflags[@]}" -- "$@"
}

# git command
gitcmd() {
  local result ret
  result="$("${ANTIDOTE_GITCMD:-git}" "$@" 2>&1)"
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

# Use shell's lexer for word splitting rules
wordsplit() {
  # Use the (z) flag for shell word splitting
  typeset -ga reply=("${(z)*}")
  [[ "$ANTIDOTE_DEBUG" != true ]] || say "${reply[@]}"
}

# Parse bundles into an associative array.
parse_bundles() {
  # Creates a bundle associative array with following contents:
  #   bundle[_]: Reference name of the bundle
  #   bundle[_line]: The line number from .zsh_plugins.txt
  #   bundle[_path]: The bundle path
  #   bundle[_type]: The bundle type
  #   bundle[_url]: The bundle URL
  #   bundle[$annotation]: key:value pairs for all provided annotations

  local defer_repo_path pair key value line
  local lineno=0 itemno=0 start_time=$(epoch)
  local -a bundles=() kvpairs=() results=() cloning=()
  local -A abundle=()

  defer_repo_path="$(bundle_path "$ANTIDOTE_DEFER_REPO")"

  collect_args "$@" >/dev/null
  bundles=( "${reply[@]}" )
  unset reply

  for line in $bundles; do
    (( lineno++ ))

    # Remove anything after the first '#' and trim
    line="${line%%\#*}"
    line="$(str_trim "$line")"

    # Skip empty lines
    [[ -n "$line" ]] || continue

    # Split line into key-value pairs with quoting
    wordsplit "${line}" >/dev/null
    kvpairs=("${reply[@]}")
    unset reply

    abundle=()
    abundle[_line]="$lineno"
    itemno=0

    for pair in $kvpairs; do
      (( itemno++ ))
      # 1st field gets a '_:' prefix so we can treat everything as key:val pairs
      if [[ $itemno -eq 1 ]]; then
        case $pair in
          git*|http*) pair="_:$pair" ;;
          *:*) ;;
          *) pair="_:$pair" ;;
        esac
      fi

      if [[ "$pair" != *:* ]]; then
        die 1 "missing ':' in bundle annotation '$pair' on line $lineno"
      fi

      key="${pair%%:*}"  # Extract key (before first ':')
      if [[ "$pair" == *:* ]]; then
        value="${pair#*:}"  # Extract value (after first ':')
      else
        value=""
      fi
      abundle[$key]="$value"
    done

    # Expand bundles
    if [[ -v abundle[_] ]]; then
      # Default to kind:zsh
      [[ -v abundle[kind] ]] || abundle[kind]=zsh

      # Determine bundle type
      abundle[_type]="$(bundle_type $abundle[_])"

      # URL
      if [[ $abundle[_type] == (url|short) ]]; then
        abundle[_url]="$(bundle_url "$abundle[_]")"
      fi

      # Path
      abundle[_path]="$(bundle_path "$abundle[_]")"
    fi

    # Clone if missing.
    if [[ -n "$abundle[_url]" && ! -e "$abundle[_path]" ]] && ! (( $cloning[(Ie)$abundle[_path]] )); then
      if [[ "$abundle[kind]" == defer ]] && ! (( $cloning[(Ie)$defer_repo_path] )); then
        print -ru2 -- "# antidote cloning $(bundle_short $ANTIDOTE_DEFER_REPO)..."
        cloning+=("$defer_repo_path")
        git_clone "$ANTIDOTE_DEFER_REPO" "$defer_repo_path" &
      fi

      print -ru2 -- "# antidote cloning $(bundle_short $abundle[_])..."
      cloning+=("$abundle[_path]")
      git_clone "$abundle[_url]" "$abundle[_path]" "$abundle[branch]" &
    fi

    results+=( "$(declare -p abundle)" )
  done
  wait

  if (( ${#cloning} > 0 )); then
    print -ru2 -- "# antidote finished cloning ${#cloning} bundles in $(to_human_time "$start_time")"
  fi

  # Set reply array
  typeset -ga reply=("${results[@]}")
  [[ "$ANTIDOTE_DEBUG" != true ]] || say "${reply[@]}"
}

# Print the OS specific temp dir.
temp_dir() {
  local result tmpd

  # Set the appropriate temp directory (cargo cult code from p10k)
  if [[ -n "$TMPDIR" && (( -d "$TMPDIR" && -w "$TMPDIR" ) || ! ( -d /tmp && -w /tmp )) ]]; then
    tmpd="${TMPDIR%/}"
  else
    tmpd="/tmp"
  fi
  result="$tmpd"
  say "$result"
}

# Get the URL for a bundle.
bundle_url() {
  local bundle=$1
  if [[ $bundle == *://* || $bundle == git@*:*/* ]]; then
    say "$bundle"
  elif [[ $bundle != /* && $bundle == */* && $bundle != */*/* ]]; then
    say "${ANTIDOTE_GIT_SITE:-https://github.com}/$bundle"
  else
    return 1
  fi
}

# Convert git URLs to user/repo format.
bundle_short() {
  local str

  str="${1%/}"       # strip trailing /
  str="${str%.git}"  # strip trailing .git

  # strip the domain
  if [[ "$str" == *://*/*/* ]]; then
    str="${str#*://*/}"
  elif [[ "$str" == git@*:*/* ]]; then
    str="${str#git@*:}"
  elif [[ "$str" != */* ]]; then
    return 1
  else
    str="${str:h:t}/${str:t}"
  fi

  # make sure whatever is left is repo_user/repo_name
  [[ "$str" == */* ]] && [[ "$str" != */*/* ]] || return 1
  say "$str"
}

# Bundle type.
bundle_type() {
  local result
  case "$1" in
    (\$|~|/)*)   result=path  ;;
    http*://*)   result=url   ;;
    (git|ssh)@*) result=url   ;;
    */*/*)       result=?     ;;
    */*)         result=short ;;
    *)           result=use   ;;
  esac
  typeset -g REPLY=$result
  say $REPLY
}

# Get the base directory of a bundle.
bundle_path() {
  local url bundle bundle_type
  local -a parts=()

  if (( $# == 0 )); then
    die 1 "required argument 'bundle' not provided"
  fi

  bundle="$1"
  bundle_type="$(bundle_type $bundle)"
  if [[ "$bundle_type" == "path" ]]; then
    say "$bundle"
  elif [[ "$bundle_type" == "url" ]]; then
    if is_true "$ANTIDOTE_COMPATIBILITY_MODE"; then
      url="$(bundle_url "$bundle")"
      url=${url%.git}
      url=${url:gs/\@/-AT-}
      url=${url:gs/\:/-COLON-}
      url=${url:gs/\//-SLASH-}
      say "$(antidote_home)/$url"
    else
      # user/repo format
      # ex: $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions
      bundle=${bundle%.git}
      bundle=${bundle:gs/\:/\/}
      parts=( "${(ps./.)bundle}" )
      if [[ ${#parts} -gt 1 ]]; then
        say "$(antidote_home)/${parts[-2]}/${parts[-1]}"
      else
        say "$(antidote_home)/$bundle"
      fi
    fi
  elif [[ "$bundle" == */* && "$bundle" != */*/* ]]; then
    say "$(antidote_home)/$bundle"
  else
    die 1 "unexpected bundle argument '$bundle'."
  fi
}

# Print help.
print_help() {
  0="${(%):-%x}"
  local cmd funcname line print_on=0
  local -a lines

  # Read whole file into an array (pure zsh, no external commands).
  lines=("${(@f)$(<"${0:a}")}")
  cmd="$1"
  if (( $+functions[antidote_${cmd}] )); then
    funcname="antidote_${cmd}"
  else
    funcname="antidote2"
  fi

  for line in $lines; do
    # Trim leading and trailing spaces.
    line="$(str_trim "$line")"
    if [[ $line == "${funcname}() {" ]]; then
      print_on=1
    elif [[ $line == "##?"* ]]; then
      line="${line#\#\#\? }"
      line="${line#\#\#\?}"
      if [[ $print_on -ne 0 ]]; then
        say "$line"
      fi
    elif [[ $line == "}" && $print_on -ne 0 ]]; then
      return
    fi
  done
}

# git helpers.
git_basedir()  { gitcmd -C "$1" rev-parse --show-toplevel; }
git_url()      { gitcmd -C "$1" config remote.origin.url; }
git_branch()   { gitcmd -C "$1" rev-parse --abbrev-ref HEAD; }
git_sha()      { gitcmd -C "$1" rev-parse HEAD; }
git_repodate() { gitcmd -C "$1" log -1 --format=%cd --date=short; }
git_clone() {
  local -a o_branch=()
  [[ -z "$3" ]] || o_branch=(--branch "$3")
  gitcmd clone --quiet --recurse-submodules --shallow-submodules $o_branch "$1" "$2"
}

# Parse bundles into an associative array.
antidote_bundle() {
  ##? Usage: antidote bundle [<bundles>...]
  ##?
  ##? Clones a bundle and prints its source line.
  ##?
  ##? Flags:
  ##?   -h, --help   Show context-sensitive help.
  ##?
  ##? Args:
  ##?   [<bundles>]  Bundle list.
  [[ "$1" == (-h|--help) ]] && { print_help bundle; return }

  local bundle_str
  local -a bundles
  local -A bundle

  parse_bundles "$@" || die 1 "bundle error: unable to parse bundles"
  bundles=( "${reply[@]}" )
  unset reply

  for bundle_str in $bundles; do
    eval "$bundle_str"  # populate abundle
    # echo "bundle: $bundle_str"
    declare -p abundle
  done
}

# Print help.
antidote_help() {
  print_help "$@"
}

# Print home directory for antidote.
antidote_home() {
  ##? usage: antidote home
  ##?
  ##? Prints where antidote is cloning bundles.
  ##?
  ##? Flags:
  ##?   -h, --help   Show context-sensitive help.
  [[ "$1" == (-h|--help) ]] && { print_help home; return }

  local result

  case "$1" in
    -h|--help)
      antidote_help home
      return 0
      ;;
  esac

  if [[ -n "$ANTIDOTE_HOME" ]]; then
    result="$ANTIDOTE_HOME"
  else
    result="$(cache_dir antidote)"
  fi
  printf '%s\n' "$result"
}

# Initialize the shell for dynamic bundles.
antidote_init() {
  ##? usage: antidote init
  ##?
  ##? Initializes the shell so antidote can load bundles dynmically.
  ##?
  ##? Flags:
  ##?   -h, --help   Show context-sensitive help.
  [[ "$1" == (-h|--help) ]] && { print_help init; return }

  local -a script=(
    "#!/usr/bin/env zsh"
    "antidote() {"
    "  local antidote_cmd=\"$SCRIPT_PATH\""
    "  case \"\$1\" in"
    "    bundle)"
    "      source <( \$antidote_cmd \$@ ) || \$antidote_cmd \$@"
    "      ;;"
    "    *)"
    "      \$antidote_cmd \$@"
    "      ;;"
    "  esac"
    "}"
    ""
    "_antidote() {"
    "  IFS=' ' read -A reply <<< \"help bundle update home purge list init\""
    "}"
    "compctl -K _antidote antidote"
  )
  printf '%s\n' "${script[@]}"
}

# List cloned bundles.
antidote_list() {
  ##? usage: antidote list [-d|--details] [-bcprsu]
  ##?
  ##? Lists all currently installed bundles
  ##?
  ##? Flags:
  ##?   -h, --help     Show context-sensitive help.
  ##?   -d, --detail   Show full bundle details.
  ##?
  ##? Format flags:
  ##?   -b             Bundle's branch.
  ##?   -c             Bundle's last commit date.
  ##?   -p             Bundle's path.
  ##?   -r             Bundle's short repo name.
  ##?   -s             Bundle's SHA.
  ##?   -u             Bundle's URL.

  local i spec bundle_dir bundle_gitdir branch sha repodate url short_repo
  local -a bundles=() o_detail o_help o_format
  zparseopts ${ANTIDOTE_ZPARSEOPTS} -- \
    {d,-detail}=o_detail \
    {h,-help}=o_help \
    b+=o_format \
    p+=o_format \
    u+=o_format \
    r+=o_format \
    s+=o_format \
    c+=o_format ||
    return 1

  if (( ${#o_help} )); then
    antidote_help list
    return 0
  fi

  if is_true "$ANTIDOTE_COMPATIBILITY_MODE"; then
    bundles=($(antidote_home)/*/.git(N/))
  else
    bundles=($(antidote_home)/*/*/.git(N/))
  fi

  # Set the vars.
  for bundle_gitdir in $bundles; do
    # Do this in parallel because we want speed.
    bundle_dir="${bundle_gitdir:a:h}"
    {
      exec {fd_branch}< <(git_branch "$bundle_dir")
      exec {fd_sha}< <(git_sha "$bundle_dir")
      exec {fd_repodate}< <(git_repodate "$bundle_dir")
      exec {fd_url}< <(git_url "$bundle_dir")

      IFS= read -r branch <&$fd_branch
      IFS= read -r sha <&$fd_sha
      IFS= read -r repodate <&$fd_repodate
      IFS= read -r url <&$fd_url
    } always {
      exec {fd_branch}>&- 2>/dev/null
      exec {fd_sha}>&- 2>/dev/null
      exec {fd_repodate}>&- 2>/dev/null
      exec {fd_url}>&- 2>/dev/null
    }
    # branch=$(git_branch "$bundle_dir")
    # sha=$(git_sha "$bundle_dir")
    # repodate=$(git_repodate "$bundle_dir")
    # url=$(git_url "$bundle_dir")
    short_repo="$(bundle_short "$url" 2>/dev/null)"

    # If we want full details, emit verbose block.
    if (( ${#o_format} )); then
      i=0
      for spec in $o_format; do
        (( i++ ))
        (( i > 1 )) && printf '%s' $TAB
        case $spec in
          -b) printf '%s' "$branch"     ;;
          -p) printf '%s' "$bundle_dir" ;;
          -r) printf '%s' "$short_repo" ;;
          -s) printf '%s' "$sha"        ;;
          -u) printf '%s' "$url"        ;;
          -c) printf '%s' "$repodate"   ;;
        esac
      done
      print
    elif (( ${#o_detail} )); then
      say "$short_repo"
      say "====================================================="
      say "Dir:         $bundle_dir"
      say "Branch:      $branch"
      say "SHA:         $sha"
      say "URL:         $url"
      say "Last Commit: $repodate"
      say
    else
      # Default to 'repo dir'
      printf '%-40s  %s\n' "$short_repo" "$bundle_dir"
    fi
  done
}

# Print the path of a cloned bundle.
antidote_path() {
  ##? usage: antidote path <bundle>
  ##?
  ##? Prints the path of a currently cloned bundle.
  ##?
  ##? Flags:
  ##?   -h, --help   Show context-sensitive help.
  ##?
  ##? Args:
  ##?   <bundle>     The Bundle path to print.
  [[ "$1" == (-h|--help) ]] && { print_help path; return }

  local bundle_dir bundle="$1"
  (( $# > 0 )) || die 1 "required argument 'bundle' not provided."

  # If a real path was provided, then that's the path.
  if [[ -e "$bundle" && "$bundle" == /* ]]; then
    say "$bundle" && return 0
  fi

  # Figure out the bundle directory.
  bundle_dir="$(bundle_path "$bundle")"

  # If we haven't errored and we have a valid directory, print it.
  if [[ -d "$bundle_dir" ]]; then
    say "$bundle_dir"
  else
    die 1 "path error: '$bundle' does not exist in cloned paths."
  fi
}

# Remove a bundle.
antidote_purge() {
  ##? usage: antidote purge <bundle>
  ##?
  ##? Purges a bundle from your computer.
  ##?
  ##? Flags:
  ##?   -h, --help   Show context-sensitive help.
  ##?
  ##? Args:
  ##?   <bundle>     The bundle to be purged.

  local bundle
  local -a o_help o_all bundles
  zparseopts ${ANTIDOTE_ZPARSEOPTS} -- \
    {h,-help}=o_help \
    {a,-all}=o_all   ||
    return 1

  if (( $#o_help )); then
    antidote_help purge
    return
  fi

  if [[ $# -eq 0 ]] && ! (( $#o_all )); then
    die 1 "purge error: required argument 'bundle' not provided, try --help"
  fi

  if (( $#o_all )); then
    (( ! $# )) || die 1 "purge error: cannot use '${o_all[-1]}' flag with named bundle arguments."
    bundles=( ${(@f)"$(antidote_list -p)"} )
  else
    bundles=( ${(@f)"$(antidote_path "$1" 2>/dev/null)"} )
    [[ $? -eq 0 ]] || die 1 "purge error: '$1' does not exist in cloned paths."
  fi

  (( ${#bundles} )) || die 1 "no bundles to purge."

  for bundle in $bundles; do
    say "Removing $bundle..."
    del -rf -- "$bundle"
  done
}

# Get the antidote version.
antidote_version() {
  local ver gitsha
  ver="$ANTIDOTE_VERSION"
  gitsha="$(gitcmd -C "$SCRIPT_DIR" rev-parse --short HEAD 2>/dev/null)"
  [[ -z "$gitsha" ]] || ver="$ver ($gitsha)"
  say "antidote version $ver"
}

antidote2() {
  ##? antidote - the cure to slow zsh plugin management
  ##?
  ##? Usage: antidote [<flags>] <command> [<args> ...]
  ##?
  ##? Flags:
  ##?   -h, --help             Show context-sensitive help.
  ##?   -v, --version          Show application version.
  ##?
  ##? Commands:
  ##?   help <command>         Show documentation.
  ##?   bundle [<bundles>...]  Clone bundle(s) and generate Zsh source.
  ##?   update                 Update cloned bundles.
  ##?   home                   Print where antidote is cloning bundles.
  ##?   purge <bundle>         Remove a cloned bundle.
  ##?   list                   List cloned bundles.
  ##?   path <bundle>          Print the path of a cloned bundle.
  ##?   init                   Initialize the shell for dynamic bundles.

  local o_help o_version o_debug
  zparseopts ${ANTIDOTE_ZPARSEOPTS} -- \
    d=o_debug   -debug=d   \
    h=o_help    -help=h    \
    v=o_version -version=v ||
    return 1

  if (( ${#o_debug} )); then
    ANTIDOTE_DEBUG=true
    setopt WARN_CREATE_GLOBAL WARN_NESTED_VAR
  fi

  if (( ${#o_version} )); then
    antidote_version
    return 0

  elif (( ${#o_help} )); then
    antidote_help "$@"
    return 0

  elif [[ ${#} -eq 0 ]]; then
    antidote_help
    return 2
  fi

  local cmd=${1}; shift
  if [[ "$ANTIDOTE_DEBUG" == true ]] && [[ "$cmd" == run ]]; then
    cmd="$1"
    shift
    "${cmd}" "$@"
    return $?
  elif (( $+functions[antidote_${cmd}] )); then
    "antidote_${cmd}" "$@"
    return $?
  else
    die 2 "command not found '$cmd'."
  fi
}
antidote2 "$@"

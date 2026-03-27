#!/usr/bin/env zsh

# Ensure we're in Zsh and not bash
if [ -n "$BASH_VERSION" ]; then
  echo >&2 "antidote: This script requires Zsh, not Bash"
  return 1 2>/dev/null || exit 1
elif [ -z "$ZSH_VERSION" ]; then
  shellname="$(ps -p $$ -oargs= | awk 'NR=1{print $1}')"
  echo >&2 "antidote: This script requires Zsh, not '$shellname'."
  return 1 2>/dev/null || exit 1
fi

# When sourced, behave differently
0=${(%):-%N}
if [[ ":${ZSH_EVAL_CONTEXT}:" == *:file:* ]]; then
  typeset -f antidote-setup &>/dev/null && unfunction antidote-setup
  builtin autoload -Uz ${0:A:h}/functions/antidote-setup
  antidote-setup
  return 0
fi

# Initial vars
builtin autoload -Uz is-at-least
ZPARSEOPTS=( -D -M )
is-at-least 5.8 && ZPARSEOPTS+=( -F )
typeset -gr TAB=$'\t'
typeset -gr NL=$'\n'
typeset -g REPLY
typeset -ga reply=()

# Zsh options needed by antidote
setopt extended_glob warn_create_global # warn_nested_var

# Internal profiling support
[[ -n "$ANTIDOTE_PROFILE" ]] && zmodload zsh/zprof
zmodload zsh/datetime

# Load config: source config file then apply any serialized zstyles
() {
  local cfg=${ANTIDOTE_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/antidote/config.zsh}
  [[ -f "$cfg" ]] && source "$cfg"
}
[[ -n "$ANTIDOTE_ZSTYLES" ]] && eval "$ANTIDOTE_ZSTYLES"

# Helpers
die()  { warn "$@"; exit "${ERR:-1}"; }
say()  { printf '%s\n' "$@"; }
warn() { say "$@" >&2; }

# git helpers.
git() {
  local result err
  result="$(command "$ANTIDOTE_GIT_CMD" "$@" 2>&1)"
  err=$?
  if [[ "$err" -ne 0 ]]; then
    warn "antidote: unexpected git error on command 'git $*'."
    if [[ -n "$result" ]]; then
      warn "antidote: error details:"
      warn "$result"
    fi
    return $err
  fi
  if [[ -n "$result" ]]; then
    say "$result"
  fi
}
git_checkout_detach()   { git -C "$1" checkout --quiet --detach "$2"; }
git_clone()             { local d=$1; shift; git clone --depth 1 --no-local --quiet --recurse-submodules --shallow-submodules "$@" "$d"; }
git_config_get()        { git -C "$1" config --get "$2" 2>/dev/null; }
git_config_set()        { git -C "$1" config "$2" "$3"; }
git_config_unset()      { git -C "$1" config --unset "$2" 2>/dev/null; }
git_fetch()             { local d=$1; shift; git -C "$d" fetch --quiet "$@"; }
git_is_shallow()        { [[ -f "$1/.git/shallow" ]] || [[ "$(git -C "$1" rev-parse --is-shallow-repository 2>/dev/null)" == "true" ]] }
git_log_oneline()       { git -C "$1" --no-pager log --abbrev=7 --oneline --ancestry-path --first-parent "${2}^..${3}" 2>/dev/null; }
git_sha()               { git -C "${@[-1]}" rev-parse ${@[1,-2]} HEAD; }
git_submodule_sync()    { git -C "$1" submodule --quiet sync --recursive; }
git_submodule_update()  { git -C "$1" submodule --quiet update --init --recursive --depth 1; }
git_url()               { git -C "$1" config remote.origin.url; }
git_checkout_pin() {
  local dir="$1" sha="$2" bname="$3"
  if ! git_checkout_detach "$dir" "$sha" 2>/dev/null; then
    if ! git_fetch "$dir" --depth 1 origin "$sha" 2>/dev/null \
      || ! git_checkout_detach "$dir" "$sha"; then
      warn "antidote: error: pin commit '$sha' not found for $bname"
      return 1
    fi
  fi
}
git_pull() {
  local -a autostash_flag=(--autostash)
  [[ "$ANTIDOTE_GIT_AUTOSTASH" != true ]] && autostash_flag=()
  git -C "$1" pull --quiet --ff --rebase $autostash_flag
}

# True if the bundle is a git repo (not a local path/file).
is_repo() {
  bundle_type "$1"
  [[ $REPLY == (repo|url|ssh_url) ]]
}

# Find all cloned bundles under ANTIDOTE_HOME.
find_bundles() {
  command find -H "$ANTIDOTE_HOME" -type d -name .git -prune -print 2>/dev/null | \
    sed 's|/.git$||' | sort
}

bulk_clone() {
  local bundle_str branch pin zsh_defer=0
  local -A bundle
  local -aU script

  while IFS= read -r bundle_str; do
    [[ -n "$bundle_str" ]] || continue
    typeset -A bundle=("${(@Q)${(z)bundle_str}}")
    is_repo $bundle[__bundle__] || continue

    if [[ -n "${bundle[branch]}" ]]; then
      branch="--branch ${bundle[branch]} "
    else
      branch=
    fi

    if [[ -n "${bundle[pin]}" ]]; then
      pin="--pin ${bundle[pin]} "
    else
      pin=
    fi

    if [[ "${bundle[kind]}" == defer && $zsh_defer == 0 ]]; then
      zsh_defer=1
      script+=("zsh_script --kind clone ${ANTIDOTE_DEFER_BUNDLE} &")
    fi
    script+=("zsh_script --kind clone ${branch}${pin}${bundle[__bundle__]} &")
  done

  # Print script
  if [[ ${#script} -gt 0 ]]; then
    printf '%s\n' ${(o)script[@]}
    printf '%s\n' "wait"
  fi
}

bundle_parser() {
  local line lineno arg partno key bname btype input
  local -a args bundle_arr lines
  local -A bundle

  # Read all input and normalize line endings (\r\n, \r, \n -> \n)
  input=$(cat)
  input=${input//$'\r\n'/$'\n'}
  input=${input//$'\r'/$'\n'}
  lines=("${(@f)input}")

  lineno=1
  for line in "${lines[@]}"; do
    # (z): use shell wordsplitting rules
    # (Q): remove one level of quotes
    args=(${(Q)${(z)line}})
    partno=0
    for arg in $args; do
      [[ $arg == \#* ]] && break
      (( partno++ ))
      if (( partno == 1 )); then
        bundle=()
        bundle[__lineno__]=$lineno
        bundle[__bundle__]=$arg
      else
        if [[ "$arg" == *:* ]]; then
          key=${arg%%:*}
          bundle[$key]=${arg#*:}
        else
          bundle[__error__]="error: Expecting 'key:value' form for annotation '$arg'."
        fi
      fi
    done
    if [[ $partno -gt 0 ]]; then
      # Compute metadata keys for repo and URL bundles
      bname="$bundle[__bundle__]"
      bundle_type "$bname"; btype=$REPLY
      bundle[__type__]="$btype"
      if [[ "$btype" == (repo|url|ssh_url) ]]; then
        tourl "$bname"; bundle[__url__]=$REPLY
        short_repo_name "$bname"; bundle[__short__]=$REPLY
        bundle_dir "$bname"; bundle[__dir__]=$REPLY
      fi

      bundle_arr=(__lineno__ $bundle[__lineno__])
      for key in ${(ko)bundle:#__lineno__}; do
        bundle_arr+=("${(q)key}" "${(q)bundle[$key]}")
      done
      printf '%s\n' "${bundle_arr[*]}"
    fi
    (( lineno++ ))
  done
}

version() {
  local ver="$ANTIDOTE_VERSION"
  local gitsha
  if [[ "$ANTIDOTE_VERSION_SHOW_SHA" == true ]]; then
    gitsha=$(git_sha --short ${ANTIDOTE_ZSH:h})
    [[ -z "$gitsha" ]] || ver="$ver ($gitsha)"
  fi
  say "antidote version $ver"
}

diagnostics() {
  local antidote_dir="${ANTIDOTE_ZSH:A:h}"
  local antidote_ver="$ANTIDOTE_VERSION"
  local antidote_sha num_bundles num_snapshots zstyle_output line configfile bundlefile staticfile
  local -a bundle_dirs snapshots

  antidote_sha=$(command git -C "$antidote_dir" rev-parse --short HEAD 2>/dev/null) || antidote_sha=""
  if [[ -d "$ANTIDOTE_HOME" ]]; then
    bundle_dirs=( "$ANTIDOTE_HOME"/*(N/) )
    num_bundles=${#bundle_dirs}
  else
    num_bundles=0
  fi
  if [[ -d "$ANTIDOTE_SNAPSHOT_DIR" ]]; then
    snapshots=( "$ANTIDOTE_SNAPSHOT_DIR"/snapshot-*.txt(N) )
    num_snapshots=${#snapshots}
  else
    num_snapshots=0
  fi

  say "antidote:"
  if [[ -n "$antidote_sha" ]]; then
    say "  version:      $antidote_ver ($antidote_sha)"
  else
    say "  version:      $antidote_ver"
  fi
  say "  path:         $antidote_dir"
  say "  home:         $ANTIDOTE_HOME"
  say "  bundles:      $num_bundles"
  say "  snapshot dir: $ANTIDOTE_SNAPSHOT_DIR"
  say "  snapshots:    $num_snapshots"
  configfile=${ANTIDOTE_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/antidote/config.zsh}
  if [[ -f "$configfile" ]]; then
    say "  config:       $configfile"
  else
    say "  config:       $configfile (not found)"
  fi
  zstyle -s ':antidote:bundle' file 'bundlefile' ||
    bundlefile=${ZDOTDIR:-$HOME}/.zsh_plugins.txt
  if [[ -f "$bundlefile" ]]; then
    say "  bundle file:  $bundlefile"
  else
    say "  bundle file:  $bundlefile (not found)"
  fi
  zstyle -s ':antidote:static' file 'staticfile'
  if [[ -z "$staticfile" ]]; then
    if [[ -z "$bundlefile:t:r" ]]; then
      staticfile=${bundlefile}.zsh
    else
      staticfile=${bundlefile:r}.zsh
    fi
  fi
  if [[ -f "$staticfile" ]]; then
    say "  static file:  $staticfile"
  else
    say "  static file:  $staticfile (not found)"
  fi
  say ""
  say "system/utils:"
  say "  system:       $(uname -srm 2>/dev/null || say '(unknown)')"
  say "  zsh path:     ${commands[zsh]:-(not found)}"
  say "  zsh version:  $(zsh --version 2>&1 || say '(unknown)')"
  say "  git path:     ${commands[${ANTIDOTE_GIT_CMD}]:-(not found)}"
  say "  git version:  $(${ANTIDOTE_GIT_CMD:-git} --version 2>&1 || say '(unknown)')"
  say ""
  say "environment:"
  say "  ANTIDOTE_HOME:    ${ANTIDOTE_HOME:-(not set)}"
  say "  OSTYPE:           ${OSTYPE:-(not set)}"
  say "  TERM:             ${TERM:-(not set)}"
  say "  TERM_PROGRAM:     ${TERM_PROGRAM:-(not set)}"
  say "  XDG_CONFIG_HOME:  ${XDG_CONFIG_HOME:-(not set)}"
  say "  ZDOTDIR:          ${ZDOTDIR:-(not set)}"
  say "  ZSH_VERSION:      ${ZSH_VERSION:-(not set)}"
  say ""
  say "zstyles:"
  zstyle_output=$(eval "$ANTIDOTE_ZSTYLES"; zstyle -L ':antidote:*' 2>/dev/null)
  if [[ -n "$zstyle_output" ]]; then
    for line in "${(@f)zstyle_output}"; do
      say "  $line"
    done
  else
    say "  (none)"
  fi
}

usage() {
  say "$ANTIDOTE_HELP"
}

supports_color() {
  [[ -n "$NO_COLOR" ]] && return 1
  [[ -n "$CLICOLOR_FORCE" ]] && return 0
  [[ ! -t 1 ]] && return 1
  [[ "$COLORTERM" == (truecolor|24bit) || "$TERM" == (*256color*|*rxvt*) ]]
}

tourl() {
  REPLY=$1
  if [[ $1 != *://* && $1 != git@*:*/* ]]; then
    if [[ ${ANTIDOTE_GIT_PROTOCOL:-https} == ssh ]]; then
      REPLY=git@${ANTIDOTE_GIT_SITE}:$1
    else
      REPLY=https://${ANTIDOTE_GIT_SITE}/$1
    fi
  fi
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
  if [[ -e "$bundle" ]]; then
    [[ -f $bundle ]] && REPLY=file || REPLY=dir
  elif [[ -z "${bundle// }" ]]; then
    REPLY=empty
  else
    case "$bundle" in
      (/|~|'$'|'.')*)  REPLY=path     ;;
      *://*)           REPLY=url      ;;
      *@*:*/*)         REPLY=ssh_url  ;;
      *(:|@)*)         REPLY='?'      ;;
      */*/*)           REPLY=relpath  ;;
      */)              REPLY=relpath  ;;
      */*)             REPLY=repo     ;;
      *)               REPLY=word     ;;
    esac
  fi
}

# Convert URLs and paths to short user/repo form
short_repo_name() {
  local -a parts
  REPLY=${1%.git}
  if [[ "$REPLY" != git@*:*/* ]]; then
    REPLY=${REPLY:gs/\:/\/}
    parts=(${(ps./.)REPLY})
    REPLY=${parts[-2]}/${parts[-1]}
  fi
}

bundle_name() {
  bundle_type "$1"
  if [[ "$REPLY" == (url|ssh_url) ]] ; then
    short_repo_name "$1"
  else
    REPLY=${1/#\~\//\$HOME/}
    REPLY=${REPLY/#$HOME/\$HOME}
  fi
}

initfiles() {
  local dir
  dir=${1:A}
  reply=($dir/${dir:A:t}.plugin.zsh(N))
  [[ $#reply -gt 0 ]] || reply=($dir/*.plugin.zsh(N))
  [[ $#reply -gt 0 ]] || reply=($dir/*.zsh(N))
  [[ $#reply -gt 0 ]] || reply=($dir/*.sh(N))
  [[ $#reply -gt 0 ]] || reply=($dir/*.zsh-theme(N))
  reply=(${(u)reply[@]})
  (( $#reply )) || return 1
}

get_dir() {
  local kind="$1" suffix="$2" result
  if [[ "${ANTIDOTE_OSTYPE}" == darwin* ]]; then
    case $kind in
      cache) result=$HOME/Library/Caches ;;
      data)  result="$HOME/Library/Application Support" ;;
    esac
  elif [[ "${ANTIDOTE_OSTYPE}" == (cygwin|msys)* ]]; then
    result=$ANTIDOTE_LOCALAPPDATA
    if (( $+commands[cygpath] )); then
      result=$(cygpath "$result")
    fi
  else
    case $kind in
      cache) result=${XDG_CACHE_HOME:-$HOME/.cache} ;;
      data)  result=${XDG_DATA_HOME:-$HOME/.local/share} ;;
    esac
  fi

  if [[ -n "$suffix" ]]; then
    if [[ $result == *\\* ]] && [[ $result != */* ]]; then
      result+="\\$suffix"
    else
      result+="/$suffix"
    fi
  fi
  say $result
}
get_cachedir() { get_dir cache "$@"; }
get_datadir()  { get_dir data "$@"; }

# Print the OS specific temp dir.
temp_dir() {
  local tmpd=/tmp
  # Use TMPDIR if it has a value and is better than /tmp
  if [[ -n "$ANTIDOTE_TMPDIR" ]]; then
    # Use ANTIDOTE_TMPDIR if it exists and is writable
    if [[ -d "$ANTIDOTE_TMPDIR" ]] && [[ -w "$ANTIDOTE_TMPDIR" ]]; then
      tmpd="${ANTIDOTE_TMPDIR%/}"
    elif [[ ! -d /tmp ]] || [[ ! -w /tmp ]]; then
      # Fall back to ANTIDOTE_TMPDIR only if /tmp is unusable
      tmpd="${ANTIDOTE_TMPDIR%/}"
    fi
  fi
  say "$tmpd"
}

del() {
  local p tmpdir

  (( $# > 0 )) || return 1

  tmpdir=$(temp_dir)
  for p in $@; do
    p="${p:a}"
    if [[ "$p" != ${HOME}/* ]] && [[ "$p" != ${tmpdir}/* ]]; then
      die "antidote: Blocked attempt to rm path: '$p'."
    fi
  done

  rm -rf -- "$@"
}

### Create a cross-platform temporary directory/file for antidote.
# usage: maketmp [-d] [-s suffix]
#   -d   Create a directory rather than a file
#   -s   Use this for the temp file/dir
# Returns the path of created temp directory/file.
maketmp() {
  local -a o_dir o_suffix
  local tmpbase pattern

  zparseopts ${ZPARSEOPTS} -- d=o_dir s:=o_suffix

  # Set the appropriate temp directory (cargo cult code from p10k)
  tmpbase=$(temp_dir)

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

# Print a path, replacing $HOME with the literal string "$HOME" unless escaped style.
print_path() {
  if [[ $ANTIDOTE_PATH_STYLE == escaped ]]; then
    REPLY=$1
  else
    REPLY=${1/#$HOME/\$HOME}
  fi
}

# Indent each line of input by 2 spaces.
indent() {
  local -a lines
  lines=("${(@f)$(collect_input "$@")}")
  printf '  %s\n' $lines
}

bundle_zcompile() {
  builtin autoload -Uz zrecompile

  local -a bundles
  if [[ -z "$1" ]]; then
    bundles=($(antidote_list --dirs))
  elif [[ -f "$1" ]]; then
    zrecompile -pq "$1"
    return
  elif [[ -d "$1" ]]; then
    bundles=($1)
  else
    bundles=($(antidote_path "$1"))
  fi

  local bundle zfile
  for bundle in $bundles; do
    for zfile in ${bundle}/**/*.zsh{,-theme}(N); do
      [[ $zfile != */test-data/* ]] || continue
      zrecompile -pq "$zfile"
    done
  done
}

# Read input from args, pipe, or redirect.
collect_input() {
  local data
  local -a input=()
  if (( $# > 0 )); then
    input=("${(s.\n.)${@}}")
  elif [[ ! -t 0 ]]; then
    while IFS= read -r data || [[ -n "$data" ]]; do
      input+=("$data")
    done
  fi
  printf '%s\n' "${input[@]}"
}

### Compute the bundle directory path for a given path-style.
#
# Unlike bundle_dir, this always computes based on the requested style
# without checking for existing directories.
#
__bundle_dir_by_style() {
  local url=$1 style=${2:-$ANTIDOTE_PATH_STYLE}
  REPLY=$url
  case $style in
    escaped)
      REPLY=${REPLY:gs/\@/-AT-}
      REPLY=${REPLY:gs/\:/-COLON-}
      REPLY=${REPLY:gs/\//-SLASH-}
      ;;
    *)
      if [[ $REPLY == https://* ]]; then
        REPLY=${REPLY#https://}
      elif [[ $REPLY == git@*:* ]]; then
        REPLY=${REPLY#git@}
        REPLY=${REPLY:s/\:/\/}
      fi
      if [[ $style == short ]]; then
        REPLY=${REPLY#*/}
      fi
      ;;
  esac
  REPLY=$ANTIDOTE_HOME/$REPLY
}

bundle_dir() {
  # Determine the bundle directory based on the configured path-style:
  #   full (default) : $ANTIDOTE_HOME/github.com/owner/repo
  #   short          : $ANTIDOTE_HOME/owner/repo
  #   escaped        : $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-owner-SLASH-repo
  #
  # If a clone already exists under a different path-style, return it rather
  # than computing a new path. No side effects — use bundle_dir_cleanup to
  # remove legacy duplicates.
  local bundle=$1
  local url preferred style dir found
  local -a other_styles=(full short escaped)
  bundle_type "$bundle"

  if [[ "$REPLY" == (repo|url|ssh_url) ]] && [[ ! -e "$bundle" ]]; then
    tourl $bundle; url=${REPLY%.git}
    __bundle_dir_by_style "$url"; preferred=$REPLY

    if [[ -d "$preferred" ]]; then
      REPLY=$preferred
    else
      # Check other path-styles for existing clones.
      other_styles=( ${other_styles:#$ANTIDOTE_PATH_STYLE} )
      for style in $other_styles; do
        __bundle_dir_by_style "$url" "$style"; dir=$REPLY
        if [[ -d "$dir" ]]; then
          found=$dir
          break
        fi
      done
      REPLY=${found:-$preferred}
    fi
  elif [[ -f "$bundle" ]]; then
    REPLY=${bundle:A:h}
  else
    REPLY=${bundle}
  fi
}

### Remove legacy path-style duplicates for a bundle.
#
# If the preferred path exists, remove any clones under other path-styles.
# Called during bundling to clean up after a path-style migration.
#
bundle_dir_cleanup() {
  local bundle=$1
  local url preferred style dir
  local -a other_styles=(full short escaped)
  bundle_type "$bundle"

  if [[ "$REPLY" == (repo|url|ssh_url) ]] && [[ ! -e "$bundle" ]]; then
    tourl $bundle; url=${REPLY%.git}
    __bundle_dir_by_style "$url"; preferred=$REPLY

    # Only clean up if the preferred path exists.
    [[ -d "$preferred" ]] || return 0

    other_styles=( ${other_styles:#$ANTIDOTE_PATH_STYLE} )
    for style in $other_styles; do
      __bundle_dir_by_style "$url" "$style"; dir=$REPLY
      [[ -d "$dir" ]] && del "$dir"
    done
  fi
}

### Check for conflicting pin/branch annotations on the same repo.
#
# Reads raw bundle text from stdin, parses it via bundle_parser, and fails
# if the same repo directory appears with different pin or branch values.
#
bundle_check_conflicts() {
  local parsed_line key dir val prev lookup
  local -a parsed_bundles
  local -A b seen_repo seen

  parsed_bundles=("${(@f)$(bundle_parser)}")
  for parsed_line in $parsed_bundles; do
    b=("${(@Q)${(z)parsed_line}}")
    dir="${b[__dir__]}"
    [[ -n "$dir" ]] || continue

    for key in pin branch; do
      val="${b[$key]}"
      lookup="${dir}:${key}"
      prev="${seen[$lookup]}"

      if [[ -n "${seen_repo[$dir]}" ]]; then
        # One entry has the annotation and the other doesn't
        if [[ -n "$val" && -z "$prev" ]] || [[ -z "$val" && -n "$prev" ]]; then
          warn "antidote: error: inconsistent $key for '${b[__bundle__]}': some entries have ${key}:${val:-$prev}, others do not"
          return 1
        fi
        # Both have it but they disagree
        if [[ -n "$val" ]] && [[ "$prev" != "$val" ]]; then
          warn "antidote: error: conflicting $key for '${b[__bundle__]}': ${key}:${val} vs ${key}:${prev}"
          return 1
        fi
      fi

      [[ -n "$val" ]] && seen[$lookup]="$val"
    done

    seen_repo[$dir]=1
  done
}

bundle_scripter() {
  local parsed_line skip_load_defer
  local key val
  local -a parsed_lines
  local -A bundle

  skip_load_defer=0

  # Parse all bundles at once (single bundle_parser call)
  parsed_lines=("${(@f)$(collect_input "$@" | bundle_parser)}")
  if ! (( $#parsed_lines )); then
    die "antidote: error: bundle argument expected"
  fi

  # Loop through parsed bundles
  for parsed_line in $parsed_lines; do
    [[ -z "$parsed_line" ]] && continue
    bundle=("${(@Q)${(z)parsed_line}}")
    if [[ -n "${bundle[__error__]}" ]]; then
      warn "antidote: Bundle parser error on line ${bundle[__lineno__]}: '${bundle[__bundle__]}'"
      return 1
    fi

    # alias for convenience
    bundle[name]=$bundle[__bundle__]

    # move flags to front and call zsh_script
    print -rn -- "zsh_script"
    for key in ${(ok)bundle}; do
      [[ "$key" != name ]] && [[ "$key" != '_'* ]] || continue
      val="${bundle[$key]}"
      if [[ "$val" == "${(q)val}" ]]; then
        printf ' --%s %s' $key $val
      else
        printf ' --%s %s' $key ${(qqq)val}
      fi
    done

    # Add flag for first defer
    if [[ "${bundle[kind]}" == "defer" ]]; then
      if [[ "$skip_load_defer" -eq 0 ]]; then
        skip_load_defer=1
      else
        printf ' --skip-load-defer'
      fi
    fi

    # Escape leading '$' variables
    if [[ "${bundle[__bundle__]}" == '$'* ]]; then
      printf ' \$%s\n' "${bundle[name]#\$}"
    else
      printf ' %s\n' "${bundle[name]}"
    fi
  done
}

### Wrap bundle_scripter output for parallel execution.
#
# Converts sequential zsh_script calls into parallel ones that write
# to numbered temp files, then concatenates results in order.
#
bundle_scripter_parallel() {
  local line par_dir
  local n=0
  par_dir=$(maketmp -d -s par)

  while IFS= read -r line; do
    (( n++ ))
    printf '%s > "%s"/%03d &\n' "$line" "$par_dir" $n
  done < <(bundle_scripter "$@")

  if (( n > 0 )); then
    printf 'wait\n'
    printf 'cat "%s"/*\n' "$par_dir"
    printf 'rm -rf "%s"\n' "$par_dir"
  fi
}

### Generate the Zsh script to load a plugin.
#
# usage: zsh_script [-h|--help] [-k|--kind <kind>] [-p|--path <path>]
#               [-c|--conditional <func>] [-b|--branch <branch>]
#               [--pre <func>] [--post <func>] [--skip-load-defer]
#               [-a|--autoload <path>] <bundle>
# <kind>   : zsh,path,fpath,defer,clone,autoload
# <path>   : Relative path from the bundle root
# <branch> : The git branch
# <bundle> : A bundle can be a directory, a zsh script, or a git repo
#
zsh_script() {
  local MATCH MBEGIN MEND
  local -a match mbegin mend
  local -a o_help o_kind o_path o_branch o_pin o_cond o_autoload o_pre o_post o_fpath_rule o_skip_load_defer
  local repat bundle bname bundle_path btype dopts zsh_defer zsh_defer_bundle giturl current_pin pin_sha unpin_branch
  local source_cmd print_bundle_path initfile print_initfile fpath_script
  local -a supported_kind_vals supported_fpath_rules script

  zparseopts ${ZPARSEOPTS} -- \
    h=o_help       -help=h            \
    a:=o_autoload  -autoload:=a       \
    b:=o_branch    -branch:=b         \
    k:=o_kind      -kind:=k           \
                   -pin:=o_pin        \
    p:=o_path      -path:=p           \
                   -pre:=o_pre        \
                   -post:=o_post      \
                   -fpath-rule:=o_fpath_rule \
                   -skip-load-defer=o_skip_load_defer \
    c:=o_cond      -conditional:=c    ||
    return 1

  # set defaults
  (( $#o_kind )) || o_kind=(--kind zsh)
  (( $#o_fpath_rule )) || o_fpath_rule=($ANTIDOTE_FPATH_RULE)

  # strip '=' or ':' from beginning of arg values
  repat='^[=:]?(.+)$'
  [[ $o_kind[-1] =~ $repat ]] && o_kind[-1]=$match
  [[ $o_autoload[-1] =~ $repat ]] && o_autoload[-1]=$match
  [[ $o_path[-1] =~ $repat ]] && o_path[-1]=$match
  [[ $o_cond[-1] =~ $repat ]] && o_cond[-1]=$match
  [[ $o_branch[-1] =~ $repat ]] && o_branch[-1]=$match
  [[ $o_pin[-1] =~ $repat ]] && o_pin[-1]=$match
  [[ $o_pre[-1] =~ $repat ]] && o_pre[-1]=$match
  [[ $o_post[-1] =~ $repat ]] && o_post[-1]=$match
  [[ $o_fpath_rule[-1] =~ $repat ]] && o_fpath_rule[-1]=$match

  supported_kind_vals=(autoload clone defer fpath path zsh)
  if (( $#o_kind )) && ! (( $supported_kind_vals[(Ie)$o_kind[-1]] )); then
    warn "antidote: error: unexpected kind value: '$o_kind[-1]'"
    return 1
  fi

  supported_fpath_rules=(append prepend)
  if ! (( $supported_fpath_rules[(Ie)$o_fpath_rule[-1]] )); then
    warn "antidote: error: unexpected fpath rule: '$o_fpath_rule[-1]'"
    return 1
  fi

  bundle=$1
  if [[ -z "$bundle" ]]; then
    warn "antidote: error: bundle argument expected"
    return 1
  fi

  # Compute bundle type and name once
  bundle_type $bundle; btype=$REPLY
  bundle_name $bundle; bname=$REPLY

  # replace ~/ with $HOME/
  if [[ "$bundle" == '~/'* ]]; then
    bundle=${~bundle}
  fi

  # set the path to the bundle (repo or local)
  if [[ -e "$bundle" ]]; then
    bundle_path=$bundle
  elif [[ "$btype" == (repo|url|ssh_url) ]]; then
    bundle_dir $bundle; bundle_path=$REPLY
    # Clean up legacy path-style duplicates.
    bundle_dir_cleanup $bundle
  else
    bundle_path=$bundle
  fi
  if (( $#o_pin )) && [[ "$btype" == (repo|url|ssh_url) ]]; then
    pin_sha="$o_pin[-1]"
    if (( $#pin_sha != 40 )) || [[ "$pin_sha" != [0-9a-f](#c40) ]]; then
      warn "antidote: error: pin requires a full 40-character commit SHA, got '$pin_sha'"
      return 1
    fi
  fi

  # handle cloning repo bundles
  if [[ "$btype" == (repo|url|ssh_url) ]] && [[ ! -e "$bundle_path" ]]; then
    tourl $bundle; giturl=$REPLY
    warn "# antidote cloning $bname..."
    if (( $#o_pin )); then
      git_clone $bundle_path $giturl || return 1
      if ! git_checkout_pin "$bundle_path" "$pin_sha" "$bname"; then
        del "$bundle_path"
        return 1
      fi
      [[ "$ANTIDOTE_EPHEMERAL_PIN" != true ]] && git_config_set "$bundle_path" antidote.pin $pin_sha
    else
      git_clone $bundle_path $o_branch $giturl || return 1
    fi
  fi

  # Sync pin state for existing repos
  if [[ "$btype" == (repo|url|ssh_url) ]] && [[ -e "$bundle_path" ]]; then
    if (( $#o_pin )); then
      current_pin=$(git_config_get "$bundle_path" antidote.pin)
      if [[ "$current_pin" != "$pin_sha" ]] || [[ "$(git_sha "$bundle_path")" != "$pin_sha" ]]; then
        if ! git_checkout_pin "$bundle_path" "$pin_sha" "$bname"; then
          return 1
        fi
        [[ "$ANTIDOTE_EPHEMERAL_PIN" != true ]] && git_config_set "$bundle_path" antidote.pin $pin_sha
      fi
    else
      # Pin removed — clear config and return to a branch so update can pull
      if [[ -n "$(git_config_get "$bundle_path" antidote.pin)" ]]; then
        git_config_unset "$bundle_path" antidote.pin
        unpin_branch="${o_branch[-1]}"
        if [[ -z "$unpin_branch" ]]; then
          unpin_branch=$(git -C "$bundle_path" rev-parse --abbrev-ref origin/HEAD 2>/dev/null)
          unpin_branch=${unpin_branch#origin/}
        fi
        [[ -n "$unpin_branch" ]] && git -C "$bundle_path" checkout --quiet "$unpin_branch" 2>/dev/null
      fi
    fi
  fi

  # if we only needed to clone the bundle, compile and we're done
  if [[ "$o_kind[-1]" == "clone" ]]; then
    if zstyle -t ":antidote:bundle:$bundle" zcompile; then
      bundle_zcompile $bundle_path
    fi
    return
  fi

  # add path to bundle
  [[ -n "$o_path[-1]" ]] && bundle_path+="/$o_path[-1]"

  # handle defer pre-reqs first
  dopts=
  zsh_defer='zsh-defer'
  zstyle -s ":antidote:bundle:${bundle}" defer-options 'dopts'
  [[ -n "$dopts" ]] && zsh_defer="zsh-defer $dopts"

  # generate the script
  script=()

  # add pre-load function
  (( $#o_pre )) && script+=("$o_pre[-1]")

  # handle defers
  source_cmd="source"
  zsh_defer_bundle=$ANTIDOTE_DEFER_BUNDLE
  if [[ "$o_kind[-1]" == "defer" ]]; then
    source_cmd="${zsh_defer} source"
    if ! (( $#o_skip_load_defer )); then
      script+=(
        'if ! (( $+functions[zsh-defer] )); then'
        "$(zsh_script $zsh_defer_bundle | indent)"
        'fi'
      )
    fi
  fi

  # Let's make the path a little nicer to deal with
  print_path "$bundle_path"; print_bundle_path=$REPLY

  # handle autoloading before sourcing
  if (( $#o_autoload )); then
    if [[ "$o_fpath_rule[-1]" == prepend ]]; then
      script+=("fpath=( \"${print_bundle_path}/${o_autoload[-1]}\" \$fpath )")
      script+=("builtin autoload -Uz \$fpath[1]/*(N.:t)")
    else
      script+=("fpath+=( \"${print_bundle_path}/${o_autoload[-1]}\" )")
      script+=("builtin autoload -Uz \$fpath[-1]/*(N.:t)")
    fi
  fi

  # generate load script — recheck type since path may have been appended
  if [[ "$btype" != file ]] && [[ -f "$bundle_path" ]]; then
    btype=file
  fi
  if [[ "$o_fpath_rule[-1]" == prepend ]]; then
    fpath_script="fpath=( \"$print_bundle_path\" \$fpath )"
  else
    fpath_script="fpath+=( \"$print_bundle_path\" )"
  fi

  if [[ "$o_kind[-1]" == fpath ]]; then
    # fpath
    script+="$fpath_script"
  elif [[ "$o_kind[-1]" == path ]]; then
    # path
    script+="export PATH=\"$print_bundle_path:\$PATH\""
  elif [[ "$o_kind[-1]" == autoload ]]; then
    # autoload
    script+=("$fpath_script")
    if [[ "$o_fpath_rule[-1]" == prepend ]]; then
      script+=("builtin autoload -Uz \$fpath[1]/*(N.:t)")
    else
      script+=("builtin autoload -Uz \$fpath[-1]/*(N.:t)")
    fi
  else
    if zstyle -t ":antidote:bundle:$bundle" zcompile; then
      bundle_zcompile $bundle_path
    fi
    if [[ $btype == file ]]; then
      script+="$source_cmd \"$print_bundle_path\""
    else
      # directory/default
      initfiles $bundle_path
      # if no init file was found, assume the default
      if [[ $#reply -eq 0 ]]; then
        if (( $#o_path )); then
          reply=($bundle_path/${bundle_path:t}.plugin.zsh)
        else
          reply=($bundle_path/${bname:t}.plugin.zsh)
        fi
      fi
      script+="$fpath_script"
      for initfile in $reply; do
        print_path "$initfile"; print_initfile=$REPLY
        script+="$source_cmd \"$print_initfile\""
      done
    fi
  fi

  # add post-load function
  if (( $#o_post )); then
    if [[ "$o_kind[-1]" == "defer" ]]; then
      script+=("${zsh_defer} $o_post[-1]")
    else
      script+=("$o_post[-1]")
    fi
  fi

  # wrap conditional
  if [[ -n "$o_cond[-1]" ]]; then
    print "if $o_cond[-1]; then"
    # (F)join + (@f)split flattens multiline elements so each line gets indented
    printf "  %s\n" "${(@f)${(F)script}}"
    print "fi"
  else
    printf "%s\n" $script
  fi
}

### Clone bundle(s) and generate the static load script.
#
# usage: antidote bundle [-h|--help] <bundle>...
#
antidote_bundle() {
  local o_help bundle_output
  local -a bundles zcompile_script

  zparseopts ${ZPARSEOPTS} -- h=o_help -help=h || return 1

  if (( $#o_help )); then
    usage
    return
  fi

  # handle bundles as newline delimited arg strings,
  # or as <redirected or piped| input
  bundles=("${(@f)$(collect_input "$@")}")
  (( $#bundles )) || return 1

  # validate bundles for conflicting pin/branch before doing any work
  printf '%s\n' $bundles | bundle_check_conflicts || return 1

  # output static file compilation
  zcompile_script=(
    "function {"
    '  0=${(%):-%x}'
    '  local staticfile=${0:A}'
    '  [[ -e ${staticfile} ]] || return 1'
    '  if [[ ! -s ${staticfile}.zwc || ${staticfile} -nt ${staticfile}.zwc ]]; then'
    '    builtin autoload -Uz zrecompile'
    '    zrecompile -pq ${staticfile}'
    '  fi'
    '}'
  )
  # antidote_script also clones, but this way we can do it all at once in parallel!
  if (( $#bundles > 1 )); then
    source <(printf '%s\n' $bundles | bundle_parser | bulk_clone)
  fi

  # generate bundle script, capturing output so zcompile header is only
  # emitted after all bundles succeed (no output on clone failure)
  bundle_output=$(source <(printf '%s\n' $bundles | bundle_scripter_parallel)) || return $?

  # output static file compilation
  if zstyle -t ':antidote:static' zcompile; then
    printf '%s\n' $zcompile_script
  fi
  [[ -n "$bundle_output" ]] && printf '%s\n' "$bundle_output"
}

### Clone a new bundle and add it to your plugins file.
#
# usage: antidote install [-h|--help] [-k|--kind <kind>] [-p|--path <path>]
#                         [-c|--conditional <func>] [-b|--branch <branch>]
#                         [--pre <func>] [--post <func>]
#                         [-a|--autoload <path>] <bundle> [<bundlefile>]
#
antidote_install() {
  local arg bundle bundlefile bundledir bundlestr
  local -a annotations
  local -A flag_to_annotation

  flag_to_annotation=(
    '-a' autoload
    '-b' branch
    '-c' conditional
    '-h' help
    '-k' kind
    '-p' path
  )
  annotations=()

  while (( $# )); do
    arg="$1"
    case "$arg" in
      -h|--help)
        usage
        return
      ;;
      --)   shift; break  ;;
      --*)  annotations+=( "${arg#*--}:$2" ); shift  ;;
      -*)   annotations+=( $flag_to_annotation[$arg]:$2 ); shift  ;;
      *)    break  ;;
    esac
    shift
  done

  if [[ $# -eq 0 ]]; then
    die "antidote: error: required argument 'bundle' not provided, try --help"
  fi

  bundle=$1
  bundlefile=$2
  if [[ -z "$bundlefile" ]]; then
    zstyle -s ':antidote:bundle' file 'bundlefile' ||
      bundlefile=${ZDOTDIR:-$HOME}/.zsh_plugins.txt
  fi

  bundle_dir $bundle; bundledir=$REPLY
  if [[ -d "$bundledir" ]]; then
    die "antidote: error: $bundle already installed: $bundledir"
  fi

  # use antidote bundle to clone our bundle
  bundlestr=$bundle
  (( $#annotations )) && bundlestr+=" $annotations"
  if ! antidote_bundle "$bundlestr" >/dev/null; then
    die "antidote: unable to install bundle '$bundle'."
  else
    say "Adding bundle to '$bundlefile':"
    say $bundlestr | tee -a $bundlefile
  fi
}

### Remove a cloned bundle.
#
# usage: antidote purge [-h|--help] <bundle>
#        antidote purge [-a|--all]
#
antidote_purge() {
  local o_help o_all REPLY i line
  local bundlefile bundle bundledir dtstmp p
  local -a lines

  zparseopts ${ZPARSEOPTS} -- \
    h=o_help -help=h \
    a=o_all  -all=a  ||
    return 1

  if (( $#o_help )); then
    usage
    return
  fi

  if [[ $# -eq 0 ]] && ! (( $#o_all )); then
    die "antidote: error: required argument 'bundle' not provided, try --help"
  fi

  zstyle -s ':antidote:bundle' file 'bundlefile' ||
    bundlefile=${ZDOTDIR:-$HOME}/.zsh_plugins.txt

  if (( $#o_all )); then
    # last chance to save the user from themselves
    zstyle -s ':antidote:test:purge' answer 'REPLY' || {
      read -q "REPLY?You are about to permanently remove '$ANTIDOTE_HOME' and all its contents!${NL}Are you sure [Y/n]? "
      print
    }
    [[ ${REPLY:u} == "Y" ]] || return 1

    # If $ANTIDOTE_HOME is a symlink, we need to remove contents under it before removing it
    if [[ -L "$ANTIDOTE_HOME" ]]; then
      () {
        setopt localoptions glob_dots
        for p in "$ANTIDOTE_HOME"/*(N); do
          del "$p"
        done
      }
    fi
    del "$ANTIDOTE_HOME"

    if [[ -e "${bundlefile:r}.zsh" ]]; then
      zstyle -s ':antidote:test:purge' answer 'REPLY' || {
        read -q "REPLY?You are about to remove '${bundlefile:t:r}.zsh'"$'\n'"Are you sure [Y/n]? "
        print
      }
      if [[ ${REPLY:u} == "Y" ]]; then
        dtstmp=$(date -u '+%Y%m%d_%H%M%S')
        command mv -f "${bundlefile:r}.zsh" "${bundlefile:r}.${dtstmp}.bak"
        say "'"${bundlefile:r}.zsh"' backed up to '${bundlefile:t:r}.${dtstmp}.bak'"
      fi
    fi
    say "Antidote purge complete. Be sure to start a new Zsh session."

  else
    bundle=$1
    # make sure the user isn't trying to do something out-of-bounds
    if [[ -e "$bundle" ]]; then
      ERR=2 die "antidote: error: '$bundle' is not a repo and cannot be removed by antidote."
    fi

    bundle_dir $bundle; bundledir=$REPLY
    if [[ ! -d "$bundledir" ]]; then
      die "antidote: error: $bundle does not exist at the expected location: $bundledir"
    fi

    # remove
    del "$bundledir"
    say "Removed '$bundle'."

    # attempt to comment out the bundle from .zsh_plugins.txt
    if [[ -e "$bundlefile" ]]; then
      lines=( "${(@f)"$(<$bundlefile)"}" )
      for (( i=1; i<=$#lines; i++ )); do
        [[ "${lines[$i]}" =~ "^[[:blank:]]*${bundle}" ]] && lines[$i]="# $lines[$i]"
      done
      printf '%s\n' "${lines[@]}" > "$bundlefile"
      say "Bundle '$bundle' was commented out in '$bundlefile'."
    fi
  fi
}

### Update antidote's cloned bundles.
#
# usage: antidote update [-h|--help] [-n|--dry-run]
#
antidote_update() {
  local o_help o_dry_run
  local tmpfile tmpdir bundledir url repo filename repo_id pin_ref
  local line loadable_check_path

  zparseopts ${ZPARSEOPTS} -- \
    h=o_help    -help=h    \
    n=o_dry_run -dry-run=n ||
    return 1

  if (( $#o_help )); then
    usage
    return
  fi

  if (( $#o_dry_run )); then
    say "Checking for bundle updates (dry run)..."
  else
    say "Updating bundles..."

    # remove zcompiled files
    del $ANTIDOTE_HOME/**/*.zwc(N)

    # remove check file
    loadable_check_path="${ANTIDOTE_HOME}/.antidote.load"
    [[ -r "$loadable_check_path" ]] && del "$loadable_check_path"
  fi

  # Setup temporary directory
  tmpdir=$(maketmp -d -s update)

  # Set trap to ensure cleanup on exit, interrupt, etc.
  # (EXIT is special, 2=INT, 15=TERM, 1=HUP)
  trap '[[ -d "$tmpdir" ]] && del "$tmpdir"' EXIT 2 15 1

  # update all bundles
  for bundledir in $(antidote_list --dirs); do
    url=$(git_url "$bundledir")
    short_repo_name "$url"; repo=$REPLY

    # Skip pinned bundles
    pin_ref=$(git_config_get "$bundledir" antidote.pin)
    if [[ -n "$pin_ref" ]]; then
      say "${C_BLUE}antidote:${C_NORMAL} skipping update for pinned bundle: $repo (at ${C_GREEN}${pin_ref[1,7]}...${C_NORMAL})"
      continue
    fi

    say "${C_BLUE}antidote:${C_NORMAL} checking for updates: $repo"

    () {
      local repo_id tmpfile oldsha newsha
      local GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM

      repo_id="${repo//\//-SLASH-}"
      tmpfile="${tmpdir}/${repo_id}.output"
      oldsha=$(git_sha "$1")

      # Isolate git from user config
      GIT_CONFIG_GLOBAL=/dev/null
      GIT_CONFIG_SYSTEM=/dev/null

      # Unshallow the repo if needed
      if git_is_shallow "$1"; then
        git_fetch "$1" --unshallow
      else
        git_fetch "$1"
      fi

      if (( $#o_dry_run )); then
        # Compare local HEAD against fetched remote HEAD
        newsha=$(git -C "$1" rev-parse FETCH_HEAD 2>/dev/null) || newsha=$oldsha
      else
        git_pull "$1"
        git_submodule_sync "$1"
        git_submodule_update "$1"
        newsha=$(git_sha "$1")
      fi

      # Capture all output to temporary file
      {
        if [[ $oldsha != $newsha ]]; then
          if (( $#o_dry_run )); then
            say "${C_YELLOW}antidote:${C_NORMAL} update available: $2 ${C_GREEN}${oldsha[1,7]}${C_NORMAL} -> ${C_GREEN}${newsha[1,7]}${C_NORMAL}"
          else
            say "${C_GREEN}antidote:${C_NORMAL} updated: $2 ${C_GREEN}${oldsha[1,7]}${C_NORMAL} -> ${C_GREEN}${newsha[1,7]}${C_NORMAL}"
          fi
          git_log_oneline "$1" "$oldsha" "$newsha"
        fi

        # recompile bundles
        if ! (( $#o_dry_run )); then
          if zstyle -t ":antidote:bundle:$repo" zcompile; then
            bundle_zcompile $bundledir
          fi
        fi
      } > "$tmpfile" 2>&1
    } "$bundledir" "$repo" &
  done

  say "Waiting for bundle updates to complete..."
  say ""
  wait

  # Display all output in sequence
  for tmpfile in "$tmpdir"/*.output(N); do
    if [[ -s "$tmpfile" ]]; then
      filename=${tmpfile:t}
      repo_id=${filename%.output}
      repo_id=${repo_id//-SLASH-/\/}

      say "${C_BLUE}Bundle ${repo_id} update check complete.${C_NORMAL}"

      # Colorize the SHA in each line
      while IFS= read -r line; do
        if [[ -n "$line" ]] && [[ "$line" == [[:alnum:]]* ]]; then
          say "${C_YELLOW}${line%% *}${C_NORMAL} ${line#* }"
        else
          say "$line"
        fi
      done < "$tmpfile"
      say ""
    fi
  done

  # cleanup temp dir
  [[ -d "$tmpdir" ]] && del "$tmpdir"
  if (( $#o_dry_run )); then
    say "${C_GREEN}Dry run complete. No changes were made.${C_NORMAL}"
  else
    say "${C_GREEN}Bundle updates complete.${C_NORMAL}"
    [[ "$ANTIDOTE_AUTOSNAPSHOT" == true ]] && snapshot_save >/dev/null
  fi
  say ""
}

### Print where antidote is cloning bundles.
#
# usage: antidote home [-h|--help]
#
# Can be overridden by setting `$ANTIDOTE_HOME`.
#
antidote_home() { say "$ANTIDOTE_HOME" }

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
  say "      source <( ANTIDOTE_DYNAMIC=true antidote-dispatch \$@ ) || ANTIDOTE_DYNAMIC=true antidote-dispatch \$@"
  say "      ;;"
  say "    *)"
  say "      ANTIDOTE_DYNAMIC=true antidote-dispatch \$@"
  say "      ;;"
  say "  esac"
  say "}"
}

### List cloned bundles.
#
# usage: antidote list [-h|--help] [-l|--long] [-j|--jsonl] [-d|--dirs] [-u|--url]
#
antidote_list() {
  local o_help o_jsonl o_long o_dirs o_url
  zparseopts ${ZPARSEOPTS} -- \
    h=o_help  -help=h   \
    j=o_jsonl -jsonl=j  \
    l=o_long  -long=l   \
    d=o_dirs  -dirs=d   \
    u=o_url   -url=u    ||
    return 1

  if (( $# )); then
    die "antidote: error: unexpected $1, try --help"
  fi

  local bundledir url repo sha pin_ref
  local -a output=()
  local -a bundles=()

  bundles=(${(f)"$(find_bundles)"})

  if (( ${#bundles[@]} == 0 )); then
    print_path $ANTIDOTE_HOME
    warn "antidote: list: no bundles found in '$REPLY'"
    return 0
  fi

  for bundledir in "${bundles[@]}"; do
    url=$(git_url "$bundledir") || continue
    repo=${url%.git}
    repo=${repo#https://${ANTIDOTE_GIT_SITE}/}

    if (( $#o_jsonl )); then
      sha=$(git_sha "$bundledir")
      pin_ref=$(git_config_get "$bundledir" antidote.pin)
      if [[ -n "$pin_ref" ]]; then
        printf '{"url":"%s","repo":"%s","path":"%s","sha":"%s","pin":"%s"}\n' \
          "$url" "$repo" "$bundledir" "$sha" "$pin_ref"
      else
        printf '{"url":"%s","repo":"%s","path":"%s","sha":"%s"}\n' \
          "$url" "$repo" "$bundledir" "$sha"
      fi
      continue
    elif (( $#o_long )); then
      sha=$(git_sha "$bundledir")
      pin_ref=$(git_config_get "$bundledir" antidote.pin)
      printf 'Repo:   %s\n' "$repo"
      print_path "$bundledir"; printf 'Path:   %s\n' "$REPLY"
      printf 'URL:    %s\n' "$url"
      printf 'SHA:    %s\n' "$sha"
      if [[ -n "$pin_ref" ]]; then
        printf 'Pinned: %s\n' "$pin_ref"
      fi
      print
      continue
    elif (( $#o_dirs )); then
      output+=("$bundledir")
    elif (( $#o_url )); then
      output+=("$url")
    else
      output+=("${bundledir}${TAB}${url}")
    fi
  done
  if (( $#output )); then
    printf '%s\n' ${(o)output}
  fi
}

### Print the clone path of one or more bundles.
antidote_path() {
  local bundle bundledir
  local -a results=()
  local -a bundles=("${(@f)$(collect_input "$@")}")
  if (( $#bundles == 0 )); then
    die "antidote: error: required argument 'bundle' not provided, try --help"
  fi
  for bundle in $bundles; do
    # Allow piping from `antidote list` default output: <path><TAB><url>
    bundle=${bundle%%${TAB}*}
    if [[ $bundle == '$'* ]]; then
      bundle="${(e)bundle}"
    fi
    bundle_dir $bundle; bundledir=$REPLY
    if [[ ! -d $bundledir ]]; then
      die "antidote: error: $bundle does not exist in cloned paths"
    else
      results+=("$bundledir")
    fi
  done
  say $results
}

### Save, restore, or list snapshots of cloned bundle state.
#
# usage: antidote snapshot [save|restore|list] [<file>]
#
antidote_snapshot() {
  local o_help subcmd
  zparseopts ${ZPARSEOPTS} -- h=o_help -help=h || return 1

  if (( $#o_help )); then
    say "usage: antidote snapshot [save|restore|remove|list] [<file>]"
    return
  fi

  subcmd=${1:-list}; shift 2>/dev/null

  case "$subcmd" in
    save)    snapshot_save "$@"    ;;
    restore) snapshot_restore "$@" ;;
    remove)  snapshot_remove "$@"  ;;
    list)    snapshot_list         ;;
    *)       die "antidote: snapshot: unknown subcommand '$subcmd'" ;;
  esac
}

### Write a snapshot of all cloned bundles to a timestamped file.
snapshot_save() {
  local bundledir url sha repo snapshot_file epoch
  local -a bundles bundle_lines

  [[ "$ANTIDOTE_DYNAMIC" == true ]] && return 0

  [[ -d "$ANTIDOTE_SNAPSHOT_DIR" ]] || mkdir -p "$ANTIDOTE_SNAPSHOT_DIR"

  epoch=$EPOCHSECONDS
  snapshot_file=${1:-$ANTIDOTE_SNAPSHOT_DIR/snapshot-$(TZ=UTC strftime '%Y%m%d-%H%M%SZ' $epoch).txt}

  bundles=(${(f)"$(find_bundles)"})

  for bundledir in "${bundles[@]}"; do
    url=$(git_url "$bundledir") || continue
    sha=$(git_sha "$bundledir")

    # Derive short name (user/repo) when possible
    repo=${url%.git}
    repo=${repo#https://${ANTIDOTE_GIT_SITE}/}

    bundle_lines+=("$repo kind:clone pin:$sha")
  done

  {
    print "# antidote snapshot"
    print "# version: $ANTIDOTE_VERSION"
    print "# date: $(TZ=UTC strftime '%Y-%m-%dT%H:%M:%SZ' $epoch)"
    printf '%s\n' ${(o)bundle_lines}
  } >| "$snapshot_file"
  say "Snapshot saved: $snapshot_file"

  # Prune old snapshots
  snapshot_prune
}

### Prune snapshots beyond the configured max.
snapshot_prune() {
  local -a snapshots to_remove
  snapshots=($ANTIDOTE_SNAPSHOT_DIR/snapshot-*.txt(N))
  if (( $#snapshots > ANTIDOTE_SNAPSHOT_MAX )); then
    to_remove=(${(o)snapshots[1,$(( $#snapshots - ANTIDOTE_SNAPSHOT_MAX ))]})
    del $to_remove
  fi
}

### Interactive fzf snapshot picker. Prints selected file path(s) to stdout.
# Usage: snapshot_pick "prompt" [--multi]
snapshot_pick() {
  setopt localoptions pipefail
  local prompt="$1" snap date_line epoch preview_cmd
  local -a snapshots labels fzf_opts fzf_cmd

  snapshots=($ANTIDOTE_SNAPSHOT_DIR/snapshot-*.txt(NOn))
  if (( $#snapshots == 0 )); then
    warn "antidote: snapshot: no snapshots found"
    return 1
  fi

  fzf_cmd=(${(z)ANTIDOTE_FZF_CMD})
  if (( ${#fzf_cmd} == 0 )) || ! command -v -- "${fzf_cmd[1]}" >/dev/null 2>&1; then
    warn "antidote: snapshot: no snapshot file specified (use 'antidote snapshot list' to see available snapshots)"
    return 1
  fi

  preview_cmd='echo {2}; echo; tail -n +4 {2}'
  if [[ "$ANTIDOTE_COLOR" == true ]]; then
    preview_cmd='
  printf "\033[1;4m%s\033[0m\n\n" {2}
  tail -n +4 {2} |
  awk "{
    colors[0] = \"\033[34m\"; # blue
    colors[1] = \"\033[32m\"; # green
    colors[2] = \"\033[33m\"; # yellow

    # first field = repo (no key)
    printf \"%s%s\033[0m \", colors[0], \$1;

    # remaining fields = key:value
    for (i=2; i<=NF; i++) {
      split(\$i, kv, \":\");
      key = kv[1];
      val = kv[2];

      color = colors[(i-1)%3];
      printf \"%s:%s%s\033[0m \", key, color, val;
    }

    printf \"\n\";
  }"
'
  fi

  for snap in $snapshots; do
    date_line=${${(f)"$(<$snap)"}[3]#\# date: }
    if TZ=UTC strftime -r -s epoch '%Y-%m-%dT%H:%M:%SZ' "$date_line" 2>/dev/null; then
      date_line=$(strftime "$ANTIDOTE_SNAPSHOT_DATEFMT" $epoch)
    fi
    labels+=("$date_line	$snap")
  done

  fzf_opts=(--no-sort ${C_NORMAL:+--ansi} --with-nth=1 --delimiter=$'\t'
    --prompt="$prompt" --preview="$preview_cmd" --preview-window=right:75%)
  if [[ "$2" == --multi ]]; then
    fzf_opts+=(--multi --marker='* ' --color='marker:red')
  fi

  printf '%s\n' $labels | "${fzf_cmd[@]}" $fzf_opts | cut -f2 \
    || { warn "antidote: snapshot: no snapshot selected"; return 1; }
}

### Restore bundles from a snapshot file.
snapshot_restore() {
  local snapshot_file="$1"
  local line bundle pin

  if [[ -z "$snapshot_file" ]]; then
    snapshot_file=$(snapshot_pick "Select snapshot to restore: ") \
      || return 1
  fi

  if [[ ! -r "$snapshot_file" ]]; then
    die "antidote: snapshot: file not found '$snapshot_file'"
  fi

  say "Restoring from snapshot: $snapshot_file"
  while IFS= read -r line; do
    [[ "$line" == \#* || -z "$line" ]] && continue
    bundle=${line%% *}
    pin=${line##*pin:}
    pin=${pin%% *}
    say "${C_BLUE}antidote:${C_NORMAL} restoring $bundle (${C_GREEN}${pin[1,7]}...${C_NORMAL})"
    ANTIDOTE_EPHEMERAL_PIN=true antidote_bundle "$line" &>/dev/null &
  done <"$snapshot_file"
  wait

  say "${C_GREEN}Restore complete.${C_NORMAL}"
}

### List available snapshots.
snapshot_list() {
  local -a snapshots
  snapshots=($ANTIDOTE_SNAPSHOT_DIR/snapshot-*.txt(N))
  if (( $#snapshots == 0 )); then
    say "No snapshots found."
    return
  fi
  printf '%s\n' ${(O)snapshots}
}

### Remove snapshots.
snapshot_remove() {
  local snap REPLY
  local -a selected

  if [[ -n "$1" ]]; then
    for snap in "$@"; do
      if [[ ! -r "$snap" ]]; then
        warn "antidote: snapshot: file not found '$snap'"
        continue
      fi
      del "$snap"
      say "Removed: $snap"
    done
    return
  fi

  selected=("${(@f)$(snapshot_pick "Select snapshot(s) to remove: " --multi)}") \
    || return 1

  say "Snapshots to remove:"
  for snap in $selected; do
    say "  $snap"
  done

  zstyle -s ':antidote:test:snapshot:remove' answer 'REPLY' || {
    read -q "REPLY?Are you sure you want to remove ${#selected} snapshot(s) [Y/n]? "
    print
  }
  if [[ ${REPLY:u} != "Y" ]]; then
    say "Cancelled."
    return 1
  fi

  for snap in $selected; do
    del "$snap"
    say "Removed: $snap"
  done
}

antidote() {
  local o_help o_version o_diagnostics
  zparseopts ${ZPARSEOPTS} -- \
    h=o_help          -help=h           \
    v=o_version       -version=v        \
    -diagnostics=o_diagnostics          ||
    return 1

  if (( ${#o_version} )); then
    version
    return 0
  fi

  if (( ${#o_diagnostics} )); then
    diagnostics
    return 0
  fi

  if (( ${#o_help} )) || [[ ${#} -eq 0 ]]; then
    usage
    return
  fi

  local cmd=$1; shift
  if [[ "$cmd" == __private__ ]]; then
    cmd="$1"
    shift
    REPLY=
    "${cmd}" "$@"
    local ret=$?
    case $cmd in
      tourl|bundle_type|short_repo_name|bundle_name|bundle_dir|__bundle_dir_by_style|print_path)
        say "$REPLY"
        ;;
      initfiles)
        (( $#reply )) && printf '%s\n' "${reply[@]}"
        ;;
    esac
    return $ret
  elif (( $+functions[antidote_${cmd}] )); then
    "antidote_${cmd}" "$@"
    return $?
  else
    die "antidote: command not found '${cmd}'"
  fi
}

# Initialize antidote global variables from zstyles and environment.
() {
  typeset -g ANTIDOTE_ZSH="$1"
  typeset -g ANTIDOTE_VERSION="2.0.7"
  typeset -g ANTIDOTE_TMPDIR=${ANTIDOTE_TMPDIR:-$TMPDIR}

  typeset -g ANTIDOTE_GIT_SITE ANTIDOTE_GIT_PROTOCOL ANTIDOTE_GIT_CMD ANTIDOTE_FZF_CMD ANTIDOTE_PATH_STYLE
  typeset -g ANTIDOTE_DEFER_BUNDLE ANTIDOTE_FPATH_RULE
  typeset -g ANTIDOTE_OSTYPE ANTIDOTE_LOCALAPPDATA
  typeset -g ANTIDOTE_VERSION_SHOW_SHA=false ANTIDOTE_GIT_AUTOSTASH=false
  zstyle -s ':antidote:bundle'       path-style   ANTIDOTE_PATH_STYLE   || ANTIDOTE_PATH_STYLE=full
  zstyle -s ':antidote:defer'        bundle       ANTIDOTE_DEFER_BUNDLE || ANTIDOTE_DEFER_BUNDLE=romkatv/zsh-defer
  zstyle -s ':antidote:fpath'        rule         ANTIDOTE_FPATH_RULE   || ANTIDOTE_FPATH_RULE=append
  zstyle -s ':antidote:fzf'          cmd          ANTIDOTE_FZF_CMD      || ANTIDOTE_FZF_CMD=fzf
  zstyle -s ':antidote:git'          cmd          ANTIDOTE_GIT_CMD      || ANTIDOTE_GIT_CMD=git
  zstyle -s ':antidote:git'          protocol     ANTIDOTE_GIT_PROTOCOL || ANTIDOTE_GIT_PROTOCOL=https
  zstyle -s ':antidote:git'          site         ANTIDOTE_GIT_SITE     || ANTIDOTE_GIT_SITE=github.com
  zstyle -s ':antidote:test:env'     LOCALAPPDATA ANTIDOTE_LOCALAPPDATA || ANTIDOTE_LOCALAPPDATA="${LOCALAPPDATA:-$LocalAppData}"
  zstyle -s ':antidote:test:env'     OSTYPE       ANTIDOTE_OSTYPE       || ANTIDOTE_OSTYPE=$OSTYPE
  zstyle -T ':antidote:test:git'     autostash && ANTIDOTE_GIT_AUTOSTASH=true
  zstyle -T ':antidote:test:version' show-sha  && ANTIDOTE_VERSION_SHOW_SHA=true
  # Legacy use of friendly names overrides all
  if zstyle -t ':antidote:bundle' use-friendly-names; then
    ANTIDOTE_PATH_STYLE=short
  fi

  typeset -g ANTIDOTE_HOME=${ANTIDOTE_HOME:-$(get_cachedir antidote)}

  typeset -g ANTIDOTE_SNAPSHOT_DIR ANTIDOTE_SNAPSHOT_MAX ANTIDOTE_SNAPSHOT_DATEFMT ANTIDOTE_AUTOSNAPSHOT=false
  zstyle -s ':antidote:snapshot' dir        ANTIDOTE_SNAPSHOT_DIR     || ANTIDOTE_SNAPSHOT_DIR=$(get_datadir antidote)/snapshots
  zstyle -s ':antidote:snapshot' max        ANTIDOTE_SNAPSHOT_MAX     || ANTIDOTE_SNAPSHOT_MAX=100
  zstyle -s ':antidote:snapshot' dateformat ANTIDOTE_SNAPSHOT_DATEFMT || ANTIDOTE_SNAPSHOT_DATEFMT='%Y-%m-%d %H:%M:%S %Z'
  zstyle -T ':antidote:snapshot:automatic' enabled && ANTIDOTE_AUTOSNAPSHOT=true
  ANTIDOTE_SNAPSHOT_DIR=${~ANTIDOTE_SNAPSHOT_DIR}

  typeset -g ANTIDOTE_COLOR C_BLUE C_GREEN C_YELLOW C_NORMAL
  if supports_color; then
    ANTIDOTE_COLOR=true
    C_BLUE=$'\E[34m'
    C_GREEN=$'\E[32m'
    C_YELLOW=$'\E[33m'
    C_NORMAL=$'\E[0m'
  fi
} "${0:A}"

ANTIDOTE_HELP=$(
cat <<'EOS'
antidote - the cure to slow zsh plugin management

usage: antidote [<flags>] <command> [<args> ...]

flags:
  -h, --help            Show context-sensitive help
  -v, --version         Show application version
      --diagnostics     Show antidote and system diagnostics

commands:
  bundle    Clone bundle(s) and generate the static load script
  install   Clone a new bundle and add it to your plugins file
  update    Update antidote and its cloned bundles
  purge     Remove a cloned bundle
  home      Print where antidote is cloning bundles
  list      List cloned bundles
  path      Print the path of a cloned bundle
  snapshot  Save, restore, or list bundle snapshots
  init      Initialize the shell for dynamic bundles
EOS
)

antidote "$@"
ERR=$?

# Internal profiling support
if [[ -n "$ANTIDOTE_PROFILE" ]]; then
  zprof >> "${ANTIDOTE_PROFILE_OUT:-/tmp/antidote-profile.zprof}"
fi

[[ "$ERR" -eq 0 ]] || exit $ERR

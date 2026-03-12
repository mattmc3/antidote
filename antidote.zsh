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

# Initial vars
0=${(%):-%N}
builtin autoload -Uz is-at-least
ZPARSEOPTS=( -D -M )
is-at-least 5.8 && ZPARSEOPTS+=( -F )
TAB="$(printf '\t')"

# When sourced, behave differently
if [[ ":${ZSH_EVAL_CONTEXT}:" == *:file:* ]]; then
  typeset -f antidote-setup &>/dev/null && unfunction antidote-setup
  builtin autoload -Uz ${0:A:h}/functions/antidote-setup
  antidote-setup
  return 0
fi

# Internal profiling support
[[ -n "$ANTIDOTE_PROFILE" ]] && zmodload zsh/zprof

# Load config: source config file then apply any serialized zstyles
() {
  local _cfg=${ANTIDOTE_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/antidote/config.zsh}
  [[ -f "$_cfg" ]] && source "$_cfg"
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
git_url()      { git -C "$1" config remote.origin.url; }
git_sha()      { git -C "$1" rev-parse HEAD; }
git_shortsha() { git -C "$1" rev-parse --short HEAD; }

git_is_shallow()  { [[ -f "$1/.git/shallow" ]] || [[ "$(git -C "$1" rev-parse --is-shallow-repository 2>/dev/null)" == "true" ]] }
git_clone()       { git clone --depth 1 --no-local --quiet --recurse-submodules --shallow-submodules "$@"; }
git_fetch()       { local d=$1; shift; git -C "$d" fetch --quiet "$@"; }
git_pull() {
  local -a autostash_flag=(--autostash)
  [[ "$ANTIDOTE_GIT_AUTOSTASH" != true ]] && autostash_flag=()
  git -C "$1" pull --quiet --ff --rebase $autostash_flag
}
git_log_oneline()      { git -C "$1" --no-pager log --oneline --ancestry-path --first-parent "${2}^..${3}" 2>/dev/null; }
git_submodule_sync()   { git -C "$1" submodule --quiet sync --recursive; }
git_submodule_update() { git -C "$1" submodule --quiet update --init --recursive --depth 1; }
git_checkout_detach()  { git -C "$1" checkout --quiet --detach "$2"; }
git_config_get()       { git -C "$1" config --get "$2" 2>/dev/null; }
git_config_set()       { git -C "$1" config "$2" "$3"; }
git_config_unset()     { git -C "$1" config --unset "$2" 2>/dev/null; }

# True if the bundle is a git repo (not a local path/file).
is_repo() {
  [[ $(bundle_type "$1") == (repo|url|ssh_url) ]]
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
  lines=("${(f)input}")

  lineno=1
  for line in $lines; do
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
      btype=$(bundle_type "$bname")
      bundle[__type__]="$btype"
      if [[ "$btype" == (repo|url|ssh_url|malformed_url) ]]; then
        bundle[__url__]=$(tourl "$bname")
        bundle[__short__]=$(short_repo_name "$bname")
        bundle[__dir__]=$(bundle_dir "$bname")
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
  if [[ "$ANTIDOTE_VERSION_SHOW_SHA" == true ]]; then
    local gitsha=$(git_shortsha ${ANTIDOTE_ZSH:h})
    [[ -z "$gitsha" ]] || ver="$ver ($gitsha)"
  fi
  say "antidote version $ver"
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
  local bundle=$1
  local url=$bundle
  if [[ $bundle != *://* && $bundle != git@*:*/* ]]; then
    if [[ ${ANTIDOTE_GIT_PROTOCOL:-https} == ssh ]]; then
      url=git@${ANTIDOTE_GIT_SITE}:$bundle
    else
      url=https://${ANTIDOTE_GIT_SITE}/$bundle
    fi
  fi
  say $url
}

bundle_type() {
  local bundle=$1
  local result url_path ssh_path
  local -a path_parts

  # Try to expand path bundles with '$' and '~' prefixes so that we get a more
  # granular result than 'path'.
  if [[ $bundle == '~/'* ]]; then
    bundle=${~bundle}
  elif [[ $bundle == '$'* ]]; then
    bundle=${(e)bundle}
  fi

  # Determine the bundle type.
  if [[ -e "$bundle" ]]; then
    [[ -f $bundle ]] && result=file || result=dir
  elif [[ -z "${bundle// }" ]]; then
    result=empty
  else
    case "$bundle" in
      (/|~|'$'|'.')*)  result=path   ;;
      *://*)
        # Validate URL format: https://website.com/user/repo[.git]
        url_path="${bundle#*://}"      # Remove protocol
        url_path="${url_path#*/}"      # Remove domain
        url_path="${url_path%.git}"    # Remove optional .git
        path_parts=(${(ps:/:)url_path})
        if [[ ${#path_parts} -eq 2 ]]; then
          result=url
        else
          result=malformed_url
        fi
        ;;
      *@*:*/*)
        # Validate SSH URL format: git@website.com:user/repo[.git]
        ssh_path="${bundle#*:}"        # Get everything after the colon
        ssh_path="${ssh_path%.git}"    # Remove optional .git
        path_parts=(${(ps:/:)ssh_path})
        if [[ ${#path_parts} -eq 2 ]]; then
          result=ssh_url
        else
          result=malformed_url
        fi
        ;;
      *(:|@)*)         result='?'      ;;
      */*/*)           result=relpath  ;;
      */)              result=relpath  ;;
      */*)             result=repo     ;;
      *)               result=word     ;;
    esac
  fi
  say $result
}

# Convert URLs and paths to short user/repo form
short_repo_name() {
  local bundle=$1
  bundle=${bundle%.git}
  bundle=${bundle:gs/\:/\/}
  local parts=(${(ps./.)bundle})
  say ${parts[-2]}/${parts[-1]}
}

bundle_name() {
  local bundle=$1
  local bundle_type="$(bundle_type $bundle)"
  if [[ "$bundle_type" == (url|ssh_url) ]] ; then
    say $(short_repo_name $bundle)
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
    result=$ANTIDOTE_LOCALAPPDATA
    if (( $+commands[cygpath] )); then
      result=$(cygpath "$result")
    fi
  else
    result=${XDG_CACHE_HOME:-$HOME/.cache}
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
# usage: maketmp [-d] [-s suffix]
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

# Print a path, replacing $HOME with the literal string "$HOME" unless escaped style.
print_path() {
  if [[ $ANTIDOTE_PATH_STYLE == escaped ]]; then
    say "$1"
  else
    say "${1/#$HOME/\$HOME}"
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
    bundles=($(antidote_list))
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
  # Determine the bundle directory based on the configured path-style:
  #   full (default) : $ANTIDOTE_HOME/github.com/owner/repo
  #   short          : $ANTIDOTE_HOME/owner/repo
  #   escaped        : $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-owner-SLASH-repo
  # If the bundle is a file, use its parent directory.
  # Otherwise, just assume the bundle is a directory.
  local bundle=$1
  local bundle_type="$(bundle_type $bundle)"

  if [[ "$bundle_type" == (repo|url|ssh_url) ]] && [[ ! -e "$bundle" ]]; then
    local url=$(tourl $bundle)
    url=${url%.git}
    case $ANTIDOTE_PATH_STYLE in
      escaped)
        url=${url:gs/\@/-AT-}
        url=${url:gs/\:/-COLON-}
        url=${url:gs/\//-SLASH-}
        say $ANTIDOTE_HOME/$url
        ;;
      short)
        bundle=${bundle%.git}
        bundle=${bundle:gs/\:/\/}
        local parts=( ${(ps./.)bundle} )
        if [[ $#parts -gt 1 ]]; then
          say $ANTIDOTE_HOME/${parts[-2]}/${parts[-1]}
        else
          say $ANTIDOTE_HOME/$bundle
        fi
        ;;
      *)  # full
        if [[ $url == https://* ]]; then
          url=${url#https://}
        elif [[ $url == git@*:* ]]; then
          url=${url#git@}
          url=${url:s/\:/\/}
        fi
        say $ANTIDOTE_HOME/$url
        ;;
    esac
  elif [[ -f "$bundle" ]]; then
    say ${bundle:A:h}
  else
    say ${bundle}
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
  local bundle_str collected_input lineno skip_load_defer
  local key val _parsed
  local -a bundles
  local -A bundle

  lineno=0
  skip_load_defer=0

  # Get piped/passed bundles
  collected_input="$(collect_input "$@")"
  if [[ -n "$collected_input" ]]; then
    bundles=( "${(@f)collected_input}" )
  else
    bundles=()
  fi
  if ! (( $#bundles )); then
    die "antidote: error: bundle argument expected"
  fi

  # Loop through bundles
  for bundle_str in $bundles; do
    (( lineno += 1 ))

    # Parse the bundle.
    _parsed=$(printf '%s\n' "$bundle_str" | bundle_parser)
    [[ -z "$_parsed" ]] && continue
    bundle=("${(@Q)${(z)_parsed}}")
    if [[ -n "${bundle[__error__]}" ]]; then
      warn "antidote: Bundle parser error on line ${lineno}: '$bundle_str'"
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
  local MATCH MBEGIN MEND REPLY
  local -a match mbegin mend
  local -a o_help o_kind o_path o_branch o_pin o_cond o_autoload o_pre o_post o_fpath_rule o_skip_load_defer
  local re bundle bname bundle_path btype dopts zsh_defer zsh_defer_bundle giturl current_pin
  local source_cmd print_bundle_path initfile print_initfile fpath_script _initfiles_out
  local -a supported_kind_vals supported_fpath_rules script initfiles

  REPLY=

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
  re='^[=:]?(.+)$'
  [[ $o_kind[-1] =~ $re ]] && o_kind[-1]=$match
  [[ $o_autoload[-1] =~ $re ]] && o_autoload[-1]=$match
  [[ $o_path[-1] =~ $re ]] && o_path[-1]=$match
  [[ $o_cond[-1] =~ $re ]] && o_cond[-1]=$match
  [[ $o_branch[-1] =~ $re ]] && o_branch[-1]=$match
  [[ $o_pin[-1] =~ $re ]] && o_pin[-1]=$match
  [[ $o_pre[-1] =~ $re ]] && o_pre[-1]=$match
  [[ $o_post[-1] =~ $re ]] && o_post[-1]=$match
  [[ $o_fpath_rule[-1] =~ $re ]] && o_fpath_rule[-1]=$match

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
  bname=$(bundle_name $bundle)

  # replace ~/ with $HOME/
  if [[ "$bundle" == '~/'* ]]; then
    bundle=${~bundle}
  fi

  # set the path to the bundle (repo or local)
  [[ -e "$bundle" ]] && bundle_path=$bundle || bundle_path=$(bundle_dir $bundle)

  # handle cloning repo bundles
  btype=$(bundle_type $bundle)
  if [[ "$btype" == (repo|url|ssh_url) ]] && [[ ! -e "$bundle_path" ]]; then
    giturl=$(tourl $bundle)
    warn "# antidote cloning $bname..."
    if (( $#o_pin )); then
      # Pin: clone at the pinned ref (works for tags/branches, stays shallow)
      if ! git_clone --branch $o_pin[-1] $giturl $bundle_path; then
        warn "antidote: error: pin ref '$o_pin[-1]' not found for $bname"
        return 1
      fi
      # Detach HEAD so update won't accidentally advance past the pin
      git_checkout_detach "$bundle_path" $o_pin[-1]
      # Store pin in repo-local git config so antidote update knows to skip it
      git_config_set "$bundle_path" antidote.pin $o_pin[-1]
    else
      git_clone $o_branch $giturl $bundle_path || return 1
    fi
  fi

  # Sync pin state for existing repos
  if [[ "$btype" == (repo|url|ssh_url) ]] && [[ -e "$bundle_path" ]]; then
    if (( $#o_pin )); then
      current_pin=$(git_config_get "$bundle_path" antidote.pin)
      if [[ "$current_pin" != "$o_pin[-1]" ]]; then
        # Pin changed or newly added — fetch the ref and checkout
        # Try fetching the specific ref first (works for tags/branches)
        git_fetch "$bundle_path" origin tag $o_pin[-1] 2>/dev/null \
          || git_fetch "$bundle_path" origin $o_pin[-1] 2>/dev/null \
          || git_fetch "$bundle_path" --unshallow origin 2>/dev/null
        if ! git_checkout_detach "$bundle_path" $o_pin[-1]; then
          warn "antidote: error: pin ref '$o_pin[-1]' not found for $bname"
          return 1
        fi
        git_config_set "$bundle_path" antidote.pin $o_pin[-1]
      fi
    else
      git_config_unset "$bundle_path" antidote.pin
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
  print_bundle_path=$(print_path "$bundle_path")

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

  # generate load script
  btype=$(bundle_type $bundle_path)
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
      _initfiles_out=$(initfiles $bundle_path)
      if [[ -n "$_initfiles_out" ]]; then
        initfiles=("${(@f)_initfiles_out}")
      fi
      # if no init file was found, assume the default
      if [[ $#initfiles -eq 0 ]]; then
        if (( $#o_path )); then
          initfiles=($bundle_path/${bundle_path:t}.plugin.zsh)
        else
          initfiles=($bundle_path/${bname:t}.plugin.zsh)
        fi
      fi
      script+="$fpath_script"
      for initfile in $initfiles; do
        print_initfile=$(print_path "$initfile")
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
    printf "  %s\n" $script
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
  local o_help
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
  if zstyle -t ':antidote:static' zcompile; then
    printf '%s\n' $zcompile_script
  fi

  # antidote_script also clones, but this way we can do it all at once in parallel!
  if (( $#bundles > 1 )); then
    source <(printf '%s\n' $bundles | bundle_parser | bulk_clone)
  fi

  # generate bundle script
  source <(printf '%s\n' $bundles | bundle_scripter)
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

  bundledir=$(bundle_dir $bundle)
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
  local bundlefile bundle bundledir dtstmp
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
      read -q "REPLY?You are about to permanently remove '$ANTIDOTE_HOME' and all its contents!"$'\n'"Are you sure [Y/n]? "
      print
    }
    [[ ${REPLY:u} == "Y" ]] || return 1
    # remove antidote home and static cache file
    del -rf -- "$ANTIDOTE_HOME"

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

    bundledir=$(bundle_dir $bundle)
    if [[ ! -d "$bundledir" ]]; then
      die "antidote: error: $bundle does not exist at the expected location: $bundledir"
    fi

    # remove
    del -rf "$bundledir"
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
# usage: antidote update [-h|--help] [-s|--self] [-b|--bundles]
#
antidote_update() {
  local o_help o_self o_bundles
  local tmpfile tmpdir bundledir url repo filename repo_id antidote_dir pin_ref
  local green blue yellow normal
  local line loadable_check_path

  zparseopts ${ZPARSEOPTS} -- \
    h=o_help    -help=h    \
    s=o_self    -self=s    \
    b=o_bundles -bundles=b ||
    return 1

  if (( $#o_help )); then
    usage
    return
  fi

  # colors
  if supports_color; then
    if (( $+commands[tput] )); then
      green=$(tput setaf 2)
      blue=$(tput setaf 4)
      yellow=$(tput setaf 3)
      normal=$(tput sgr0)
    else
      green=$'\E[32m'
      blue=$'\E[34m'
      yellow=$'\E[33m'
      normal=$'\E[0m'
    fi
  fi

  if (( $#o_bundles )) || ! (( $#o_self )); then
    say "Updating bundles..."

    # remove zcompiled files
    del -rf -- $ANTIDOTE_HOME/**/*.zwc(N)

    # remove check file
    loadable_check_path="${ANTIDOTE_HOME}/.antidote.load"
    [[ -r "$loadable_check_path" ]] && del -- "$loadable_check_path"

    # Setup temporary directory
    tmpdir=$(maketmp -d -s update)

    # Set trap to ensure cleanup on exit, interrupt, etc.
    # (EXIT is special, 2=INT, 15=TERM, 1=HUP)
    trap '[[ -d "$tmpdir" ]] && del -rf -- "$tmpdir"' EXIT 2 15 1

    # update all bundles
    for bundledir in $(antidote_list); do
      url=$(git_url "$bundledir")
      repo="${url:h:t}/${${url:t}%.git}"

      # Skip pinned bundles
      pin_ref=$(git_config_get "$bundledir" antidote.pin)
      if [[ -n "$pin_ref" ]]; then
        say "antidote: skipping update for pinned bundle: $repo (at $pin_ref)"
        continue
      fi

      say "antidote: checking for updates: $url"

      () {
        local repo_id tmpfile oldsha newsha
        local GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM

        repo_id="${repo//\//-SLASH-}"
        tmpfile="${tmpdir}/${repo_id}.output"
        oldsha=$(git_shortsha "$1")

        # Isolate git from user config
        GIT_CONFIG_GLOBAL=/dev/null
        GIT_CONFIG_SYSTEM=/dev/null

        # Unshallow the repo if needed
        if git_is_shallow "$1"; then
          git_fetch "$1" --unshallow
        else
          git_fetch "$1"
        fi

        git_pull "$1"
        git_submodule_sync "$1"
        git_submodule_update "$1"
        newsha=$(git_shortsha "$1")

        # Capture all output to temporary file
        {
          if [[ $oldsha != $newsha ]]; then
            say "${green}antidote: updated: $2 ${oldsha} -> ${newsha}${normal}"
            git_log_oneline "$1" "$oldsha" "$newsha"
          fi

          # recompile bundles
          if zstyle -t ":antidote:bundle:$repo" zcompile; then
            bundle_zcompile $bundledir
          fi
        } > "$tmpfile" 2>&1
      } "$bundledir" "$url" &
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

        say "${blue}Bundle ${repo_id} update check complete.${normal}"

        # Colorize the SHA in each line
        while IFS= read -r line; do
          if [[ -n "$line" ]] && [[ "$line" == [[:alnum:]]* ]]; then
            say "${yellow}${line%% *}${normal} ${line#* }"
          else
            say "$line"
          fi
        done < "$tmpfile"
        say ""
      fi
    done

    # cleanup temp dir
    [[ -d "$tmpdir" ]] && del -rf -- "$tmpdir"
    say "${green}Bundle updates complete.${normal}"
    say ""
  fi

  # self-update
  if (( $#o_self )) || ! (( $#o_bundles )); then
    say "Updating antidote..."
    antidote_dir="${ANTIDOTE_ZSH:A:h}"
    if [[ -d "${antidote_dir}/.git" ]]; then
      git_pull "$antidote_dir" 2>/dev/null
      say "antidote self-update complete."
      say ""
      version
    else
      say "Self updating is disabled in this build."
      say "Use your OS package manager to update antidote itself."
    fi
  fi
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
  say "      source <( antidote-dispatch \$@ ) || antidote-dispatch \$@"
  say "      ;;"
  say "    *)"
  say "      antidote-dispatch \$@"
  say "      ;;"
  say "  esac"
  say "}"
}

### List cloned bundles.
#
# usage: antidote list [-u|--url] [-h|--help] [-s|--short-name] [--sha] [--short-sha] [-j|--jsonl]
#
antidote_list() {
  local o_help o_jsonl o_url o_short_name o_sha o_short_sha
  zparseopts ${ZPARSEOPTS} -- \
    h=o_help       -help=h    \
    u=o_url        -url=u     \
    j=o_jsonl      -jsonl=j   \
    s=o_short_name -short-name=s \
                   -sha=o_sha    \
                   -short-sha=o_short_sha ||
    return 1

  if (( $# )); then
    die "antidote: error: unexpected $1, try --help"
  fi

  local bundledir url short_name sha
  local -a output=() parts=()
  local -a bundles=()

  # each style has a different depth
  case $ANTIDOTE_PATH_STYLE in
      escaped) bundles=($ANTIDOTE_HOME/*/.git(/N))     ;;
      short)   bundles=($ANTIDOTE_HOME/*/*/.git(/N))   ;;
      *)       bundles=($ANTIDOTE_HOME/*/*/*/.git(/N)) ;;
  esac

  for bundledir in $bundles; do
    bundledir=${bundledir:h}
    url=$(git_url "$bundledir") || continue
    short_name=${url%.git}
    short_name=${short_name#https://${ANTIDOTE_GIT_SITE}/}
    parts=($bundledir)

    if (( $#o_jsonl )); then
      sha=$(git_sha "$bundledir")
      printf '{"url":"%s","short_name":"%s","type":"repo","path":"%s","sha":"%s"}\n' \
        "$url" "$short_name" "$bundledir" "$sha"
      continue
    elif (( $#o_url || $#o_short_name || $#o_sha || $#o_short_sha )); then
      (( $#o_short_name )) && parts+=($short_name)
      (( $#o_url        )) && parts+=($url)
      (( $#o_sha        )) && parts+=($(git_sha "$bundledir"))
      (( $#o_short_sha  )) && parts+=($(git_shortsha "$bundledir"))
      output+=("$(printf '%s\n' ${(pj:\t:)parts})")
    else
      output+=("$(printf '%s\n' $bundledir)")
    fi
  done
  (( $#output )) && printf '%s\n' ${(o)output}
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
  local o_help o_version
  zparseopts ${ZPARSEOPTS} -- \
    h=o_help      -help=h     \
    v=o_version   -version=v  ||
    return 1

  if (( ${#o_version} )); then
    version
    return 0
  fi

  if [[ ${#} -eq 0 ]]; then
    return 2
  fi

  local cmd=$1; shift
  if [[ "$cmd" == __private__ ]]; then
    cmd="$1"
    shift
    "${cmd}" "$@"
    return $?
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
  typeset -g ANTIDOTE_VERSION="1.10.3"
  typeset -g ANTIDOTE_TMPDIR=${ANTIDOTE_TMPDIR:-$TMPDIR}

  typeset -g ANTIDOTE_GIT_SITE ANTIDOTE_GIT_PROTOCOL ANTIDOTE_GIT_CMD ANTIDOTE_PATH_STYLE
  typeset -g ANTIDOTE_DEFER_BUNDLE ANTIDOTE_FPATH_RULE
  typeset -g ANTIDOTE_OSTYPE ANTIDOTE_LOCALAPPDATA
  typeset -g ANTIDOTE_VERSION_SHOW_SHA=false ANTIDOTE_GIT_AUTOSTASH=false
  zstyle -s ':antidote:bundle'       path-style   ANTIDOTE_PATH_STYLE   || ANTIDOTE_PATH_STYLE=full
  zstyle -s ':antidote:defer'        bundle       ANTIDOTE_DEFER_BUNDLE || ANTIDOTE_DEFER_BUNDLE=romkatv/zsh-defer
  zstyle -s ':antidote:fpath'        rule         ANTIDOTE_FPATH_RULE   || ANTIDOTE_FPATH_RULE=append
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
} "${0:A}"

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
ERR=$?

# Internal profiling support
if [[ -n "$ANTIDOTE_PROFILE" ]]; then
  zprof >> "${ANTIDOTE_PROFILE_OUT:-/tmp/antidote-profile.zprof}"
fi

[[ "$ERR" -eq 0 ]] || exit $ERR

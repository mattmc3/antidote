#!/usr/bin/env zsh

# Ensure we're in Zsh and not bash
if [ -n "$BASH_VERSION" ]; then
  echo >&2 "antidote: This script requires Zsh, not Bash"
  return 1 2>/dev/null || exit 1
elif [ -z "$ZSH_VERSION" ]; then
  shellname="$(ps -p $$ -oargs= 2>/dev/null | awk 'NR==1{print $1}')"
  echo >&2 "antidote: This script requires Zsh, not '$shellname'."
  return 1 2>/dev/null || exit 1
fi

# When sourced, behave differently. Zsh uses the 'filecode' context
# token instead of 'file' when a script loads from its .zwc bytecode.
0=${(%):-%N}
if [[ ":${ZSH_EVAL_CONTEXT}:" == *:file(|code):* ]]; then
  typeset -f antidote-setup &>/dev/null && unfunction antidote-setup
  builtin autoload -Uz ${0:a:h}/functions/antidote-setup
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

# Internal profiling support
[[ -n "$ANTIDOTE_PROFILE" ]] && zmodload zsh/zprof
zmodload zsh/datetime

# Load config: source config file then apply any serialized zstyles.
# XDG resolution is fine here rather than via get_dir.
typeset -g ANTIDOTE_CONFIG=${ANTIDOTE_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/antidote/config.zsh}
[[ -f "$ANTIDOTE_CONFIG" ]] && source "$ANTIDOTE_CONFIG"
[[ -n "$ANTIDOTE_ZSTYLES" ]] && eval "$ANTIDOTE_ZSTYLES"

# Zsh options needed by antidote
setopt extended_glob
typeset -ga _ext_setopts
zstyle -a ':antidote:test' setopts _ext_setopts && setopt $_ext_setopts
unset _ext_setopts

##### OUTPUT HELPERS

die()     { warn "$@"; exit "${ERR:-1}"; }
say()     { printf '%s\n' "$@"; }
warn()    { say "$@" >&2; }
is_true() { [[ "${1:l}" != (0|no|false|off) ]]; }

# Escape a string for use inside a JSON double-quoted value.
json_escape() {
  local i ch esc
  esc=${1//\\/\\\\}
  esc=${esc//\"/\\\"}
  esc=${esc//$'\b'/\\b}
  esc=${esc//$'\f'/\\f}
  esc=${esc//$'\n'/\\n}
  esc=${esc//$'\r'/\\r}
  esc=${esc//$'\t'/\\t}
  # Any remaining C0 control chars need \u00XX form to be valid JSON.
  if [[ "$esc" == *[$'\x01'-$'\x1f']* ]]; then
    for (( i = 1; i <= 31; i++ )); do
      ch=${(#)i}
      [[ "$esc" == *${ch}* ]] || continue
      esc=${esc//${ch}/\\u$(printf '%04x' $i)}
    done
  fi
  typeset -g REPLY=$esc
}

# Prompt for a y/n answer unless a test zstyle provides one.
# usage: confirm <test-zstyle-context> <prompt>
confirm() {
  local REPLY
  zstyle -s "$1" answer REPLY || {
    read -q "REPLY?$2"
    print
  }
  [[ ${REPLY:u} == Y ]]
}

##### GIT HELPERS

# Error-capturing wrapper around $_ANTIDOTE_GIT_CMD. Named so a bare
# `git` in this file is unambiguously the real thing. Output lands in
# REPLY, never on stdout: git chatters on success (eg "warning:
# redirecting to") and stdout during bundling is the generated script.
gits() {
  local err out
  # Two steps: assigning inside typeset would report typeset's status.
  out="$(command "$_ANTIDOTE_GIT_CMD" "$@" 2>&1)"
  err=$?
  typeset -g REPLY=$out
  if (( err )); then
    warn "antidote: unexpected git error on command 'git $*'."
    if [[ -n "$REPLY" ]]; then
      warn "antidote: error details:"
      warn "$REPLY"
    fi
    return $err
  fi
}

# Quiet wrapper for calls where a nonzero exit is the expected answer.
gitq() { command "$_ANTIDOTE_GIT_CMD" "$@" 2>/dev/null; }

# gits, for the calls whose output the caller reads off stdout.
gitsay() { gits "$@" || return $?; [[ -z "$REPLY" ]] || say "$REPLY" }

# Having all the git usage in one place helps me easily see at a glance what all we run.
git_checkout_detach()   { gits -C "$1" checkout --quiet --detach "$2"; }
git_clone()             { local d=$1; shift; gits clone --depth 1 --no-local --quiet --recurse-submodules --shallow-submodules "$@" "$d"; }
git_config_get()        { gitsay -C "$1" config --get "$2" 2>/dev/null; }
git_config_set()        { gits -C "$1" config "$2" "$3"; }
git_config_unset()      { gits -C "$1" config --unset "$2" 2>/dev/null; }
git_fetch()             { local d=$1; shift; gits -C "$d" fetch --quiet "$@"; }
git_unshallow()         { git_fetch "$1" --unshallow; }
git_unshallow_try()     { gitq -C "$1" fetch --quiet --unshallow >/dev/null }
git_is_shallow()        { [[ -f "$1/.git/shallow" ]] || [[ "$(gitq -C "$1" rev-parse --is-shallow-repository)" == "true" ]] }
git_is_ancestor()       { gitq -C "$1" merge-base --is-ancestor "$2" "$3" }
git_log_oneline()       { gitsay -C "$1" --no-pager log --abbrev=7 --oneline --ancestry-path --first-parent "${2}..${3}" 2>/dev/null; }
git_merge_ffonly()      { gits -C "$1" merge --quiet --ff-only "$2"; }
git_min_age_sha()       { gitsay -C "$1" rev-list --before="${2} days ago" -1 "$3" 2>/dev/null; }
git_reset_hard()        { gits -C "$1" reset --quiet --hard "$2"; }
git_sha()               { local d=$1; shift; gitsay -C "$d" rev-parse "$@" HEAD; }
git_submodule_sync()    { gits -C "$1" submodule --quiet sync --recursive; }
git_submodule_update()  { gits -C "$1" submodule --quiet update --init --recursive --depth 1; }
git_url()               { gitsay -C "$1" config remote.origin.url; }
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

# Print the ref a bundle updates against, or return 1. Falls back past
# @{upstream} for a detached HEAD (eg an ephemeral pin).
git_upstream_ref() {
  local ref
  local -a refs
  ref=$(gitq -C "$1" rev-parse --symbolic-full-name '@{upstream}')
  if [[ -z "$ref" ]]; then
    refs=(${(f)"$(gitq -C "$1" for-each-ref --format='%(refname)' refs/remotes/origin)"})
    refs=(${refs:#refs/remotes/origin/HEAD})
    if (( $#refs == 1 )); then
      ref=$refs[1]
    else
      ref=$(gitq -C "$1" symbolic-ref refs/remotes/origin/HEAD)
    fi
  fi
  [[ -n "$ref" ]] || return 1
  print -r -- "$ref"
}

# Rebase onto an already-fetched ref. Not `git pull`: a concurrent fetch
# on the same repo can leave two branches for merge in FETCH_HEAD, which
# kills the rebase. A ref can't.
git_rebase() {
  local -a autostash_flag=(--autostash)
  [[ "$_ANTIDOTE_GIT_AUTOSTASH" != true ]] && autostash_flag=()
  gits -C "$1" rebase --quiet $autostash_flag "$2"
}

# Move a bundle straight onto a ref, stashing local edits the way
# git_rebase's --autostash would. Edits that no longer apply stay in the
# stash rather than landing as conflict markers in a sourced plugin.
git_reset_to() {
  local dir="$1" ref="$2" bname="$3" stashed=
  if [[ "$_ANTIDOTE_GIT_AUTOSTASH" == true ]] && ! gitq -C "$dir" diff --quiet HEAD; then
    gitq -C "$dir" stash push --quiet && stashed=1
  fi
  git_reset_hard "$dir" "$ref" || return 1
  if [[ -n "$stashed" ]] && ! gitq -C "$dir" stash pop --quiet; then
    git_reset_hard "$dir" "$ref" || return 1
    warn "antidote: $bname: local changes conflicted, kept in the stash (git -C $dir stash pop)"
  fi
}

### Read the min-age zstyle for a bundle.
#
# usage: min_age_days <bundle-name>
# Sets REPLY to the configured age in days, or 0 when unset.
#
min_age_days() {
  local days
  zstyle -s ":antidote:bundle:$1" min-age days || days=0
  # Fail-safe: an unset style can still resolve to an empty value.
  # Treat that as no delay rather than erroring. Use 0 to opt out.
  [[ -z "$days" ]] && days=0
  if [[ "$days" != <-> ]]; then
    warn "antidote: error: min-age requires a whole number of days, got '$days'"
    return 1
  fi
  typeset -g REPLY=$days
}

### Move a repo back to the newest commit older than N days.
#
# usage: git_min_age_reset <dir> <days> <bundle-name>
# A shallow clone has no history to search, so unshallow first.
#
git_min_age_reset() {
  local dir="$1" days="$2" bname="$3" sha
  if git_is_shallow "$dir"; then
    git_unshallow "$dir" || return 1
  fi
  sha=$(git_min_age_sha "$dir" "$days" HEAD)
  if [[ -z "$sha" ]]; then
    warn "# antidote: $bname: no commits older than $days days, using latest"
    return 0
  fi
  git_reset_hard "$dir" "$sha"
}

##### BUNDLE DISCOVERY & CLONING

# Find all cloned bundles under ANTIDOTE_HOME.
find_bundles() {
  command find -H "$ANTIDOTE_HOME" -type d -name .git -prune -print 2>/dev/null | \
    sed 's|/.git$||' | sort
}

bulk_clone() {
  local i bundle zsh_defer=0
  local -a row
  local -aU script

  if (( !${_parsed_bundles[__count__]:-0} )); then
    bundle_parser
  fi

  for (( i = 1; i <= _parsed_bundles[__count__]; i++ )); do
    bundle=${_parsed_bundles[$i,__bundle__]}
    bundle_type "$bundle"
    [[ $REPLY == (repo|url|ssh_url) ]] || continue

    if [[ "${_parsed_bundles[$i,kind]}" == defer && $zsh_defer == 0 ]]; then
      zsh_defer=1
      row=(__bundle__ "${(q)_ANTIDOTE_DEFER_BUNDLE}" kind clone)
      script+=("zsh_script ${(j: :)row} &")
    fi

    row=(__bundle__ "${(q)bundle}" kind clone)
    [[ -n "${_parsed_bundles[$i,branch]}" ]] && row+=(branch "${(q)_parsed_bundles[$i,branch]}")
    [[ -n "${_parsed_bundles[$i,pin]}" ]] && row+=(pin "${(q)_parsed_bundles[$i,pin]}")
    script+=("zsh_script ${(j: :)row} &")
  done

  if [[ ${#script} -gt 0 ]]; then
    printf '%s\n' ${(o)script[@]}
    printf 'wait\n'
  fi
}

##### BUNDLE PARSER

### Handle a using: directive line - set the active using context.
#
# Repo using: converts the entry to kind:clone and returns 0 to keep it.
# Path using: sets context only and returns 1 to skip the entry.
# Invalid using: records an error entry and returns 1 to skip it.
# Reads/writes bundle_parser's locals (bundle, bname, n) via dynamic scoping.
#
parse_using_directive() {
  local key
  typeset -gA _antidote_using_context=()
  _antidote_using_context[bundle]=${bname#using:}
  bundle_type "${_antidote_using_context[bundle]}"; _antidote_using_context[__type__]=$REPLY
  if [[ "${_antidote_using_context[__type__]}" == ('?'|empty) ]]; then
    bundle[__error__]="invalid using: target '${_antidote_using_context[bundle]}'"
    bundle[__severity__]=error
    for key in ${(k)bundle}; do
      _parsed_bundles[$n,$key]=$bundle[$key]
    done
    _parsed_bundles[__has_errors__]=1
    return 1
  fi
  for key in ${(k)bundle}; do
    [[ $key == __* ]] && continue
    _antidote_using_context[$key]=$bundle[$key]
  done
  if [[ "${_antidote_using_context[__type__]}" == (repo|url|ssh_url) ]]; then
    bundle[__bundle__]=${_antidote_using_context[bundle]}
    bundle[kind]=clone
    unset "bundle[path]"
    typeset -g bname=$bundle[__bundle__]
    return 0
  fi
  (( n-- ))
  return 1
}

### Expand a bare-word bundle using the active using: context.
#
# Reads/writes bundle_parser's locals (bundle, bname, btype) via dynamic scoping.
#
expand_using_subplugin() {
  local key ctx_path ctx_type
  ctx_path=${_antidote_using_context[path]:-}
  ctx_type=${_antidote_using_context[__type__]:-}
  for key in ${(k)_antidote_using_context}; do
    [[ $key == (bundle|path|__type__) ]] && continue
    [[ -n "${bundle[$key]}" ]] || bundle[$key]=${_antidote_using_context[$key]}
  done
  [[ -n "${bundle[kind]}" ]] || bundle[kind]=zsh
  if [[ "$ctx_type" == (path|dir|file) ]]; then
    # Path using: construct the full path as the bundle
    bundle[__bundle__]=${_antidote_using_context[bundle]}${ctx_path:+/$ctx_path}/$bname
    typeset -g bname=$bundle[__bundle__]
    bundle_type "$bname"; typeset -g btype=$REPLY
  else
    # Repo using: keep repo as bundle, set path annotation
    [[ -n "${bundle[path]}" ]] || bundle[path]=${ctx_path:+$ctx_path/}$bname
    bundle[__bundle__]=${_antidote_using_context[bundle]}
    typeset -g bname=$bundle[__bundle__]
  fi
}

### Detect pin/branch conflicts across entries sharing a bundle dir.
#
# Reads bundle_parser's locals (bundle, btype, n, seen_bundles,
# seen_bundle_vals) via dynamic scoping; flags criticals in _parsed_bundles.
#
check_pin_branch_conflicts() {
  local key bdir bval bprev
  [[ -n "${bundle[__dir__]}" && "$btype" != using_subplugin && -z "${bundle[__error__]}" ]] || return 0
  bdir="${bundle[__dir__]}"
  for key in pin branch; do
    bval="${bundle[$key]}" bprev="${seen_bundle_vals[${bdir}:${key}]}"
    if [[ -n "${seen_bundles[$bdir]}" ]]; then
      if [[ -n "$bval" && -z "$bprev" ]] || [[ -z "$bval" && -n "$bprev" ]]; then
        _parsed_bundles[$n,__error__]="inconsistent $key for '${bundle[__bundle__]}': some entries have ${key}:${bval:-$bprev}, others do not"
        _parsed_bundles[$n,__severity__]="critical"
        _parsed_bundles[__has_critical__]=1
        _parsed_bundles[__has_errors__]=1
      elif [[ -n "$bval" && "$bprev" != "$bval" ]]; then
        _parsed_bundles[$n,__error__]="conflicting $key for '${bundle[__bundle__]}': ${key}:${bval} vs ${key}:${bprev}"
        _parsed_bundles[$n,__severity__]="critical"
        _parsed_bundles[__has_critical__]=1
        _parsed_bundles[__has_errors__]=1
      fi
    fi
    [[ -n "$bval" ]] && seen_bundle_vals[${bdir}:${key}]="$bval"
  done
  seen_bundles[$bdir]=1
}

### Parse bundle input into a matrix.
#
# Reads bundle text from stdin and populates the _parsed_bundles[i,key] global.
# Detects invalid bundles and conflicting pin/branch annotations inline.
# Sets matrix-level flags: __count__, __has_pins__, __has_errors__, __has_critical__.
#
bundle_parser() {
  local line lineno arg partno key bname btype bnameval input
  local -a args lines
  local -A bundle seen_bundles seen_bundle_vals
  local -i n=0

  typeset -gA _parsed_bundles=()
  typeset -gA _antidote_using_context

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
      (( n++ ))
      bname="$bundle[__bundle__]"

      # Handle using: directive - set the active using context.
      if [[ "$bname" == using:* ]]; then
        if ! parse_using_directive; then
          (( lineno++ ))
          continue
        fi
      fi

      # Expand word bundles using the active use context.
      bundle_type "$bname"; btype=$REPLY
      if [[ "$btype" == using_subplugin && -n "${_antidote_using_context[bundle]}" ]]; then
        expand_using_subplugin
      fi

      # Detect invalid bundles: unresolvable type or bare word with no active using: context.
      if [[ "$btype" == '?' || ( "$btype" == using_subplugin && -z "${_antidote_using_context[bundle]}" ) ]]; then
        if [[ -z "${bundle[__error__]}" ]]; then
          bundle[__error__]="invalid bundle '${bundle[__bundle__]}'"
          [[ "$btype" == using_subplugin ]] && bundle[__error__]+=". Are you missing a 'using:' directive?"
        fi
        bundle[__severity__]=error
        bundle[__type__]="$btype"
        for key in ${(k)bundle}; do
          _parsed_bundles[$n,$key]=$bundle[$key]
        done
        _parsed_bundles[__has_errors__]=1
        (( lineno++ ))
        continue
      fi

      # Compute metadata keys for repo and URL bundles
      bundle[__type__]="$btype"
      if [[ "$btype" == (repo|url|ssh_url) || ( "$btype" == using_subplugin && -n "${_antidote_using_context[bundle]}" && "${_antidote_using_context[__type__]}" == (repo|url|ssh_url) ) ]]; then
        tourl "$bname"; bundle[__url__]=$REPLY
        short_repo_name "$bname"; bundle[__short__]=$REPLY
        bundle_dir "$bname"; bundle[__dir__]=$REPLY
        bundle[__name__]=$bundle[__short__]
      else
        bnameval=${bname/#\~\//\$HOME/}
        bundle[__name__]=${bnameval/#$HOME/\$HOME}
      fi

      for key in ${(k)bundle}; do
        _parsed_bundles[$n,$key]=$bundle[$key]
      done
      [[ -n "${bundle[pin]}" ]] && _parsed_bundles[__has_pins__]=1
      if [[ -n "${bundle[__error__]}" ]]; then
        _parsed_bundles[__has_errors__]=1
        [[ -z "${_parsed_bundles[$n,__severity__]}" ]] && _parsed_bundles[$n,__severity__]=error
      fi

      # Detect pin/branch conflicts inline for non-subplugin bundles.
      check_pin_branch_conflicts
    fi
    (( lineno++ ))
  done

  _parsed_bundles[__count__]=$n
}

### Serialize the parsed bundles matrix for use in subshell/eval contexts.
bundle_parser_serialize() {
  bundle_parser
  typeset -p _parsed_bundles
}

##### INFO & USAGE

version() {
  local ver="$_ANTIDOTE_VERSION"
  local gitsha
  if [[ "$_ANTIDOTE_VERSION_SHOW_SHA" == true ]] && [[ -e "${ANTIDOTE_ZSH:h}/.git" ]]; then
    gitsha=$(git_sha "${ANTIDOTE_ZSH:h}" --short)
    [[ -z "$gitsha" ]] || ver="$ver ($gitsha)"
  fi
  say "antidote version $ver"
}

diagnostics() {
  local antidote_dir="${ANTIDOTE_ZSH:A:h}"
  local antidote_ver="$_ANTIDOTE_VERSION"
  local antidote_sha num_bundles num_snapshots zstyle_output line configfile bundlefile staticfile
  local -a bundle_dirs snapshots

  antidote_sha=$(command git -C "$antidote_dir" rev-parse --short HEAD 2>/dev/null) || antidote_sha=""
  if [[ -d "$ANTIDOTE_HOME" ]]; then
    bundle_dirs=( "$ANTIDOTE_HOME"/*(N/) )
    num_bundles=${#bundle_dirs}
  else
    num_bundles=0
  fi
  if [[ -d "$_ANTIDOTE_SNAPSHOT_DIR" ]]; then
    snapshots=( "$_ANTIDOTE_SNAPSHOT_DIR"/snapshot-*.txt(N) )
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
  say "  snapshot dir: $_ANTIDOTE_SNAPSHOT_DIR"
  say "  snapshots:    $num_snapshots"
  configfile=$ANTIDOTE_CONFIG
  if [[ -f "$configfile" ]]; then
    say "  config:       $configfile"
  else
    say "  config:       $configfile (not found)"
  fi
  bundlefile=$_ANTIDOTE_BUNDLE_FILE
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
  say "  git path:     ${commands[${_ANTIDOTE_GIT_CMD}]:-(not found)}"
  say "  git version:  $($_ANTIDOTE_GIT_CMD --version 2>&1 || say '(unknown)')"
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
  zstyle_output=$(zstyle -L ':antidote:*' 2>/dev/null)
  if [[ -n "$zstyle_output" ]]; then
    for line in "${(@f)zstyle_output}"; do
      say "  $line"
    done
  else
    say "  (none)"
  fi
}

usage() {
  say "$_ANTIDOTE_HELP"
}

##### BUNDLE TYPES & NAMING

### True when output should be colorized. NO_COLOR wins, then either force
# variable, then CLICOLOR=0, then a terminal with at least 8 colors.
# Terminals shipping their own terminfo entry can be missing from the
# system database, but those set COLORTERM.
supports_color() {
  local force=${FORCE_COLOR:-$CLICOLOR_FORCE}
  [[ -n "$NO_COLOR" ]] && return 1
  [[ -n "$force" ]] && { is_true "$force"; return }
  is_true "${CLICOLOR-1}" && [[ "$_ANTIDOTE_IS_TTY" == true ]] || return 1
  zmodload -F zsh/terminfo p:terminfo 2>/dev/null
  (( ${terminfo[colors]:-0} >= 8 )) ||
    [[ "$COLORTERM" == (truecolor|24bit) || "$TERM" == (*color*|*rxvt*) ]]
}

tourl() {
  local url=$1
  if [[ $1 != *://* && $1 != git@*:*/* ]]; then
    if [[ $_ANTIDOTE_GIT_PROTOCOL == ssh ]]; then
      url=git@${_ANTIDOTE_GIT_SITE}:$1
    else
      url=https://${_ANTIDOTE_GIT_SITE}/$1
    fi
  fi
  typeset -g REPLY=$url
}

bundle_type() {
  local bundle=$1 btype

  # Try to expand path bundles with '$' and '~' prefixes so that we get a more
  # granular result than 'path'.
  if [[ $bundle == '~/'* ]]; then
    bundle=${~bundle}
  elif [[ $bundle == '$'* ]]; then
    bundle=${(e)bundle}
  fi

  # Determine the bundle type.
  if [[ -e "$bundle" ]]; then
    [[ -f $bundle ]] && btype=file || btype=dir
  elif [[ -z "${bundle// }" ]]; then
    btype=empty
  else
    case "$bundle" in
      (/|~|'$'|'.')*)  btype=path     ;;
      *://*)           btype=url      ;;
      *@*:*/*)         btype=ssh_url  ;;
      *(:|@)*)         btype='?'      ;;
      *\ *|*$'\t'*)    btype='?'      ;;
      */*/*)           btype='?'      ;;
      */)              btype='?'      ;;
      */*)             btype=repo     ;;
      *)               btype=using_subplugin ;;
    esac
  fi
  typeset -g REPLY=$btype
}

# Convert URLs and paths to short user/repo form
short_repo_name() {
  local name
  local -a parts
  name=${1%.git}
  if [[ "$name" != git@*:*/* ]]; then
    name=${name:gs/\:/\/}
    parts=(${(ps./.)name})
    name=${parts[-2]}/${parts[-1]}
  fi
  typeset -g REPLY=$name
}

bundle_name() {
  local name
  bundle_type "$1"
  if [[ "$REPLY" == (url|ssh_url) ]] ; then
    short_repo_name "$1"
  else
    name=${1/#\~\//\$HOME/}
    typeset -g REPLY=${name/#$HOME/\$HOME}
  fi
}

##### FILESYSTEM & MISC HELPERS

initfiles() {
  local dir
  local -a found
  dir=${1:A}
  found=($dir/${dir:A:t}.plugin.zsh(N))
  [[ $#found -gt 0 ]] || found=($dir/*.plugin.zsh(N))
  [[ $#found -gt 0 ]] || found=($dir/*.zsh(N))
  [[ $#found -gt 0 ]] || found=($dir/*.sh(N))
  [[ $#found -gt 0 ]] || found=($dir/${dir:A:t}.zsh-theme(N))
  [[ $#found -gt 0 ]] || found=($dir/*.zsh-theme(N))
  typeset -ga reply=(${(u)found[@]})
  (( $#reply )) || return 1
}

get_dir() {
  local kind="$1" suffix="$2" result
  if [[ "${_ANTIDOTE_OSTYPE}" == darwin* ]]; then
    case $kind in
      cache) result=$HOME/Library/Caches ;;
      data)  result="$HOME/Library/Application Support" ;;
    esac
  elif [[ "${_ANTIDOTE_OSTYPE}" == (cygwin|msys)* ]]; then
    result=$_ANTIDOTE_LOCALAPPDATA
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

# Print the OS specific temp dir: ANTIDOTE_TMPDIR if usable, else /tmp.
temp_dir() {
  local tmpd="${ANTIDOTE_TMPDIR%/}"
  [[ -n "$tmpd" && -d "$tmpd" && -w "$tmpd" ]] || tmpd=/tmp
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
  if [[ $_ANTIDOTE_PATH_STYLE == escaped ]]; then
    typeset -g REPLY=$1
  else
    typeset -g REPLY=${1/#$HOME/\$HOME}
  fi
}

# Indent each line of input by 2 spaces.
indent() {
  local -a lines
  lines=("${(@f)$(collect_input "$@")}")
  printf '  %s\n' $lines
}

bundle_zcompile() {
  local bundle zfile
  local -a bundles
  builtin autoload -Uz zrecompile

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

##### BUNDLE DIRECTORIES

### Compute the bundle directory path for a given path-style.
#
# Unlike bundle_dir, this always computes based on the requested style
# without checking for existing directories.
#
__bundle_dir_by_style() {
  local url=$1 style=${2:-$_ANTIDOTE_PATH_STYLE} dir
  dir=$url
  case $style in
    escaped)
      dir=${dir:gs/\@/-AT-}
      dir=${dir:gs/\:/-COLON-}
      dir=${dir:gs/\//-SLASH-}
      ;;
    *)
      if [[ $dir == https://* ]]; then
        dir=${dir#https://}
      elif [[ $dir == git@*:* ]]; then
        dir=${dir#git@}
        dir=${dir:s/\:/\/}
      fi
      if [[ $style == short ]]; then
        dir=${dir#*/}
      fi
      ;;
  esac
  typeset -g REPLY=$ANTIDOTE_HOME/$dir
}

bundle_dir() {
  # Determine the bundle directory based on the configured path-style:
  #   full (default) : $ANTIDOTE_HOME/github.com/owner/repo
  #   short          : $ANTIDOTE_HOME/owner/repo
  #   escaped        : $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-owner-SLASH-repo
  #
  # If a clone already exists under a different path-style, return it rather
  # than computing a new path. No side effects - use bundle_dir_cleanup to
  # remove legacy duplicates.
  local bundle=$1
  local url preferred style dir found
  local -a other_styles=(full short escaped)
  bundle_type "$bundle"

  if [[ "$REPLY" == (repo|url|ssh_url) ]] && [[ ! -e "$bundle" ]]; then
    tourl $bundle; url=${REPLY%.git}
    __bundle_dir_by_style "$url"; preferred=$REPLY

    if [[ -d "$preferred" ]]; then
      typeset -g REPLY=$preferred
    else
      # Check other path-styles for existing clones.
      other_styles=( ${other_styles:#$_ANTIDOTE_PATH_STYLE} )
      for style in $other_styles; do
        __bundle_dir_by_style "$url" "$style"; dir=$REPLY
        if [[ -d "$dir" ]]; then
          found=$dir
          break
        fi
      done
      typeset -g REPLY=${found:-$preferred}
    fi
  elif [[ -f "$bundle" ]]; then
    typeset -g REPLY=${bundle:A:h}
  else
    typeset -g REPLY=${bundle}
  fi
}

### Remove legacy path-style duplicates for a bundle.
#
# If the preferred path exists, remove any clones under other path-styles.
# Called during bundling to clean up after a path-style migration.
#
bundle_dir_cleanup() {
  local bundle=$1 preferred=$2
  local url style dir
  local -a other_styles=(full short escaped)
  bundle_type "$bundle"

  if [[ "$REPLY" == (repo|url|ssh_url) ]] && [[ ! -e "$bundle" ]]; then
    tourl $bundle; url=${REPLY%.git}
    [[ -z "$preferred" ]] && { __bundle_dir_by_style "$url"; preferred=$REPLY }

    # Only clean up if the preferred path exists.
    [[ -d "$preferred" ]] || return 0

    other_styles=( ${other_styles:#$_ANTIDOTE_PATH_STYLE} )
    for style in $other_styles; do
      __bundle_dir_by_style "$url" "$style"; dir=$REPLY
      [[ -d "$dir" ]] && del "$dir"
    done
  fi
}

### Remove the empty directories a failed clone left behind.
#
# git deletes the clone target itself but keeps any parent directory it
# had to create, and those leftovers then look like an existing clone.
# Everything here goes through rmdir, which refuses a non-empty
# directory, so a real bundle can never be removed by mistake.
#
# Always succeeds. Pruning nothing is the normal case, and callers run as
# parallel jobs whose status becomes the bundle run's exit code.
#
clone_dir_prune() {
  local dir

  # never prune the home itself, or anything outside it
  [[ "$1" == "$ANTIDOTE_HOME"/?* ]] || return 0

  # a clone is never leftovers, and .git carries empty dirs of its own
  # (objects/info, refs/tags) that rmdir would happily take.
  [[ -e "$1/.git" ]] && return 0

  # descending name order puts children ahead of their parents
  for dir in "$1"/**/*(ND/On) "$1"; do
    [[ "$dir" == *"/.git"(|/*) ]] && continue
    rmdir "$dir" 2>/dev/null
  done
  dir=${1:h}
  while [[ "$dir" == "$ANTIDOTE_HOME"/?* ]]; do
    rmdir "$dir" 2>/dev/null || break
    dir=${dir:h}
  done
  return 0
}

##### MATRIX PASSES

### Remove legacy path-style duplicates for all bundles in the matrix.
bundle_dir_cleanup_pass() {
  local i
  for (( i = 1; i <= _parsed_bundles[__count__]; i++ )); do
    [[ "${_parsed_bundles[$i,__type__]}" == (repo|url|ssh_url) ]] || continue
    bundle_dir_cleanup "${_parsed_bundles[$i,__bundle__]}"
  done
}

### Sync pin state for all pinned repo bundles in the matrix.
#
# Only handles bundles with an active pin: annotation. The "pin removed" case
# (clearing a previously-set antidote.pin git config) is handled inside
# zsh_script so it runs in parallel across all bundles.
#
bundle_sync_pins() {
  local i bundle_path bname pin current_pin

  for (( i = 1; i <= _parsed_bundles[__count__]; i++ )); do
    [[ "${_parsed_bundles[$i,__type__]}" == (repo|url|ssh_url) ]] || continue
    pin=${_parsed_bundles[$i,pin]:-}
    [[ -n "$pin" ]] || continue
    bundle_path=${_parsed_bundles[$i,__dir__]}
    [[ -e "$bundle_path" ]] || continue

    bname=${_parsed_bundles[$i,__name__]}
    current_pin=$(git_config_get "$bundle_path" antidote.pin)
    if [[ "$current_pin" != "$pin" ]] || [[ "$(git_sha "$bundle_path")" != "$pin" ]]; then
      if ! git_checkout_pin "$bundle_path" "$pin" "$bname"; then
        return 1
      fi
      # if-form so an ephemeral pin doesn't leak status 1 from the loop
      if [[ "$ANTIDOTE_EPHEMERAL_PIN" != true ]]; then
        git_config_set "$bundle_path" antidote.pin $pin
      fi
    fi
  done
  return 0
}

### Zcompile all bundles in the matrix that have zcompile enabled.
bundle_zcompile_pass() {
  local i bundle_str bundle_path subpath kind
  for (( i = 1; i <= _parsed_bundles[__count__]; i++ )); do
    bundle_str=${_parsed_bundles[$i,__bundle__]}
    zstyle -t ":antidote:bundle:$bundle_str" zcompile || continue
    kind=${_parsed_bundles[$i,kind]:-zsh}
    # clone-only bundles: compile the whole bundle dir
    # zsh bundles: compile the bundle dir (possibly with subpath)
    # fpath/path/autoload/defer: skip
    [[ "$kind" == (fpath|path|autoload) ]] && continue
    bundle_path=${_parsed_bundles[$i,__dir__]:-$bundle_str}
    subpath=${_parsed_bundles[$i,path]:-}
    [[ -n "$subpath" ]] && bundle_path+="/$subpath"
    [[ -e "$bundle_path" ]] || continue
    bundle_zcompile $bundle_path
  done
}

### Emit critical errors from the parsed bundle matrix and return 1 if any exist.
#
bundle_check_critical() {
  local i

  if (( _parsed_bundles[__has_critical__] )); then
    for (( i = 1; i <= _parsed_bundles[__count__]; i++ )); do
      [[ "${_parsed_bundles[$i,__severity__]}" == "critical" ]] || continue
      warn "# antidote: critical error on line ${_parsed_bundles[$i,__lineno__]}: ${_parsed_bundles[$i,__error__]}"
    done
    return 1
  fi
}

##### SCRIPT GENERATION

### Generate script lines to add a dir to fpath and autoload its functions.
# usage: autoload_script <dir> <append|prepend>
autoload_script() {
  if [[ "$2" == prepend ]]; then
    typeset -ga reply=(
      "fpath=( \"$1\" \$fpath )"
      'builtin autoload -Uz $fpath[1]/*(N.:t)'
    )
  else
    typeset -ga reply=(
      "fpath+=( \"$1\" )"
      'builtin autoload -Uz $fpath[-1]/*(N.:t)'
    )
  fi
}

bundle_scripter() {
  local i key bval skip_load_defer=0 err=0
  local -a row bkeys

  if (( !${_parsed_bundles[__count__]:-0} )); then
    die "antidote: error: bundle argument expected"
  fi

  for (( i = 1; i <= _parsed_bundles[__count__]; i++ )); do
    if [[ -n "${_parsed_bundles[$i,__error__]}" ]]; then
      warn "# antidote: ${_parsed_bundles[$i,__severity__]:-error} on line ${_parsed_bundles[$i,__lineno__]}: ${_parsed_bundles[$i,__error__]}"
      err=1
      continue
    fi

    # Serialize matrix row as key-value args for zsh_script.
    # Pass __bundle__ and __type__ as the only internal keys; pass all user keys.
    bval=${_parsed_bundles[$i,__bundle__]}
    if [[ "$bval" == "${(q)bval}" || "$bval" == '~'* ]]; then
      row=(__bundle__ "$bval")
    else
      row=(__bundle__ "${(qq)bval}")
    fi
    row+=(__type__ "${_parsed_bundles[$i,__type__]}")
    bkeys=(${${(k)_parsed_bundles[(I)$i,^__*]}#$i,})
    for key in ${(o)bkeys}; do
      bval=${_parsed_bundles[$i,$key]}
      if [[ "$bval" == "${(q)bval}" ]]; then
        row+=("$key" "$bval")
      else
        row+=("$key" "${(qq)bval}")
      fi
    done

    # Track defers: inject __skip_load_defer__ for 2nd+ defer bundles
    if [[ "${_parsed_bundles[$i,kind]}" == defer ]]; then
      if (( skip_load_defer == 0 )); then
        skip_load_defer=1
      else
        row+=(__skip_load_defer__ 1)
      fi
    fi

    printf 'zsh_script'
    printf ' %s' "${row[@]}"
    printf '\n'
  done
  return $err
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

  # Track each job's pid so `wait $pid` can recover its exit status;
  # a bare `wait` would lose script failures like a bad kind value.
  printf 'local -a __pids\nlocal __pid __err=0\n'
  while IFS= read -r line; do
    (( n++ ))
    printf '%s > "%s"/%03d &\n' "$line" "$par_dir" $n
    printf '__pids+=($!)\n'
  done < <(bundle_scripter "$@")

  if (( n > 0 )); then
    printf 'for __pid in $__pids; do wait $__pid || __err=1; done\n'
    printf 'cat "%s"/*\n' "$par_dir"
    printf 'rm -rf "%s"\n' "$par_dir"
    printf 'return $__err\n'
  fi
}

### Clone a repo bundle if missing, and sync removed pins.
#
# Reads zsh_script's locals (btype, bundle, bundle_str, bundle_path,
# bname, pin, branch, min_age) via dynamic scoping.
#
zsh_script_clone() {
  local giturl unpin_branch
  local -a branch_flag

  [[ "$btype" == (repo|url|ssh_url) ]] || return 0

  # An older failed clone can leave empty dirs that pass the check below.
  if [[ -d "$bundle_path" && ! -e "$bundle_path/.git" ]]; then
    clone_dir_prune "$bundle_path"
  fi

  # handle cloning repo bundles
  if [[ ! -e "$bundle_path" ]]; then
    giturl=${bundle[__url__]:-}
    [[ -z "$giturl" ]] && { tourl $bundle_str; giturl=$REPLY }
    warn "# antidote cloning $bname..."
    if [[ -n "$pin" ]]; then
      git_clone $bundle_path $giturl || { clone_dir_prune $bundle_path; return 1 }
      if ! git_checkout_pin "$bundle_path" "$pin" "$bname"; then
        del "$bundle_path"
        clone_dir_prune "$bundle_path"
        return 1
      fi
      [[ "$ANTIDOTE_EPHEMERAL_PIN" != true ]] && git_config_set "$bundle_path" antidote.pin $pin
    else
      branch_flag=()
      [[ -n "$branch" ]] && branch_flag=(-b "$branch")
      git_clone $bundle_path "${branch_flag[@]}" $giturl || { clone_dir_prune $bundle_path; return 1 }
      if (( min_age )); then
        git_min_age_reset "$bundle_path" "$min_age" "$bname" || return 1
      elif ! zstyle -t ":antidote:bundle:$bname" shallow; then
        # Disowned so the clone returns immediately. Tests run it in the
        # foreground instead, since nothing can wait on a disowned job.
        if [[ "$_ANTIDOTE_GIT_BG_DEEPEN" == true ]]; then
          git_unshallow_try "$bundle_path" </dev/null >/dev/null 2>&1 &!
        else
          git_unshallow_try "$bundle_path"
        fi
      fi
    fi
  fi

  # Pin removed - clear config and return to branch so update can pull.
  # Runs here (in parallel) rather than bundle_sync_pins to avoid sequential git calls.
  if [[ -e "$bundle_path" ]] && [[ -z "$pin" ]]; then
    if [[ -n "$(git_config_get "$bundle_path" antidote.pin)" ]]; then
      git_config_unset "$bundle_path" antidote.pin
      unpin_branch="$branch"
      if [[ -z "$unpin_branch" ]]; then
        unpin_branch=$(gitsay -C "$bundle_path" rev-parse --abbrev-ref origin/HEAD 2>/dev/null)
        unpin_branch=${unpin_branch#origin/}
      fi
      [[ -n "$unpin_branch" ]] && gits -C "$bundle_path" checkout --quiet "$unpin_branch" 2>/dev/null
    fi
  fi
  return 0
}

### Print the load script for a bundle after any cloning is done.
#
# Reads zsh_script's locals (kind, subpath, cond, autoload_path, pre, post,
# fpath_rule, skip_load_defer, bundle_str, bundle_path, btype, bname) via
# dynamic scoping.
#
zsh_script_render() {
  local dopts zsh_defer source_cmd
  local print_bundle_path initfile print_initfile fpath_script
  local -a script

  # add path to bundle
  [[ -n "$subpath" ]] && typeset -g bundle_path="$bundle_path/$subpath"

  # add pre-load function
  [[ -n "$pre" ]] && script+=("$pre")

  # handle defers
  source_cmd="source"
  if [[ "$kind" == defer ]]; then
    zsh_defer='zsh-defer'
    zstyle -s ":antidote:bundle:${bundle_str}" defer-options 'dopts'
    [[ -n "$dopts" ]] && zsh_defer="zsh-defer $dopts"
    source_cmd="${zsh_defer} source"
    if (( !skip_load_defer )); then
      script+=(
        'if ! (( $+functions[zsh-defer] )); then'
        "$(zsh_script __bundle__ $_ANTIDOTE_DEFER_BUNDLE | indent)"
        'fi'
      )
    fi
  fi

  # Let's make the path a little nicer to deal with
  print_path "$bundle_path"; print_bundle_path=$REPLY

  # handle autoloading before sourcing
  if [[ -n "$autoload_path" ]]; then
    autoload_script "${print_bundle_path}/${autoload_path}" "$fpath_rule"
    script+=("${reply[@]}")
  fi

  # generate load script - recheck type since path may have been appended
  if [[ "$btype" != file ]] && [[ -f "$bundle_path" ]]; then
    typeset -g btype=file
  fi
  if [[ "$fpath_rule" == prepend ]]; then
    fpath_script="fpath=( \"$print_bundle_path\" \$fpath )"
  else
    fpath_script="fpath+=( \"$print_bundle_path\" )"
  fi

  case "$kind" in
    fpath)
      script+="$fpath_script"
      ;;
    path)
      script+="export PATH=\"$print_bundle_path:\$PATH\""
      ;;
    autoload)
      autoload_script "$print_bundle_path" "$fpath_rule"
      script+=("${reply[@]}")
      ;;
    *)
      if [[ $btype == file ]]; then
        script+="$source_cmd \"$print_bundle_path\""
      else
        # directory/default
        initfiles $bundle_path
        # if no init file was found, assume the default
        if [[ $#reply -eq 0 ]]; then
          if [[ -n "$subpath" ]]; then
            typeset -ga reply=($bundle_path/${bundle_path:t}.plugin.zsh)
          else
            typeset -ga reply=($bundle_path/${bname:t}.plugin.zsh)
          fi
        fi
        script+="$fpath_script"
        for initfile in $reply; do
          print_path "$initfile"; print_initfile=$REPLY
          script+="$source_cmd \"$print_initfile\""
        done
      fi
      ;;
  esac

  # add post-load function
  if [[ -n "$post" ]]; then
    if [[ "$kind" == defer ]]; then
      script+=("${zsh_defer} $post")
    else
      script+=("$post")
    fi
  fi

  # wrap conditional
  if [[ -n "$cond" ]]; then
    print "if $cond; then"
    # (F)join + (@f)split flattens multiline elements so each line gets indented
    printf "  %s\n" "${(@f)${(F)script}}"
    print "fi"
  else
    printf "%s\n" $script
  fi
}

### Generate the Zsh script to load a plugin.
#
# usage: zsh_script __bundle__ <bundle> [key value ...]
# Accepts a flat key-value list (assoc array pairs) describing the bundle.
# Keys: __bundle__, kind, path, branch, pin, conditional, autoload, pre,
#       post, fpath-rule, __skip_load_defer__, __type__, __dir__
# <kind> : zsh,path,fpath,defer,clone,autoload
#
zsh_script() {
  local bundle_str bname bundle_path btype min_age
  local kind subpath branch pin cond autoload_path pre post fpath_rule skip_load_defer
  local -A bundle

  # Reconstruct assoc array from flat key-value arg list
  bundle=("$@")

  bundle_str=${bundle[__bundle__]}
  if [[ -z "$bundle_str" ]]; then
    warn "antidote: error: bundle argument expected"
    return 1
  fi

  # Extract fields with defaults
  kind=${bundle[kind]:-zsh}
  subpath=${bundle[path]:-}
  branch=${bundle[branch]:-}
  pin=${bundle[pin]:-}
  cond=${bundle[conditional]:-}
  autoload_path=${bundle[autoload]:-}
  pre=${bundle[pre]:-}
  post=${bundle[post]:-}
  fpath_rule=${bundle[fpath-rule]:-$_ANTIDOTE_FPATH_RULE}
  skip_load_defer=${bundle[__skip_load_defer__]:-0}

  if [[ "$kind" != (autoload|clone|defer|fpath|path|zsh) ]]; then
    warn "antidote: error: unexpected kind value: '$kind'"
    return 1
  fi

  if [[ "$fpath_rule" != (append|prepend) ]]; then
    warn "antidote: error: unexpected fpath rule: '$fpath_rule'"
    return 1
  fi

  # Use pre-computed type from matrix if available, otherwise compute
  if [[ -n "${bundle[__type__]}" ]]; then
    btype=${bundle[__type__]}
  else
    bundle_type $bundle_str; btype=$REPLY
  fi
  if [[ -n "${bundle[__name__]}" ]]; then
    bname=${bundle[__name__]}
  else
    bundle_name $bundle_str; bname=$REPLY
  fi

  # Fail before any cloning happens on a bad min-age value.
  min_age_days "$bname" || return 1
  min_age=$REPLY

  # replace ~/ with $HOME/
  if [[ "$bundle_str" == '~/'* ]]; then
    bundle_str=${~bundle_str}
  fi

  # set the path to the bundle (repo or local)
  if [[ -e "$bundle_str" ]]; then
    bundle_path=$bundle_str
  elif [[ "$btype" == (repo|url|ssh_url|using_subplugin) ]]; then
    if [[ -n "${bundle[__dir__]}" ]]; then
      bundle_path=${bundle[__dir__]}
    else
      bundle_dir $bundle_str; bundle_path=$REPLY
    fi
  else
    bundle_path=$bundle_str
  fi
  if [[ -n "$pin" ]] && [[ "$btype" == (repo|url|ssh_url) ]]; then
    if (( $#pin != 40 )) || [[ "$pin" != [0-9a-f](#c40) ]]; then
      warn "antidote: error: pin requires a full 40-character commit SHA, got '$pin'"
      return 1
    fi
  fi

  # clone if needed, then emit the load script
  zsh_script_clone || return 1
  [[ "$kind" == clone ]] && return 0
  zsh_script_render
}

##### COMMANDS

### Clone bundle(s) and generate the static load script.
#
# usage: antidote bundle [-h|--help] <bundle>...
#
antidote_bundle() {
  local o_help bundle_output err=0 i
  local -a zcompile_script

  # Ensure all stderr from this function starts with '#' so redirected bundle
  # output is safe to source.
  exec 2> >(local line; while IFS= read -r line; do
    [[ "$line" == '#'* ]] || line="# $line"
    print -r -- "$line" >&2
  done)

  zparseopts ${ZPARSEOPTS} -- h=o_help -help=h || return 1

  if (( $#o_help )); then
    usage
    return
  fi

  # Parse all bundles once into the matrix
  bundle_parser < <(collect_input "$@")
  (( _parsed_bundles[__has_errors__] )) && err=1
  if ! (( _parsed_bundles[__count__] )); then
    # A pure using: directive (path-based) produces no bundle entries but does
    # update the context - emit it in dynamic mode so the parent shell sees it.
    if [[ "$ANTIDOTE_DYNAMIC" == true && ${#_antidote_using_context} -gt 0 ]]; then
      typeset -p _antidote_using_context
      return 0
    fi
    return 1
  fi

  # Bail on critical errors (conflicting/inconsistent pins or branches).
  bundle_check_critical || return 1

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
  # Clone all missing repos in parallel, sync pins, zcompile
  if (( _parsed_bundles[__count__] > 1 )); then
    source <(bulk_clone)
  fi
  (( _parsed_bundles[__has_pins__] )) && { bundle_sync_pins || return 1 }
  bundle_zcompile_pass

  # generate bundle script in parallel - zsh_script still handles clone
  # fallback. Script failures (bad kind, bad pin) flag the whole bundle
  # run as failed, but valid bundles still produce output.
  bundle_output=$(source <(bundle_scripter_parallel)) || err=1

  # clean up legacy path-style dirs after cloning is complete
  bundle_dir_cleanup_pass

  # Clone failures happen in backgrounded scripts whose status is lost, so
  # detect them here: every repo bundle must exist on disk after bundling.
  for (( i = 1; i <= _parsed_bundles[__count__]; i++ )); do
    [[ "${_parsed_bundles[$i,__type__]}" == (repo|url|ssh_url) ]] || continue
    [[ -e "${_parsed_bundles[$i,__dir__]}" ]] || err=1
  done

  # output static file compilation
  if zstyle -t ':antidote:static' zcompile; then
    printf '%s\n' $zcompile_script
  fi
  # No output is fine (eg clone-only bundles); only a failed print is an error.
  if [[ -n "$bundle_output" ]]; then
    printf '%s\n' "$bundle_output" || err=$?
  fi

  # In dynamic mode, emit the use context so the parent shell can source it
  # and pass it back into the next subprocess call via ANTIDOTE_USING_CTX.
  if [[ "$ANTIDOTE_DYNAMIC" == true && ${#_antidote_using_context} -gt 0 ]]; then
    typeset -p _antidote_using_context
  fi
  return $err
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
      -*)
        [[ -n "${flag_to_annotation[$arg]}" ]] ||
          die "antidote: error: unknown flag '$arg', try --help"
        annotations+=( $flag_to_annotation[$arg]:$2 ); shift
      ;;
      *)    break  ;;
    esac
    shift
  done

  if [[ $# -eq 0 ]]; then
    die "antidote: error: required argument 'bundle' not provided, try --help"
  fi

  bundle=$1
  bundlefile=${2:-$_ANTIDOTE_BUNDLE_FILE}

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
  local o_help o_all i line
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

  bundlefile=$_ANTIDOTE_BUNDLE_FILE

  if (( $#o_all )); then
    # last chance to save the user from themselves
    confirm ':antidote:test:purge' \
      "You are about to permanently remove '$ANTIDOTE_HOME' and all its contents!${NL}Are you sure [Y/n]? " ||
      return 1

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
      if confirm ':antidote:test:purge' \
        "You are about to remove '${bundlefile:t:r}.zsh'"$'\n'"Are you sure [Y/n]? "; then
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

    # invalidate the dynamic-mode script cache so purged bundles reclone
    [[ -d "$ANTIDOTE_HOME/.dynamic" ]] && del "$ANTIDOTE_HOME/.dynamic"

    # attempt to comment out the bundle from .zsh_plugins.txt
    if [[ -e "$bundlefile" ]]; then
      lines=( "${(@f)"$(<$bundlefile)"}" )
      for (( i=1; i<=$#lines; i++ )); do
        # Match the bundle literally (not as a pattern), whole word only, so
        # purging foo/bar leaves foo/barbaz alone.
        line=${lines[$i]##[[:blank:]]#}
        if [[ "$line" == "$bundle" || "$line" == "$bundle"[[:blank:]]* ]]; then
          lines[$i]="# $lines[$i]"
        fi
      done
      printf '%s\n' "${lines[@]}" > "$bundlefile"
      say "Bundle '$bundle' was commented out in '$bundlefile'."
    fi
  fi
}

### Fetch/pull one bundle and write its report to a tmpfile.
#
# usage: update_one_bundle <bundledir> <repo> <slot>
# Run in the background by antidote_update; reads its locals (tmpdir,
# o_dry_run, _C_* colors) via dynamic scoping. <slot> is a unique index so
# repos that share a short name never overwrite each other's files.
# Always writes the worker exit status to a .status file for aggregation.
#
update_one_bundle() {
  local bundledir="$1" repo="$2" slot="$3"
  local tmpfile statusfile oldsha newsha min_age min_age_sha upstream_ref rc=0

  tmpfile="${tmpdir}/${slot}.output"
  statusfile="${tmpdir}/${slot}.status"
  oldsha=$(git_sha "$bundledir")

  min_age_days "$repo" || rc=1
  min_age=$REPLY

  # The clone's background deepen is best effort, so pick up anything
  # still shallow. Not for a bundle held shallow on purpose, and never
  # on a dry run, where deepening would be a side effect. Deepening is
  # opportunistic: a background job may still hold shallow.lock, which
  # is not an update failure, so fall back to a plain fetch.
  if (( rc == 0 )); then
    if ! (( $#o_dry_run )) && ! zstyle -t ":antidote:bundle:$repo" shallow \
       && git_is_shallow "$bundledir"; then
      git_unshallow_try "$bundledir" || git_fetch "$bundledir" || rc=1
    else
      git_fetch "$bundledir" || rc=1
    fi
  fi

  # Compare and rebase against this, never FETCH_HEAD. A clone with no
  # remote-tracking branch at all, eg a branch: naming a tag, has nothing
  # to update to, which is a skip and not a failure.
  if (( rc == 0 )); then
    upstream_ref=$(git_upstream_ref "$bundledir") || {
      print -r -- 0 > "$statusfile"
      return 0
    }
  fi

  # With min-age set, advance no further than the newest commit that has
  # sat upstream long enough.
  if (( rc == 0 && min_age )); then
    min_age_sha=$(git_min_age_sha "$bundledir" "$min_age" "$upstream_ref")
    if [[ -z "$min_age_sha" ]]; then
      warn "antidote: $repo: no commits older than $min_age days, skipping update"
      # Skipping is a success, so say so: the parent treats a missing
      # status file as a failed worker.
      print -r -- 0 > "$statusfile"
      return 0
    fi
  fi

  if (( rc == 0 )); then
    if (( $#o_dry_run )); then
      # Compare local HEAD against fetched remote HEAD
      if (( min_age )); then
        newsha=$min_age_sha
      else
        newsha=$(gitsay -C "$bundledir" rev-parse "$upstream_ref" 2>/dev/null) || newsha=$oldsha
      fi
    else
      if (( min_age )); then
        git_merge_ffonly "$bundledir" "$min_age_sha" || rc=1
      elif git_is_shallow "$bundledir" &&
           ! git_is_ancestor "$bundledir" HEAD "$upstream_ref"; then
        # A shallow graft can hide the shared history, and a rebase then
        # replays commits that are already upstream and conflicts.
        git_reset_to "$bundledir" "$upstream_ref" "$repo" || rc=1
      else
        git_rebase "$bundledir" "$upstream_ref" || rc=1
      fi
      if (( rc == 0 )) && git_submodule_sync "$bundledir" && git_submodule_update "$bundledir"; then
        newsha=$(git_sha "$bundledir")
      else
        rc=1
      fi
    fi
  fi

  # Capture all report output to temporary file
  if (( rc == 0 )); then
    {
      if [[ $oldsha != $newsha ]]; then
        if (( $#o_dry_run )); then
          say "${fg[yellow]}antidote:${reset_color} update available: $repo ${fg[green]}${oldsha[1,7]}${reset_color} -> ${fg[green]}${newsha[1,7]}${reset_color}"
        else
          say "${fg[green]}antidote:${reset_color} updated: $repo ${fg[green]}${oldsha[1,7]}${reset_color} -> ${fg[green]}${newsha[1,7]}${reset_color}"
        fi
        git_log_oneline "$bundledir" "$oldsha" "$newsha"
      fi

      # recompile bundles
      if ! (( $#o_dry_run )); then
        if zstyle -t ":antidote:bundle:$repo" zcompile; then
          bundle_zcompile $bundledir
        fi
      fi
    } > "$tmpfile" 2>&1
  fi

  # The .status file is the only failure signal the parent reads; bare
  # wait discards the worker's own exit status.
  print -r -- $rc > "$statusfile"
}

### Update antidote's cloned bundles.
#
# usage: antidote update [-h|--help] [-n|--dry-run]
#
antidote_update() {
  setup_color
  local o_help o_dry_run
  local tmpfile tmpdir bundledir url repo pin_ref
  local line loadable_check_path slot report_repo statusfile
  local -a worker_repos failed_repos

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

    # invalidate the dynamic-mode script cache; bundle contents change
    [[ -d "$ANTIDOTE_HOME/.dynamic" ]] && del "$ANTIDOTE_HOME/.dynamic"
  fi

  # Setup temporary directory
  tmpdir=$(maketmp -d -s update)

  # Set trap to ensure cleanup on exit, interrupt, etc.
  # (EXIT is special, 2=INT, 15=TERM, 1=HUP)
  # The path is expanded now, not at trap time: zsh tears down function
  # locals before running an EXIT trap, so $tmpdir would be empty there.
  trap "[[ -d ${(q)tmpdir} ]] && del ${(q)tmpdir}" EXIT 2 15 1

  # update all bundles
  for bundledir in $(antidote_list --dirs); do
    url=$(git_url "$bundledir")
    short_repo_name "$url"; repo=$REPLY

    # Skip pinned bundles
    pin_ref=$(git_config_get "$bundledir" antidote.pin)
    if [[ -n "$pin_ref" ]]; then
      say "${fg[blue]}antidote:${reset_color} skipping update for pinned bundle: $repo (at ${fg[green]}${pin_ref[1,7]}...${reset_color})"
      continue
    fi

    say "${fg[blue]}antidote:${reset_color} checking for updates: $repo"
    worker_repos+=("$repo")
    update_one_bundle "$bundledir" "$repo" $#worker_repos &
  done

  say "Waiting for bundle updates to complete..."
  say ""
  wait

  # Display each worker's report and aggregate its exit status. Iterate by
  # slot so the repo name is known even when reports collide by short name.
  for slot in {1..$#worker_repos}; do
    tmpfile="$tmpdir/$slot.output"
    report_repo=$worker_repos[$slot]

    if [[ -s "$tmpfile" ]]; then
      say "${fg[blue]}Bundle ${report_repo} update check complete.${reset_color}"

      # Colorize the SHA in each line
      while IFS= read -r line; do
        if [[ -n "$line" ]] && [[ "$line" == [[:alnum:]]* ]]; then
          say "${fg[yellow]}${line%% *}${reset_color} ${line#* }"
        else
          say "$line"
        fi
      done < "$tmpfile"
      say ""
    fi

    # A missing or empty status file means the worker died before it could
    # report, so fail closed rather than scoring it a success.
    statusfile="$tmpdir/$slot.status"
    if [[ ! -s "$statusfile" ]] || [[ "$(<"$statusfile")" != 0 ]]; then
      failed_repos+=("$report_repo")
    fi
  done

  # A failed worker must not report success or trigger an autosnapshot.
  if (( $#failed_repos )); then
    for report_repo in $failed_repos; do
      say "${fg[red]}antidote:${reset_color} update failed for '$report_repo'"
    done
    say ""
    return 1
  fi

  if (( $#o_dry_run )); then
    say "${fg[green]}Dry run complete. No changes were made.${reset_color}"
  else
    say "${fg[green]}Bundle updates complete.${reset_color}"
    [[ "$_ANTIDOTE_AUTOSNAPSHOT" == true ]] && snapshot_save >/dev/null
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
  local script
  # Bake the resolved home and config paths into the emitted function so
  # the parent shell never needs a subprocess to find the bundle cache.
  script=$_ANTIDOTE_INIT_SCRIPT
  script=${script//@ANTIDOTE_HOME@/${(qq)ANTIDOTE_HOME}}
  script=${script//@ANTIDOTE_CONFIG@/${(qq)ANTIDOTE_CONFIG}}
  say "$script"
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

  local bundledir url repo sha pin_ref jurl jrepo jpath
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
    short_repo_name "$url"; repo=$REPLY

    if (( $#o_jsonl )); then
      sha=$(git_sha "$bundledir")
      pin_ref=$(git_config_get "$bundledir" antidote.pin)
      json_escape "$url";       jurl=$REPLY
      json_escape "$repo";      jrepo=$REPLY
      json_escape "$bundledir"; jpath=$REPLY
      if [[ -n "$pin_ref" ]]; then
        json_escape "$pin_ref"
        printf '{"url":"%s","repo":"%s","path":"%s","sha":"%s","pin":"%s"}\n' \
          "$jurl" "$jrepo" "$jpath" "$sha" "$REPLY"
      else
        printf '{"url":"%s","repo":"%s","path":"%s","sha":"%s"}\n' \
          "$jurl" "$jrepo" "$jpath" "$sha"
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

##### SNAPSHOTS

### Save, restore, or list snapshots of cloned bundle state.
#
# usage: antidote snapshot [home|list|remove|restore|save] [<file>]
#
antidote_snapshot() {
  setup_color
  local o_help subcmd
  zparseopts ${ZPARSEOPTS} -- h=o_help -help=h || return 1

  if (( $#o_help )); then
    say "usage: antidote snapshot [home|list|remove|restore|save] [<file>]"
    return
  fi

  subcmd=${1:-list}; shift 2>/dev/null

  case "$subcmd" in
    home)    echo "$_ANTIDOTE_SNAPSHOT_DIR" ;;
    list)    snapshot_list                 ;;
    remove)  snapshot_remove "$@"          ;;
    restore) snapshot_restore "$@"         ;;
    save)    snapshot_save "$@"            ;;
    *)       die "antidote: snapshot: unknown subcommand '$subcmd'" ;;
  esac
}

### Write a snapshot of all cloned bundles to a timestamped file.
snapshot_save() {
  local bundledir url sha repo snapshot_file epoch
  local -a bundles bundle_lines

  [[ "$ANTIDOTE_DYNAMIC" == true ]] && return 0

  [[ -d "$_ANTIDOTE_SNAPSHOT_DIR" ]] || mkdir -p "$_ANTIDOTE_SNAPSHOT_DIR"

  zstyle -s ':antidote:test:snapshot' epoch epoch || epoch=$EPOCHSECONDS
  snapshot_file=${1:-$_ANTIDOTE_SNAPSHOT_DIR/snapshot-$(TZ=UTC strftime '%Y%m%d-%H%M%SZ' $epoch).txt}

  bundles=(${(f)"$(find_bundles)"})

  for bundledir in "${bundles[@]}"; do
    url=$(git_url "$bundledir") || continue
    sha=$(git_sha "$bundledir")
    short_repo_name "$url"; repo=$REPLY

    bundle_lines+=("$repo kind:clone pin:$sha")
  done

  {
    print "# antidote snapshot"
    print "# version: $_ANTIDOTE_VERSION"
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
  snapshots=($_ANTIDOTE_SNAPSHOT_DIR/snapshot-*.txt(N))
  if (( $#snapshots > _ANTIDOTE_SNAPSHOT_MAX )); then
    to_remove=(${(o)snapshots[1,$(( $#snapshots - _ANTIDOTE_SNAPSHOT_MAX ))]})
    del $to_remove
  fi
}

### Set color-related globals needed for interactive features (fzf previews, etc).
#
# Callers interpolate ${fg[...]} and ${reset_color} unconditionally, so
# when color is off both have to exist and expand to nothing. Blanking
# them also means an exported reset_color cannot force color on.
#
setup_color() {
  typeset -g _ANTIDOTE_COLOR=''
  if supports_color; then
    typeset -g _ANTIDOTE_COLOR=true
    autoload -Uz colors && colors
  else
    typeset -gA fg=()
    typeset -g reset_color=''
  fi
}

### Detect bat for snapshot preview highlighting.
setup_bat() {
  typeset -g _ANTIDOTE_BAT_CMD='' _ANTIDOTE_BAT_LANG=''
  [[ "$_ANTIDOTE_COLOR" == true ]] && command -v bat >/dev/null 2>&1 || return 0
  typeset -g _ANTIDOTE_BAT_CMD=bat
  if bat --list-languages 2>/dev/null | grep -q 'Antidote Bundle'; then
    typeset -g _ANTIDOTE_BAT_LANG='Antidote Bundle'
  else
    typeset -g _ANTIDOTE_BAT_LANG=properties
  fi
  # Unlike every other setting, this default cannot move to the init block:
  # it names the language, and detecting that costs a bat subprocess that
  # every antidote run would then pay for. Assign folded so the test suite's
  # warn_nested_var stays quiet.
  [[ -n "$_ANTIDOTE_BAT_OPTS" ]] ||
    typeset -g _ANTIDOTE_BAT_OPTS="--color=always -l '${_ANTIDOTE_BAT_LANG}'"
}

### Check for an fzf picker, warning and returning 1 if unavailable.
snapshot_try_picker() {
  local -a fzf_cmd
  fzf_cmd=(${(z)_ANTIDOTE_FZF_CMD})
  if (( ${#fzf_cmd} == 0 )) || ! command -v -- "${fzf_cmd[1]}" >/dev/null 2>&1; then
    warn "antidote: snapshot: no snapshot file specified (use 'antidote snapshot list' to see available snapshots)"
    return 1
  fi
}

### Interactive fzf snapshot picker. Prints selected file path(s) to stdout.
# Usage: snapshot_pick "label" [--multi]
snapshot_pick() {
  setopt localoptions pipefail
  local label="$1" snap date_line epoch preview_cmd
  local -a snapshots labels fzf_opts fzf_cmd

  setup_bat
  snapshots=($_ANTIDOTE_SNAPSHOT_DIR/snapshot-*.txt(NOn))
  if (( $#snapshots == 0 )); then
    warn "antidote: snapshot: no snapshots found"
    return 1
  fi

  fzf_cmd=(${(z)_ANTIDOTE_FZF_CMD})
  preview_cmd='echo {2}; echo; tail -n +4 {2}'
  if [[ -n "$_ANTIDOTE_BAT_CMD" ]]; then
    preview_cmd="BAT_OPTS=${(q)_ANTIDOTE_BAT_OPTS} bat {2}"
  elif [[ "$_ANTIDOTE_COLOR" == true ]]; then
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
      date_line=$(strftime "$_ANTIDOTE_SNAPSHOT_DATEFMT" $epoch)
    fi
    labels+=("$date_line	$snap")
  done

  fzf_opts=(--no-sort ${_ANTIDOTE_COLOR:+--ansi} --with-nth=1 --delimiter=$'\t'
    --prompt="❯ " --border-label=" $label " --preview="$preview_cmd")
  if [[ "$2" == --multi ]]; then
    fzf_opts+=(--multi --marker='* ' --color='marker:red')
  fi

  printf '%s\n' $labels \
    | FZF_DEFAULT_OPTS=$_ANTIDOTE_FZF_OPTS \
      FZF_DEFAULT_OPTS_FILE=$_ANTIDOTE_FZF_OPTS_FILE \
      "${fzf_cmd[@]}" $fzf_opts \
    | cut -f2 \
    || { warn "antidote: snapshot: no snapshot selected"; return 1; }
}

### Restore bundles from a snapshot file.
snapshot_restore() {
  local snapshot_file="$1"
  local line bundle pin i err=0
  local -a pids bundles

  if [[ -z "$snapshot_file" ]]; then
    snapshot_try_picker || return 1
    snapshot_file=$(snapshot_pick "Select snapshot to restore") || return 1
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
    say "${fg[blue]}antidote:${reset_color} restoring $bundle (${fg[green]}${pin[1,7]}...${reset_color})"
    ANTIDOTE_EPHEMERAL_PIN=true antidote_bundle "$line" &>/dev/null &
    pids+=($!)
    bundles+=("$bundle")
  done <"$snapshot_file"

  for (( i = 1; i <= $#pids; i++ )); do
    if ! wait ${pids[$i]}; then
      warn "antidote: snapshot: restore failed for '${bundles[$i]}'"
      err=1
    fi
  done

  if (( err )); then
    warn "Restore completed with errors."
    return 1
  fi
  say "${fg[green]}Restore complete.${reset_color}"
}

### List available snapshots.
snapshot_list() {
  local -a snapshots
  snapshots=($_ANTIDOTE_SNAPSHOT_DIR/snapshot-*.txt(N))
  if (( $#snapshots == 0 )); then
    say "No snapshots found."
    return
  fi
  printf '%s\n' ${(O)snapshots}
}

### Remove snapshots.
snapshot_remove() {
  local snap
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

  snapshot_try_picker || return 1
  selected=("${(@f)$(snapshot_pick "Select snapshot(s) to remove" --multi)}") \
    || return 1

  say "Snapshots to remove:"
  for snap in $selected; do
    say "  $snap"
  done

  if ! confirm ':antidote:test:snapshot:remove' \
    "Are you sure you want to remove ${#selected} snapshot(s) [Y/n]? "; then
    say "Cancelled."
    return 1
  fi

  for snap in $selected; do
    del "$snap"
    say "Removed: $snap"
  done
}

##### DISPATCH

### Dispatcher for antidote __private__ commands (used in tests and internals).
#
# Parses stdin into the bundle matrix for commands that need it, and prints
# REPLY/reply for commands that return via those vars.
#
private_dispatcher() {
  local cmd err
  cmd="$1"; shift
  typeset -g REPLY=
  case $cmd in
    bundle_check_critical|bundle_scripter|zsh_script)
      bundle_parser < <(collect_input "$@")
      ;;
  esac
  "${cmd}" "$@"
  err=$?
  case $cmd in
    tourl|bundle_type|short_repo_name|bundle_name|bundle_dir|__bundle_dir_by_style|print_path)
      say "$REPLY"
      ;;
    initfiles)
      (( $#reply )) && printf '%s\n' "${reply[@]}"
      ;;
  esac
  return $err
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
    private_dispatcher "$@"
    return $?
  elif (( $+functions[antidote_${cmd}] )); then
    "antidote_${cmd}" "$@"
    return $?
  else
    die "antidote: command not found '${cmd}'"
  fi
}

##### INITIALIZATION

# Initialize antidote global variables from zstyles and environment.
{
  typeset -g ANTIDOTE_ZSH="${0:a}"
  typeset -g _ANTIDOTE_VERSION="2.2.1"
  typeset -g ANTIDOTE_TMPDIR=${ANTIDOTE_TMPDIR:-$TMPDIR}

  typeset -g _ANTIDOTE_GIT_SITE _ANTIDOTE_GIT_PROTOCOL _ANTIDOTE_GIT_CMD _ANTIDOTE_FZF_CMD _ANTIDOTE_PATH_STYLE
  typeset -g _ANTIDOTE_FZF_OPTS _ANTIDOTE_FZF_OPTS_FILE _ANTIDOTE_BAT_OPTS
  typeset -g _ANTIDOTE_DEFER_BUNDLE _ANTIDOTE_FPATH_RULE _ANTIDOTE_BUNDLE_FILE
  typeset -g _ANTIDOTE_OSTYPE _ANTIDOTE_LOCALAPPDATA
  typeset -g _ANTIDOTE_VERSION_SHOW_SHA=true _ANTIDOTE_GIT_AUTOSTASH=true
  typeset -g _ANTIDOTE_GIT_BG_DEEPEN=true _ANTIDOTE_IS_TTY=true
  zstyle -s ':antidote:bat'    opts       _ANTIDOTE_BAT_OPTS
  zstyle -s ':antidote:bundle' file       _ANTIDOTE_BUNDLE_FILE          || _ANTIDOTE_BUNDLE_FILE=${ZDOTDIR:-$HOME}/.zsh_plugins.txt
  zstyle -s ':antidote:bundle' path-style _ANTIDOTE_PATH_STYLE           || _ANTIDOTE_PATH_STYLE=full
  zstyle -s ':antidote:defer'  bundle     _ANTIDOTE_DEFER_BUNDLE         || _ANTIDOTE_DEFER_BUNDLE=romkatv/zsh-defer
  zstyle -s ':antidote:fpath'  rule       _ANTIDOTE_FPATH_RULE           || _ANTIDOTE_FPATH_RULE=append
  zstyle -s ':antidote:fzf'    cmd        _ANTIDOTE_FZF_CMD              || _ANTIDOTE_FZF_CMD=fzf
  zstyle -s ':antidote:fzf'    opts       _ANTIDOTE_FZF_OPTS             || _ANTIDOTE_FZF_OPTS=${FZF_DEFAULT_OPTS:-"--border=top --preview-window=right:75%"}
  zstyle -s ':antidote:fzf'    opts_file  _ANTIDOTE_FZF_OPTS_FILE        || _ANTIDOTE_FZF_OPTS_FILE=$FZF_DEFAULT_OPTS_FILE
  zstyle -s ':antidote:git'    cmd        _ANTIDOTE_GIT_CMD              || _ANTIDOTE_GIT_CMD=git
  zstyle -s ':antidote:git'    protocol   _ANTIDOTE_GIT_PROTOCOL         || _ANTIDOTE_GIT_PROTOCOL=https
  zstyle -s ':antidote:git'    site       _ANTIDOTE_GIT_SITE             || _ANTIDOTE_GIT_SITE=github.com
  # Tests also have zstyles, but they aren't user facing
  zstyle -s ':antidote:test:env'     LOCALAPPDATA _ANTIDOTE_LOCALAPPDATA || _ANTIDOTE_LOCALAPPDATA="${LOCALAPPDATA:-$LocalAppData}"
  zstyle -s ':antidote:test:env'     OSTYPE       _ANTIDOTE_OSTYPE       || _ANTIDOTE_OSTYPE=$OSTYPE
  zstyle -t ':antidote:test'         tty                                 || [[ -t 1 ]] || _ANTIDOTE_IS_TTY=false
  zstyle -T ':antidote:test:git'     autostash                           || _ANTIDOTE_GIT_AUTOSTASH=false
  zstyle -T ':antidote:test:git'     background-deepen                   || _ANTIDOTE_GIT_BG_DEEPEN=false
  zstyle -T ':antidote:test:version' show-sha                            || _ANTIDOTE_VERSION_SHOW_SHA=false
  # Legacy use of friendly names overrides all
  if zstyle -t ':antidote:bundle' use-friendly-names; then
    _ANTIDOTE_PATH_STYLE=short
  fi

  typeset -g ANTIDOTE_HOME
  if [[ -z "$ANTIDOTE_HOME" ]]; then
    zstyle -s ':antidote:home' dir ANTIDOTE_HOME || ANTIDOTE_HOME=$(get_cachedir antidote)
  fi

  typeset -g _ANTIDOTE_SNAPSHOT_DIR _ANTIDOTE_SNAPSHOT_MAX _ANTIDOTE_SNAPSHOT_DATEFMT _ANTIDOTE_AUTOSNAPSHOT=false
  zstyle -s ':antidote:snapshot' dir        _ANTIDOTE_SNAPSHOT_DIR     || _ANTIDOTE_SNAPSHOT_DIR=$(get_datadir antidote)/snapshots
  zstyle -s ':antidote:snapshot' max        _ANTIDOTE_SNAPSHOT_MAX     || _ANTIDOTE_SNAPSHOT_MAX=100
  zstyle -s ':antidote:snapshot' dateformat _ANTIDOTE_SNAPSHOT_DATEFMT || _ANTIDOTE_SNAPSHOT_DATEFMT='%Y-%m-%d %H:%M:%S %Z'
  zstyle -T ':antidote:snapshot:automatic' enabled && _ANTIDOTE_AUTOSNAPSHOT=true
  _ANTIDOTE_SNAPSHOT_DIR=${~_ANTIDOTE_SNAPSHOT_DIR}

  typeset -gA _antidote_using_context
  [[ -n "$ANTIDOTE_USING_CTX" ]] && eval "$ANTIDOTE_USING_CTX"
}

_ANTIDOTE_INIT_SCRIPT=$(
cat <<'EOS'
#!/usr/bin/env zsh
function antidote {
  case "$1" in
    bundle)
      shift
      antidote-bundle-dynamic @ANTIDOTE_HOME@ @ANTIDOTE_CONFIG@ "$@"
      ;;
    *)
      ANTIDOTE_DYNAMIC=true antidote-dispatch $@
      ;;
  esac
}
EOS
)

_ANTIDOTE_HELP=$(
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

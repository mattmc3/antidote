#region: Requirements

function __is542 () {
  emulate -L zsh; setopt local_options extended_glob
  local ver=${1:-$ZSH_VERSION}
  [[ $ver == 5.4.<2->* || $ver == 5.<5->* || $ver == <6->* ]] && return 0
  return 1
}

if ! __is542; then
  echo >&2 "antidote: Unsupported Zsh version '$ZSH_VERSION'. Expecting >5.4.2."
  return 1
fi

unfunction __is542

#endregion

#region: Init

() {
  0=${(%):-%x}
  local MATCH MBEGIN MEND; local -a match mbegin mend  # appease 'warn_create_global'

  fpath+=${0:A:h}/functions
  if [[ "$MANPATH" != *"${0:A:h}/man"* ]]; then
    export MANPATH="${0:A:h}/man:$MANPATH"
  fi

  # the -F option was added in 5.8
  autoload -Uz is-at-least
  if is-at-least 5.8; then
    typeset -gHa _adote_zparopt_flags=( -D -M -F )
  else
    typeset -gHa _adote_zparopt_flags=( -D -M )
  fi

  typeset -gHa _adote_funcopts=( local_options extended_glob no_monitor )
  if zstyle -t ':antidote:tests' set-warn-options; then
    typeset -gHa _adote_funcopts=( $_adote_funcopts warn_create_global warn_nested_var )
  fi

  # setup the environment
  local fn
  for fn in ${0:A:h}/functions/*; do
    (( $+functions[${fn:t}] )) && unfunction ${fn:t}
    autoload -Uz "${fn}"
  done
}

#endregion


#region: Functions

### The main controller for antidote.
function __antidote_main {
  # The reason we use `__antidote_main` instead putting all of this in `antidote`
  # is that this allows the `antidote` function to be overridden via `antidote init`.
  # The init command switches antidote from static mode to dynamic mode, but this
  # core functionality remains.
  setopt extended_glob
  0=${(%):-%x}

  local o_help o_version
  zparseopts ${_adote_zparopt_flags} -- \
    h=o_help    -help=h    \
    v=o_version -version=v ||
    return 1

  if (( ${#o_version} )); then
    local ver='1.7.4'
    local gitsha=$(git -C "${0:h}" rev-parse --short HEAD 2>/dev/null)
    [[ -z "$gitsha" ]] || ver="$ver ($gitsha)"
    echo "antidote version $ver"

  elif (( ${#o_help} )); then
    antidote-help "$@"

  elif [[ ${#} -eq 0 ]]; then
    antidote-help
    return 2

  elif [[ "${1}" = help ]]; then
    local manpage=${2:-antidote}
    antidote-help $manpage

  elif (( $+functions[antidote-${1}] )); then
    local cmd=${1}; shift
    antidote-${cmd} "$@"
    return $?

  else
    echo >&2 "antidote: command not found '${1}'" && return 1
  fi
}

### Determine bundle type: empty,file,dir,sshurl,url,unk,relpath,path,repo,word
function __antidote_bundle_type {
  emulate -L zsh; setopt $_adote_funcopts
  local result
  if [[ -e "$1" ]]; then
    [[ -f $1 ]] && result=file || result=dir
  elif [[ -z "${1// }" ]]; then
    result=empty
  else
    case "$1" in
      (/|~|'$')*)  result=path     ;;
      *://*)       result=url      ;;
      *@*:*/*)     result=sshurl   ;;
      *(:|@)*)     result=unk      ;;
      */*/*)       result=relpath  ;;
      */)          result=relpath  ;;
      */*)         result=repo     ;;
      *)           result=word     ;;
    esac
  fi
  typeset -g REPLY=$result
  echo $result
}

### Get the name of the bundle dir.
function __antidote_bundledir {
  # If the bundle is a repo/URL, then by default we use the legacy antibody format:
  # `$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions`
  # With `zstyle ':antidote:bundle' use-friendly-names on`, we can simplify to
  # `$ANTIDOTE_HOME/zsh-users/zsh-autosuggestions`
  # If the bundle is a file, use its parent directory.
  # Otherwise, just assume the bundle is a directory.

  emulate -L zsh; setopt $_adote_funcopts

  local bundle="$1"
  local bundle_type="$(__antidote_bundle_type $bundle)"

  # handle repo bundle paths
  if [[ "$bundle_type" == (repo|url|sshurl) ]] && [[ ! -e "$bundle_path" ]]; then
    if zstyle -t ':antidote:bundle' use-friendly-names; then
      # user/repo format
      # ex: $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions
      bundle=${bundle%.git}
      bundle=${bundle:gs/\:/\/}
      local parts=( $(__antidote_split '/' $bundle) )
      if [[ $#parts -gt 1 ]]; then
        echo $(antidote-home)/${parts[-2]}/${parts[-1]}
      else
        echo $(antidote-home)/$bundle
      fi
    else
      # sanitize URL for safe use as a dir name
      # ex: $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions
      local url=$(__antidote_tourl $bundle)
      url=${url%.git}
      url=${url:gs/\@/-AT-}
      url=${url:gs/\:/-COLON-}
      url=${url:gs/\//-SLASH-}
      echo $(antidote-home)/$url
    fi
  elif [[ -f "$bundle" ]]; then
    echo ${bundle:A:h}
  else
    echo ${bundle}
  fi
}

### Join an array into a string.
function __antidote_join {
  local sep=$1; shift
  echo ${(pj.$sep.)@}
}

### Split a string into an array
function __antidote_split {
  local sep=$1; shift
  echo ${(ps.$sep.)@}
}

### Get the url from a repo bundle.
function __antidote_tourl {
  emulate -L zsh; setopt $_adote_funcopts

  local bundle=$1
  local url=$bundle
  if [[ $bundle != *://* && $bundle != git@*:*/* ]]; then
    url=https://github.com/$bundle
  fi
  echo $url
}

#endregion


#region Completions

_antidote() {
  IFS=' ' read -A reply <<< "help bundle update home purge list load path init install"
}
compctl -K _antidote antidote

#endregion

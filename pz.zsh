# http://github.com/mattmc3/pz
# Copyright mattmc3, 2020-2021
# MIT license, https://opensource.org/licenses/MIT
# pz - Plugins for ZSH made easy-pz

function _pz_help() {
  if [[ -n "$1" ]] && (( $+functions[pz_extended_help] )); then
    pz_extended_help $@
    return $?
  else
    echo "pz - Plugins for ZSH made easy-pz"
    echo ""
    echo "usage:"
    echo "  pz <command> [<flags...>|<arguments...>]"
    echo ""
    echo "commands:"
    echo "  help      show this message"
    echo "  clone     download a plugin"
    echo "  initfile  show the file that will be sourced to initialize a plugin"
    echo "  list      list all plugins"
    echo "  prompt    load a prompt plugin"
    echo "  pull      update a plugin, or all plugins"
    echo "  source    load a plugin"
    echo "  zcompile  compile zsh files for your plugins"
  fi
}

function _pz_clone() {
  local gitserver; zstyle -s :pz:clone: default-gitserver gitserver || gitserver="github.com"
  local repo="$1"
  local plugin
  [[ -z "$2" ]] && plugin=${${1##*/}%.git} || plugin="$2"

  if [[ $repo != git://* &&
        $repo != https://* &&
        $repo != http://* &&
        $repo != ssh://* &&
        $repo != git@*:*/* ]]; then
    repo="https://${gitserver}/${repo%.git}.git"
  fi

  [[ -d "$PZ_PLUGIN_HOME" ]] || mkdir -p "$PZ_PLUGIN_HOME"
  git -C "$PZ_PLUGIN_HOME" clone --depth 1 --recursive --shallow-submodules "$repo" "$plugin"
  [[ $? -eq 0 ]] || return 1
}

function _pz_initfile() {
  local plugin=${${1##*/}%.git}
  local plugin_path="$PZ_PLUGIN_HOME/$plugin"
  [[ -d $plugin_path ]] || return 2

  local search_files
  if [[ -z "$2" ]]; then
    search_files=(
      # look for specific files first
      $plugin_path/$plugin.plugin.zsh(.N)
      $plugin_path/$plugin.zsh(.N)
      $plugin_path/$plugin(.N)
      $plugin_path/$plugin.zsh-theme(.N)
      $plugin_path/init.zsh(.N)
      # then do more aggressive globbing
      $plugin_path/*.plugin.zsh(.N)
      $plugin_path/*.zsh(.N)
      $plugin_path/*.zsh-theme(.N)
      $plugin_path/*.sh(.N)
    )
  else
    # if a subplugin was specified, the search is different
    local subpath=${2%/*}
    local subplugin=${2##*/}
    search_files=(
        $plugin_path/$2(.N)
        $plugin_path/$subpath/$subplugin/$subplugin.plugin.zsh(.N)
        $plugin_path/$subpath/$subplugin.plugin.zsh(.N)
        $plugin_path/$subpath/$subplugin/$subplugin.zsh(.N)
        $plugin_path/$subpath/$subplugin.zsh(.N)
        $plugin_path/$subpath/$subplugin/init.zsh(.N)
        $plugin_path/$subpath/$subplugin/$subplugin.zsh-theme(.N)
        $plugin_path/$subpath/$subplugin.zsh-theme(.N)
      )
  fi
  [[ ${#search_files[@]} -gt 0 ]] || return 1
  REPLY=${search_files[1]}
  echo $REPLY
}

function _pz_list() {
  local flag_detail=false
  if [[ "$1" == "-d" ]]; then
    flag_detail=true; shift
  fi
  for d in $PZ_PLUGIN_HOME/*(/N); do
    if [[ $flag_detail == true ]] && [[ -d $d/.git ]]; then
      repo_url=$(git -C "$d" remote get-url origin)
      printf "%-30s | %s\n" ${d:t} ${repo_url}
    else
      echo "${d:t}"
    fi
  done
}

function _pz_prompt() {
  local flag_add_only=false
  if [[ "$1" == "-a" ]]; then
    flag_add_only=true
    shift
  fi
  local repo="$1"
  local plugin=${${repo##*/}%.git}
  [[ -d "$PZ_PLUGIN_HOME/$plugin" ]] || _pz_clone $@
  fpath+="$PZ_PLUGIN_HOME/$plugin"
  if [[ $flag_add_only == false ]]; then
    autoload -U promptinit
    promptinit
    prompt "$plugin"
  fi
}

function _pz_pull() {
  local update_plugins
  [[ -n "$1" ]] && update_plugins=(${${1##*/}%.git}) || update_plugins=($(_pz_list))

  local p; for p in $update_plugins; do
    echo "updating ${p:t}..."
    git -C "$PZ_PLUGIN_HOME/$p" pull --recurse-submodules --depth 1 --rebase --autostash
  done
}

function _pz_source() {
  local plugin=${${1##*/}%.git}
  local plugindir="$PZ_PLUGIN_HOME/$plugin"

  if [[ ! -d "$plugindir" ]]; then
    _pz_clone $1
    if [[ $? -ne 0 ]] || [[ ! -d "$plugindir" ]]; then
      echo >&2 "cannot find and unable to clone plugin"
      echo >&2 "'pz source $@' should find a plugin at $plugindir"
      return 1
    fi
  fi

  local initfile
  if [[ -z "$2" ]]; then
    initfile="$pluginpath/$plugin.plugin.zsh"
  else
    local subpath=${2%/*}
    local subplugin=${2##*/}
    initfile="$pluginpath/$subpath/$subplugin.plugin.zsh"
  fi

  # if we didn't find the expected initfile then search for one
  if [[ ! -f "$initfile" ]]; then
    _pz_initfile "$@" >/dev/null
    initfile=$REPLY
    if [[ $? -ne 0 ]] || [[ ! -f "$initfile" ]]; then
      echo >&2 "unable to find plugin initfile: $@" && return 1
    fi
  fi
  fpath+="${initfile:h}"
  [[ -d ${initfile:h}/functions ]] && fpath+="${initfile:h}/functions"
  source "$initfile"
}

function _pz_zcompile() {
  emulate -L zsh; setopt $_pz_opts
  autoload -U zrecompile

  local flag_clean=false
  [[ "$1" == "-c" ]] && flag_clean=true && shift

  local compile_plugins
  [[ -n "$1" ]] && compile_plugins=(${${1##*/}%.git}) || compile_plugins=($(_pz_list))

  local p; for p in $compile_plugins; do
    echo "p := $p"
    if [[ $flag_clean == true ]]; then
      local f; for f in "$PZ_PLUGIN_HOME/$p"/**/*.zwc(.N) "$PZ_PLUGIN_HOME/$p"/**/*.zwc.old(.N); do
        echo "removing $f" && command rm -f "$f"
      done
    else
      local f; for f in "$PZ_PLUGIN_HOME/$p"/**/*.zsh{,-theme}; do
        echo "compiling $f" && zrecompile -pq "$f"
      done
    fi
  done
}

function pz() {
  local cmd="$1"
  local REPLY
  if (( $+functions[_pz_${cmd}] )); then
    shift
    _pz_${cmd} "$@"
    return $?
  elif [[ -z $cmd ]]; then
    _pz_help && return
  else
    echo >&2 "pz command not found: '${cmd}'" && return 1
  fi
}

() {
  # setup pz by setting some globals and autoloading anything in functions
  typeset -g PZ_PLUGIN_HOME=${PZ_PLUGIN_HOME:-${ZDOTDIR:-$HOME/.config/zsh}/plugins}

  typeset -gHa _pz_opts=( localoptions extendedglob globdots globstarshort nullglob rcquotes )
  local basedir="${${(%):-%x}:a:h}"

  if [[ -d $basedir/functions ]]; then
    typeset -gU FPATH fpath=( $basedir/functions $basedir $fpath )
    autoload -Uz $basedir/functions/*(.N)
  fi
}

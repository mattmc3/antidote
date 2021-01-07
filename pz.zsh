# http://github.com/mattmc3/pz
# Copyright mattmc3, 2020-2021
# MIT license, https://opensource.org/licenses/MIT
#
# pz - Plugins for ZSH made easy-pz
#

() {
  typeset -gHa _pz_opts=( localoptions extendedglob globdots globstarshort nullglob rcquotes )
  local basedir="${${(%):-%x}:A:h}"
  typeset -g PZ_PLUGIN_HOME=${PZ_PLUGIN_HOME:-$basedir:h}
  local funcdir=$basedir/zfunctions
  typeset -gU FPATH fpath=( $funcdir $basedir $fpath )
  autoload -Uz $funcdir/*(.N)
}

function _pz_help() {
  if [[ -n "$1" ]] && (( $+functions[pz_extended_help] )); then
    pz_extended_help $@
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
  if [[ $repo != git://* &&
        $repo != https://* &&
        $repo != http://* &&
        $repo != ssh://* &&
        $repo != git@*:*/* ]]; then
    repo="https://${gitserver}/${repo%.git}.git"
  fi
  git -C "$PZ_PLUGIN_HOME" clone --depth 1 --recursive --shallow-submodules "$repo"
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
    # if a subplugin was specified, the search is more specific
    local subpath=${2%/*}
    local subplugin=${2##*/}
    search_files=(
        # look for specific files
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
  echo ${search_files[1]}
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
  local p update_plugins
  if [[ -n "$1" ]]; then
    update_plugins=(${${1##*/}%.git})
  else
    update_plugins=($(_pz_list))
  fi
  for p in $update_plugins; do
    echo "updating ${p:t}..."
    git -C "$PZ_PLUGIN_HOME/$p" pull --recurse-submodules --depth 1 --rebase --autostash
  done
}

function _pz_source() {
  local repo="$1"
  local plugin=${${repo##*/}%.git}
  local pluginpath="$PZ_PLUGIN_HOME/$plugin"
  [[ -d "$pluginpath" ]] || _pz_clone $@

  local source_file;
  if [[ -z "$2" ]]; then
    source_file="$pluginpath/$plugin.plugin.zsh"
  else
    local subpath=${2%/*}
    local subplugin=${2##*/}
    source_file="$pluginpath/$subpath/$subplugin.plugin.zsh"
  fi

  if [[ ! -f "$source_file" ]]; then
    # time to search
    source_file=$(_pz_initfile "$@")
  fi

  [[ -f "$source_file" ]] || {
    echo "unable to source plugin - file not found $@" >&2
    return 1
  }
  fpath+="${source_file:a:h}"
  source "$source_file"
}

function _pz_zcompile() {
  emulate -L zsh; setopt $_pz_opts
  autoload -U zrecompile
  [[ -d $PZ_PLUGIN_HOME ]] || return 1

  local f
  local flag_clean=false
  [[ "$1" == "-c" ]] && flag_clean=true && shift

  if [[ $flag_clean == true ]]; then
    for f in "$PZ_PLUGIN_HOME"/**/*.zwc(.N) "$PZ_PLUGIN_HOME"/**/*.zwc.old(.N); do
      echo "removing $f"
      command rm -f "$f"
    done
  else
    for f in "$PZ_PLUGIN_HOME"/**/*.zsh{,-theme}; do
      echo "compiling $f"
      zrecompile -pq "$f"
    done
  fi
}

function pz() {
  local cmd="$1"
  [[ -d "$PZ_PLUGIN_HOME" ]] || mkdir -p "$PZ_PLUGIN_HOME"

  # if functions "_pz_${cmd}" > /dev/null ; then
  if (( $+functions[_pz_${cmd}] )); then
    shift
    _pz_${cmd} "$@"
    return $?
  elif [[ -z $cmd ]]; then
    _pz_help
    return
  else
    echo "pz command not found: '${cmd}'" >&2 && return 1
  fi
}

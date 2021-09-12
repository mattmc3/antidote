# http://github.com/mattmc3/pz
# Copyright mattmc3, 2020-2021
# MIT license, https://opensource.org/licenses/MIT
# pz - Plugins for Zsh made easy-pz

function _pz_help() {
  if [[ -n "$1" ]] && (( $+functions[pz_extended_help] )); then
    pz_extended_help $@
    return $?
  else
    echo "pz - Plugins for Zsh made easy-pz"
    echo ""
    echo "usage:"
    echo "  pz <command> [<flags...>|<arguments...>]"
    echo ""
    echo "commands:"
    echo "  help      display this message"
    echo "  clone     download a plugin"
    echo "  initfile  display the plugin's init file"
    echo "  list      list all plugins"
    echo "  prompt    load a prompt plugin"
    echo "  pull      update a plugin, or all plugins"
    echo "  source    load a plugin"
    echo "  zcompile  compile your plugins' zsh files"
  fi
}

function _pz_clone() {
  local gitserver; zstyle -s :pz:clone: default-gitserver gitserver || gitserver="github.com"
  local repo="$1"
  local plugin
  [[ -z "$2" ]] && plugin=${${1##*/}%.git} || plugin="$2"

  [[ ! -d "$PZ_PLUGIN_HOME/$plugin" ]] || return

  if [[ $repo != git://* &&
        $repo != https://* &&
        $repo != http://* &&
        $repo != ssh://* &&
        $repo != git@*:*/* ]]; then
    repo="https://${gitserver}/${repo%.git}.git"
  fi

  [[ -d "$PZ_PLUGIN_HOME" ]] || mkdir -p "$PZ_PLUGIN_HOME"
  command git -C "$PZ_PLUGIN_HOME" clone --depth 1 --recursive --shallow-submodules "$repo" "$plugin"
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
  local giturl name user repo shorthand flag_shorthand flag_detail
  if [[ "$1" == "-s" ]]; then
    flag_shorthand=true; shift
  fi
  if [[ "$1" == "-d" ]]; then
    flag_detail=true; shift
  fi
  for d in $PZ_PLUGIN_HOME/*(/N); do
    if [[ -d "$d"/.git ]]; then
      name="${d:t}"
      giturl=$(command git -C "$d" remote get-url origin)
      user=${${${giturl%/*}%.git}##*/}
      repo=${${giturl##*/}%.git}
      shorthand="$user/$repo"
    else
      name="${d:t}"
      giturl=
      user=
      repo=
      shorthand="$name"
    fi
    if [[ $flag_detail == true ]] && [[ -n "$giturl" ]]; then
      printf "%-30s | %s\n" ${name} ${giturl}
    elif [[ $flag_shorthand == true ]]; then
      echo "$shorthand"
    else
      echo "$name"
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
  emulate -L zsh; setopt local_options no_monitor
  local update_plugins
  [[ -n "$1" ]] && update_plugins=(${${1##*/}%.git}) || update_plugins=($(_pz_list))

  local p; for p in $update_plugins; do
    () {
      echo "${fg[cyan]}updating ${p:t}...${reset_color}"
      command git -C "$PZ_PLUGIN_HOME/$p" pull --quiet --recurse-submodules --depth 1 --rebase --autostash
      if [[ $? -eq 0 ]]; then
        echo "${fg[green]}${p:t} update successful.${reset_color}"
      else
        echo "${fg[red]}${p:t} update failed.${reset_color}"
      fi
    } &
  done
  wait
}

function _pz_source() {
  # check associative array cache for initfile to source
  local initfile_key="':pz:source:$1:$2:'"
  local initfile=$_pz_initfile_cache[$initfile_key]

  # if we didn't find an initfile in the lookup or it doesn't exist, then
  # clone the plugin if possible and save the initfile location to cache
  if [[ ! -f "$initfile" ]]; then
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

    # if we have invalid cache that gives the wrong result, fix it
    [[ -z "$_pz_initfile_cache[$initfile_key]" ]] || __pz_init_cache "reset"
    # add result to cache
    _pz_initfile_cache[$initfile_key]="$initfile"
    local stored_initfile_val="${initfile/#$PZ_PLUGIN_HOME\//\$PZ_PLUGIN_HOME/}"
    echo "_pz_initfile_cache[$initfile_key]=\"${stored_initfile_val}\"" >> "$PZ_CACHE_HOME/_pz_initfile_cache.zsh"
  fi

  fpath+="${initfile:h}"
  [[ -d ${initfile:h}/functions ]] && fpath+="${initfile:h}/functions"
  source "$initfile"
}

function _pz_zcompile() {
  emulate -L zsh; setopt $_pz_opts
  autoload -U zrecompile

  local flag_clean=false
  local compile_plugins p f
  [[ "$1" == "-c" ]] && flag_clean=true && shift
  [[ -n "$1" ]] && compile_plugins=(${${1##*/}%.git}) || compile_plugins=($(_pz_list))

  for p in $compile_plugins; do
    if [[ $flag_clean == true ]]; then
      for f in "$PZ_PLUGIN_HOME/$p"/**/*.zwc(.N) "$PZ_PLUGIN_HOME/$p"/**/*.zwc.old(.N); do
        echo "removing $f" && command rm -f "$f"
      done
    else
      for f in "$PZ_PLUGIN_HOME/$p"/**/*.zsh{,-theme}; do
        echo "compiling $f" && zrecompile -pq "$f"
      done
    fi
  done
}

function __pz_init_cache() {
  if [[ ! -f "$PZ_CACHE_HOME/_pz_initfile_cache.zsh" ]] || [[ "$1" == "reset" ]]; then
    mkdir -p "$PZ_CACHE_HOME"
    echo "typeset -gA _pz_initfile_cache" > "$PZ_CACHE_HOME/_pz_initfile_cache.zsh"
  fi
  source "$PZ_CACHE_HOME/_pz_initfile_cache.zsh"
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
  autoload colors && colors
  local basedir="${${(%):-%x}:a:h}"
  [[ -n "$PZ_CACHE_HOME" ]] || typeset -g PZ_CACHE_HOME="$basedir/.cache"
  [[ -n "$PZ_PLUGIN_HOME" ]] || typeset -g PZ_PLUGIN_HOME="${ZDOTDIR:-$HOME/.config/zsh}/plugins"
  typeset -gHa _pz_opts=( localoptions extendedglob globdots globstarshort nullglob rcquotes )
  __pz_init_cache

  if [[ -d $basedir/functions ]]; then
    typeset -gU FPATH fpath=( $basedir/functions $basedir $fpath )
    autoload -Uz $basedir/functions/*(.N)
  fi
}

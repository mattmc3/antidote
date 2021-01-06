# http://github.com/mattmc3/pz
# Copyright mattmc3, 2020-2021
# MIT license, https://opensource.org/licenses/MIT
#
# pz - Plugins for ZSH made easy-pz
#

# init settings
_zero=${(%):-%N}
() {
  local zspz; zstyle -s ":pz:" "zstyle-prefix" zspz || zspz="pz"
  if zstyle -T ":${zspz}:" plugins-dir; then
    zstyle ":${zspz}:" plugins-dir ${_zero:A:h:h}
  fi
  if zstyle -T ":${zspz}:clone:" default-gitserver; then
    zstyle ":${zspz}:clone:" default-gitserver 'github.com'
  fi
}
unset _zero

function __pz_help_examples() {
  echo "examples:"
      echo "  pz $1 zsh-users/zsh-autosuggestions"
      echo "  pz $1 https://github.com/zsh-users/zsh-history-substring-search"
      echo "  pz $1 git@github.com:zsh-users/zsh-completions.git"
}

function _pz_help() {
  case "$1" in
    clone)
      echo "usage:"
      echo "  pz clone <plugin>"
      echo ""
      echo "args:"
      echo "  plugin:  shorthand user/repo or full git URL"
      echo ""
      __pz_help_examples "clone"
      ;;
    list)
      echo "usage:"
      echo "  pz list [-s]"
      echo ""
      echo "args:"
      echo "  -s  list the short name"
      ;;
    prompt)
      echo "usage:"
      echo "  pz prompt [-a] <prompt-plugin>"
      echo ""
      echo "args:"
      echo "  -a             Adds a prompt, but does not set it as the theme"
      echo "  prompt-plugin  shorthand user/repo or full git URL"
      echo ""
      echo "examples:"
      echo "  pz prompt -a https://github.com/agnoster/agnoster-zsh-theme"
      echo "  pz prompt -a git@github.com:miekg/lean.git"
      echo "  pz prompt -a romkatv/powerlevel10k"
      echo "  pz prompt sindresorhus/pure"
      ;;
    pull)
      echo "usage:"
      echo "pz pull <plugin>"
      echo ""
      echo "args:"
      echo "  plugin:  shorthand user/repo or full git URL"
      echo ""
      __pz_help_examples "pull"
      ;;
    source)
      echo "usage:"
      echo "pz source <plugin> [<subpath>]"
      echo ""
      echo "args:"
      echo "  plugin:   shorthand user/repo or full git URL"
      echo "  subpath:  subpath within plugin to use instead of root path"
      echo ""
      __pz_help_examples "source"
      ;;
    *)
      echo "pz - Plugins for ZSH made easy-pz"
      echo ""
      echo "usage: pz <cmd> [args...]"
      echo ""
      echo "commands:"
      echo "  help    show this message"
      echo "  clone   download a plugin"
      echo "  list    list all plugins"
      echo "  prompt  load a prompt plugin"
      echo "  pull    update a plugin, or all plugins"
      echo "  source  load a plugin"
      ;;
  esac
}

function _pz_clone() {
  local zspz; zstyle -s ":pz:" "zstyle-prefix" zspz || zspz="pz"
  local pluginsdir; zstyle -s ":${zspz}:" plugins-dir pluginsdir
  local gitserver; zstyle -s ":${zspz}:clone:" default-gitserver gitserver

  local repo="$1"
  if [[ $repo != git://* &&
        $repo != https://* &&
        $repo != http://* &&
        $repo != ssh://* &&
        $repo != git@*:*/* ]]; then
    repo="https://${gitserver}/${repo%.git}.git"
  fi
  git -C "$pluginsdir" clone --recursive --depth 1 "$repo"
  [[ $! -eq 0 ]] || return 1
}

function _pz_list() {
  local zspz; zstyle -s ":pz:" "zstyle-prefix" zspz || zspz="pz"
  local pluginsdir; zstyle -s ":${zspz}:" plugins-dir pluginsdir
  local gitserver; zstyle -s ":${zspz}:clone:" default-gitserver gitserver

  local httpsgit="https://$gitserver"
  local flag_short_name=false
  if [[ "$1" == "-s" ]]; then
    flag_short_name=true
    shift
  fi

  for d in $pluginsdir/*(/N); do
    if [[ $flag_short_name == true ]]; then
      echo "${d:t}"
    else
      [[ -d $d/.git ]] || continue
      repo_url=$(git -C "$d" remote get-url origin)
      if [[ "$repo_url" == ${repo_url#$httpsgit/} ]]; then
        echo "$repo_url"
      else
        echo ${${repo_url#$httpsgit/}%.git}
      fi
    fi
  done
}

function _pz_prompt() {
  local zspz; zstyle -s ":pz:" "zstyle-prefix" zspz || zspz="pz"
  local pluginsdir; zstyle -s ":${zspz}:" plugins-dir pluginsdir

  local flag_add_only=false
  if [[ "$1" == "-a" ]]; then
    flag_add_only=true
    shift
  fi
  local repo="$1"
  local plugin=${${repo##*/}%.git}
  [[ -d $pluginsdir/$plugin ]] || _pz_clone "$@"
  fpath+=$pluginsdir/$plugin
  if [[ $flag_add_only == false ]]; then
    autoload -U promptinit
    promptinit
    prompt "$plugin"
  fi
}

function _pz_pull() {
  local zspz; zstyle -s ":pz:" "zstyle-prefix" zspz || zspz="pz"
  local pluginsdir; zstyle -s ":${zspz}:" plugins-dir pluginsdir

  local p update_plugins
  if [[ -n "$1" ]]; then
    update_plugins=(${${1##*/}%.git})
  else
    update_plugins=($(_pz_list -s))
  fi
  for p in $update_plugins; do
    echo "updating ${p:t}..."
    git -C "$pluginsdir/$p" pull --rebase --autostash
  done
}

function __pz_get_source_file() {
  local zspz; zstyle -s ":pz:" "zstyle-prefix" zspz || zspz="pz"
  local pluginsdir; zstyle -s ":${zspz}:" plugins-dir pluginsdir

  local plugin=${${1##*/}%.git}
  local plugin_path="$pluginsdir/$plugin"
  [[ -d $plugin_path ]] || return 2

  local search_files
  if [[ -z "$2" ]]; then
    # if just a repo was specified, the search is broad
    if [[ -f "$plugin_path/$plugin.plugin.zsh" ]]; then
      # let's do a performance shortcut for adherents to proper convention
      search_files=("$plugin_path/$plugin.plugin.zsh")
    else
      search_files=(
        # look for specific files first
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
    fi
  else
    # if a subplugin was specified, the search is more specific
    local subpath=${2%/*}
    local subplugin=${2##*/}
    search_files=(
        # look for specific files
        $plugin_path/$2(.N)
        $plugin_path/$subpath/$subplugin.zsh(.N)
        $plugin_path/$subpath/$subplugin/$subplugin.plugin.zsh(.N)
        $plugin_path/$subpath/$subplugin/init.zsh(.N)
      )
  fi
  [[ ${#search_files[@]} -gt 0 ]] || return 1
  echo ${search_files[1]}
}

function _pz_source() {
  local source_file=$(__pz_get_source_file "$@")
  if [[ $? -eq 2 ]]; then
    _pz_clone $repo
    source_file=$(__pz_get_source_file "$@")
  fi
  [[ -n "$source_file" ]] || {
    echo "plugin not found $1 $2" >&2
    return 1
  }
  fpath+="${source_file:a:h}"
  source "$source_file"
}

function pz() {
  local zspz; zstyle -s ":pz:" "zstyle-prefix" zspz || zspz="pz"
  local pluginsdir; zstyle -s ":${zspz}:" plugins-dir pluginsdir

  local cmd="$1"
  [[ -d "$pluginsdir" ]] || mkdir -p "$pluginsdir"

  if functions "_pz_${cmd}" > /dev/null ; then
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

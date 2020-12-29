# http://github.com/mattmc3/pz
# Copyright mattmc3, 2020-2021
# MIT license, https://opensource.org/licenses/MIT
#
# pz - Plugins for ZSH made easy-pz
#

# init settings
if zstyle -T :pz: plugins-dir; then
  zstyle :pz: plugins-dir ${${(%):-%N}:A:h:h}
fi
if zstyle -T :pz:clone: default-gitserver; then
  zstyle :pz:clone: default-gitserver 'github.com'
fi

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
      echo "  plugin:  <user/repo>|<git-url>"
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
      echo "  prompt-plugin  <user/repo>|<git-url>"
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
      echo "  plugin:  <user/repo>|<git-url>"
      echo ""
      __pz_help_examples "pull"
      ;;
    source)
      echo "usage:"
      echo "pz source <plugin>"
      echo ""
      echo "args:"
      echo "  plugin:  <user/repo>|<git-url>"
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
  local repo="$1"
  local pluginsdir; zstyle -s :pz: plugins-dir pluginsdir
  local gitserver; zstyle -s :pz:clone: default-gitserver gitserver
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
  local pluginsdir; zstyle -s :pz: plugins-dir pluginsdir
  local gitserver; zstyle -s :pz:clone: default-gitserver gitserver
  local httpsgit="https://$gitserver"
  local flag_short_name=false
  if [[ "$1" == "-s" ]]; then
    flag_short_name=true
    shift
  fi

  for d in $pluginsdir/*(/N); do
    [[ -d $d/.git ]] || continue
    if [[ $flag_short_name == true ]]; then
      echo "${d:t}"
    else
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
  local pluginsdir; zstyle -s :pz: plugins-dir pluginsdir
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
  local pluginsdir; zstyle -s :pz: plugins-dir pluginsdir
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

function _pz_source() {
  local pluginsdir; zstyle -s :pz: plugins-dir pluginsdir
  local repo="$1"
  local plugin=${${repo##*/}%.git}

  if [[ ! -d $pluginsdir/$plugin ]]; then
    _pz_clone "$@"
  fi

  local source_file="$pluginsdir/$plugin/$plugin.plugin.zsh"
  if [[ ! -f "$source_file" ]]; then
    local files=(
      $pluginsdir/$plugin/*.plugin.zsh(.N)
      $pluginsdir/$plugin/*.zsh(.N)
      $pluginsdir/$plugin/*.sh(.N)
      $pluginsdir/$plugin/*.zsh-theme(.N)
    )
    local alt_source_file=${files[1]}
    [[ -n "$alt_source_file" ]] || {
      echo "cannot find zsh file to source: $repo" >&2
      return 1
    }
    ln -s "$alt_source_file" "$source_file"
  fi
  fpath+=$pluginsdir/$plugin
  source "$source_file"
}

function pz() {
  local cmd="$1"
  local pluginsdir; zstyle -s :pz: plugins-dir pluginsdir
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

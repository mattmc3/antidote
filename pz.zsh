# http://github.com/mattmc3/pz
# Copyright mattmc3, 2020-2021
# MIT license, https://opensource.org/licenses/MIT
#
# pz - Plugins for ZSH made easy-pz
#

PZ_PLUGINS_DIR="${PZ_PLUGINS_DIR:-${ZDOTDIR:-$HOME/.config/zsh}/plugins}"

function __pz_help_examples() {
  echo "examples:"
      echo "  pz $1 zsh-users/zsh-autosuggestions"
      echo "  pz $1 https://github.com/zsh-users/zsh-history-substring-search"
      echo "  pz $1 git@github.com:zsh-users/zsh-completions.git"
}

function _pz_help() {
  case "$1" in
    clone)
      echo "pz clone <plugin> - download a plugin"
      echo ""
      echo "args:"
      echo "  plugin:  <user/repo>|<git-url>"
      echo ""
      __pz_help_examples "clone"
      ;;
    source)
      echo "pz source <plugin> - load a plugin"
      echo ""
      echo "args:"
      echo "  plugin:  <user/repo>|<git-url>"
      echo ""
      __pz_help_examples "source"
      ;;
    pull)
      echo "pz pull <plugin> - update a plugin"
      echo ""
      echo "args:"
      echo "  plugin:  <user/repo>|<git-url>"
      echo ""
      __pz_help_examples "pull"
      ;;
    prompt)
      echo "pz prompt [-a] <prompt-plugin> - load a prompt plugin"
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
  local plugin=${${repo##*/}%.git}
  if [[ $repo != git://* &&
        $repo != https://* &&
        $repo != http://* &&
        $repo != ssh://* &&
        $repo != git@*:*/* ]]; then
    repo="https://github.com/${repo%.git}.git"
  fi
  git -C "$PZ_PLUGINS_DIR" clone --recursive --depth 1 "$repo"
  [[ $! -eq 0 ]] || return 1
}

function _pz_list() {
  setopt localoptions nullglob
  for d in $PZ_PLUGINS_DIR/*(/); do
    if [[ -d $d/.git ]]; then
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
  [[ -d $PZ_PLUGINS_DIR/$plugin ]] || _pz_clone "$@"
  fpath+=$PZ_PLUGINS_DIR/$plugin
  if [[ $flag_add_only == false ]]; then
    autoload -U promptinit
    promptinit
    prompt "$plugin"
  fi
}

function _pz_pull() {
  local repo plugin update_plugins
  if [[ -n "$1" ]]; then
    update_plugins=(${${1##*/}%.git})
  else
    update_plugins=($(_pz_list))
  fi
  for p in $update_plugins; do
    echo "updating ${p:t}..."
    git -C "$PZ_PLUGINS_DIR/$p" pull --rebase --autostash
  done
}

function _pz_source() {
  local repo="$1"
  local plugin=${${repo##*/}%.git}

  if [[ ! -d $PZ_PLUGINS_DIR/$plugin ]]; then
    _pz_clone "$@"
  fi

  local source_file="$PZ_PLUGINS_DIR/$plugin/$plugin.plugin.zsh"
  if [[ ! -f "$source_file" ]]; then
    local files=(
      $PZ_PLUGINS_DIR/$plugin/*.plugin.zsh(.N)
      $PZ_PLUGINS_DIR/$plugin/*.zsh(.N)
      $PZ_PLUGINS_DIR/$plugin/*.sh(.N)
      $PZ_PLUGINS_DIR/$plugin/*.zsh-theme(.N)
    )
    local alt_source_file=${files[1]}
    [[ -n "$alt_source_file" ]] || {
      echo "cannot find zsh file to source: $repo" >&2
      return 1
    }
    ln -s "$alt_source_file" "$source_file"
  fi
  fpath+=$PZ_PLUGINS_DIR/$plugin
  source "$source_file"
}

function pz() {
  cmd="$1"
  [[ -d "$PZ_PLUGINS_DIR" ]] || mkdir -p "$PZ_PLUGINS_DIR"

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

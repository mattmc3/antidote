# http://github.com/mattmc3/pz
# Copyright mattmc3, 2020-2021
# MIT license, https://opensource.org/licenses/MIT
#
# pz - Plugins for ZSH made easy-pz
#

PZ_PLUGINS_DIR="${PZ_PLUGINS_DIR:-${ZDOTDIR:-$HOME/.config/zsh}/plugins}"

function _pz_help() {
  echo "pz - Plugins for ZSH made easy-pz"
  echo ""
  echo "usage: pz <cmd> [args...]"
  echo ""
  echo "commands:"
  echo "  help    show this message"
  echo "  clone   clone a zsh plugin's git repo"
  echo "  list    list all cloned plugins"
  echo "  prompt  load a plugin as a prompt"
  echo "  pull    update a plugin, or all plugins"
  echo "  source  source a plugin"
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
  local repo="$1"
  local plugin=${${repo##*/}%.git}
  if [[ ! -d $PZ_PLUGINS_DIR/$plugin ]]; then
    _pz_clone "$@"
  fi
  autoload -U promptinit; promptinit
  fpath+=$PZ_PLUGINS_DIR/$plugin
  prompt "$plugin"
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
  setopt localoptions nullglob
  local repo="$1"
  local plugin=${${repo##*/}%.git}

  if [[ ! -d $PZ_PLUGINS_DIR/$plugin ]]; then
    _pz_clone "$@"
  fi

  local source_file="$PZ_PLUGINS_DIR/$plugin/$plugin.plugin.zsh"
  if [[ ! -f "$source_file" ]]; then
    local files=(
      $PZ_PLUGINS_DIR/$plugin/*.plugin.zsh
      $PZ_PLUGINS_DIR/$plugin/*.zsh
      $PZ_PLUGINS_DIR/$plugin/*.sh
      $PZ_PLUGINS_DIR/$plugin/*.zsh-theme
    )
    local alt_source_file=${files[1]}
    [[ -n "$alt_source_file" ]] || {
      echo "cannot find zsh file to source: $repo" >&2
      return 1
    }
    ln -s "$alt_source_file" "$source_file"
  fi
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

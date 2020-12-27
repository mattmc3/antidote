
# http://github.com/mattmc3/zplugr
# Copyright mattmc3, 2020-2021
# MIT license, https://opensource.org/licenses/MIT
#
# A humble plugin manager for zsh
#

ZPLUGR_PLUGINS_DIR="${ZPLUGR_PLUGINS_DIR:-${ZDOTDIR:-$HOME/.config/zsh}/plugins}"

function _zplugr_help() {
  echo "zplugr - A humble zsh plugin manager"
  echo ""
  echo "usage: zplugr <cmd> args..."
  echo ""
  echo "commands:"
  echo "  clone   clone a zsh plugin's git repo"
  echo "  pull    update a plugin, or all plugins"
  echo "  path    show zplugr's root plugin path"
  echo "  prompt  load a plugin as a prompt"
  echo "  ls      list all cloned plugins"
  echo "  source  source a plugin"
  echo "  exists  check if a plugin is cloned"
  echo "  help    show this message"
}

function _zplugr_prompt() {
  local repo="$1"
  local plugin=${${repo##*/}%.git}
  if [[ ! -d $ZPLUGR_PLUGINS_DIR/$plugin ]]; then
    _zplugr_clone "$@"
  fi
  autoload -U promptinit; promptinit
  fpath+=$ZPLUGR_PLUGINS_DIR/$plugin
  prompt "$plugin"
}

function _zplugr_clone() {
  local repo="$1"
  local plugin=${${repo##*/}%.git}
  if [[ $repo != git://* &&
        $repo != https://* &&
        $repo != http://* &&
        $repo != ssh://* &&
        $repo != git@*:*/* ]]; then
    repo="https://github.com/${repo%.git}.git"
  fi
  git -C "$ZPLUGR_PLUGINS_DIR" clone --recursive --depth 1 "$repo"
}

function _zplugr_pull() {
  setopt localoptions nullglob
  local repo plugin update_plugins
  if [[ -n "$1" ]]; then
    update_plugins=(${${1##*/}%.git})
  else
    update_plugins=($ZPLUGR_PLUGINS_DIR/*(/))
  fi
  for p in $update_plugins; do
    if [[ -d $p/.git ]]; then
      echo "updating ${p:t}..."
      git -C "$p" pull --rebase
    else
      echo "${p:t} is not a git repo. skipping..."
    fi
  done
}

function _zplugr_source() {
  setopt localoptions nullglob
  local repo="$1"
  local plugin=${${repo##*/}%.git}

  if [[ ! -d $ZPLUGR_PLUGINS_DIR/$plugin ]]; then
    _zplugr_clone "$@"
  fi

  local source_file="$ZPLUGR_PLUGINS_DIR/$plugin/$plugin.plugin.zsh"
  if [[ ! -f "$source_file" ]]; then
    local files=(
      $ZPLUGR_PLUGINS_DIR/$plugin/*.plugin.zsh
      $ZPLUGR_PLUGINS_DIR/$plugin/*.zsh
      $ZPLUGR_PLUGINS_DIR/$plugin/*.sh
      $ZPLUGR_PLUGINS_DIR/$plugin/*.zsh-theme
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

function _zplugr_exists() {
  local repo="$1"
  local plugin=${${repo##*/}%.git}
  [[ -d $ZPLUGR_PLUGINS_DIR/$plugin ]] && return 0 || return 1
}

function _zplugr_ls() {
  \ls $ZPLUGR_PLUGINS_DIR
}

function zplugr() {
  cmd="$1"
  [[ -d "$ZPLUGR_PLUGINS_DIR" ]] || mkdir -p "$ZPLUGR_PLUGINS_DIR"

  if functions "_zplugr_${cmd}" > /dev/null ; then
    shift
    _zplugr_${cmd} "$@"
    return $!
  elif [[ -z $cmd ]]; then
    _zplugr_help
    return
  else
    echo "zplugr command not found: '${cmd}'" >&2 && return 1
  fi
}

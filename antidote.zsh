#!/usr/bin/env zsh
#
# antidote
#
# A spiritual successor to antibody: https://getantibody.github.io/
# antidote bundle < ${ZDOTDIR:-~}/.antidote.conf >| $ANTIDOTE_DIR/init.zsh

ANTIDOTE_DIR=${ANTIDOTE_DIR:-${ZDOTDIR:-~}/.antidote}
if [[ -z "$ANTIDOTE_RESET_ON_CHANGE" ]]; then
  ANTIDOTE_RESET_ON_CHANGE=(${ZDOTDIR:-~}/.zpluginrc)
fi

function antidote-help() {
  local usage=(
    'usage: antidote [<flags>] <command> [<args> ...]'
    ''
    'Flags:'
    '  -h, --help  Show help'
    ''
    'Commands:'
    '  home'
    '    prints where antidote is cloning plugins'
  )
  printf "%s\n" "${usage[@]}"
}

function antidote-home() {
  echo $ANTIDOTE_DIR
}

function antidote-compile() {
  local repo plugin f
  autoload -U zrecompile
  for repo in $ANTIDOTE_DIR/*/.git/..(/); do
    plugin=${repo:A}
    for f in "$plugin"/**/*.zwc(N) "$plugin"/**/*.zwc.old(N); do
      command rm -f "$f"
    done
    for f in "$plugin"/**/*.zsh{,-theme}(N); do
      zrecompile -pq "$f"
    done
  done
}

function antidote-update() {
  setopt local_options no_notify no_monitor
  local repo plugin
  for repo in $ANTIDOTE_DIR/*/.git/..(/); do
    plugin=${repo:A}
    () {
      echo "Updating ${plugin:t}"
      for f in "$plugin"/**/*.zwc(N) "$plugin"/**/*.zwc.old(N); do
        command rm -f "$f"
      done
      command git -C "$plugin" pull --quiet --depth 1 --recurse-submodules --rebase --autostash
      echo "Done updating ${plugin:t}"
    } &
  done
  wait
}

function antidote-clone() {
  local repo=$1
  local giturl=$repo
  local branch=$2
  local plugin=$ANTIDOTE_DIR/${repo:t}
  if [[ ! -d $plugin ]]; then
    [[ -z "$branch" ]] || branch="--branch=$branch"
    if [[ $repo != git://* &&
          $repo != https://* &&
          $repo != http://* &&
          $repo != ssh://* &&
          $repo != git@*:*/* ]]
    then
      giturl=https://github.com/$repo
    fi
    command git clone $branch --quiet --depth 1 --recurse-submodules --shallow-submodules $giturl $plugin
  fi
}

function -antidote-initfile() {
  local plugin_dir=$1
  local plugin_name=${plugin_dir:t}
  local initfiles
  initfiles=(
    $plugin_dir/$plugin_name.plugin.zsh(N)
    $plugin_dir/$plugin_name.zsh(N)
    $plugin_dir/init.zsh(N)
    $plugin_dir/*.plugin.{z,}sh(N)
    $plugin_dir/*.{z,}sh{-theme,}(N)
  )
  if [[ ${#initfiles[@]} -eq 0 ]]; then
    >&2 echo "No init file found '$1'." && return 1
  fi
  local f
  for f in $plugin_dir/init.zsh $plugin_dir/$plugin_name.plugin.zsh; do
    [[ -e $f ]] || ln -s $initfiles[1] $f
  done
}

function antidote-bundle() {
  setopt local_options no_notify no_monitor
  # if stdin containts no data, there's nothing to do
  [[ ! -t 0 ]] || return 1

  local zsh_plugins=()
  typeset -A repos
  local data parts repo instructions plugin branch subpath

  # handle both <redirected or piped| input
  # we need to loop twice - once to find all the git repos and clone them, and a second
  # time to bundle
  while read -r data; do
    # skip comments
    [[ $data != \#* ]] && [[ -n $data ]] || continue
    zsh_plugins+=($data)

    # split plugin from further instructions into array using space delimiter
    parts=(${(@s/ /)data})
    plugin=$parts[1]
    instructions=(${parts[@]:1})

    # for repos, we may need to clone before we can do other things
    # for plugins with a leading slash assume it's a path instead of a repo
    if [[ $plugin != \/* ]]; then
      branch=$instructions[(r)branch:*]
      branch="${branch#*branch:}"
      # clone in background if we didn't already cloned the repo this session
      # remember, the same plugin can have multiple instructions
      # (ie: ohmyzsh/ohmyzsh path:lib/clipboard.zsh)
      if [[ -z "$repos[$plugin]" ]]; then
        repos[$plugin]=true
        () { antidote-clone $plugin $branch; } &
      fi
    fi
  done

  # wait for clones to finish
  wait

  # bundle loop
  for data in $zsh_plugins; do
    # split plugin from further instructions into array using space delimiter
    parts=(${(@s/ /)data})
    plugin=$parts[1]
    instructions=(${parts[@]:1})

    # if kind:clone then we're done
    (( ! $instructions[(Ie)kind:clone] )) || continue

    # turn repos into plugin dirs
    if [[ $plugin != \/* ]]; then
      plugin=$ANTIDOTE_DIR/${plugin:t}
    fi

    # if 'path:*' instruction specified, we need a subdir or subfile of the plugin
    subpath=$instructions[(r)path:*]
    subpath="${subpath#*path:}"
    if [[ -n $subpath ]]; then
      plugin=$plugin/$subpath
    fi

    # if the plugin is just a file, source it and move to the next one
    if [[ -f $plugin ]]; then
      echo "source $plugin" && continue
    fi

    if [[ ! -d $plugin ]]; then
      echo "# ERROR: plugin directory not found $plugin" && continue
    fi

    if (( $instructions[(Ie)kind:fpath] )); then
      echo "fpath+=( $plugin )"
    elif (( $instructions[(Ie)kind:path] )); then
      echo "export PATH=\"$plugin:\$PATH\""
    else
      -antidote-initfile $plugin &>/dev/null
      [[ $? -eq 0 ]] || { echo "# ERROR: plugin init file not found '$plugin'." && continue }
      echo "fpath+=( $plugin )"
      if (( $instructions[(Ie)kind:defer] )); then
        echo "zsh-defer source $plugin/${plugin:t}.plugin.zsh"
      else
        echo "source $plugin/${plugin:t}.plugin.zsh"
      fi
    fi
  done
}

function antidote-loadall() {
  local plugin_init=$ANTIDOTE_DIR/init.zsh
  [[ -f $plugin_init ]] || antidote-reset
  source $plugin_init
}

function antidote-reset() {
  # write init.zsh which drives the plugin management
  [[ -d $ANTIDOTE_DIR ]] || mkdir -p $ANTIDOTE_DIR
  echo "# generated file... do not modify!" >| $ANTIDOTE_DIR/init.zsh

  # shameless copy from zgen
  # https://github.com/tarjoilija/zgen/blob/0b669d2d0dcf788b4c81a7a30b4fa41dfbf7d1a7/zgen.zsh#L263-L284
  local ages="$(stat -Lc "%Y" 2>/dev/null $ANTIDOTE_RESET_ON_CHANGE || \
                stat -Lf "%m" 2>/dev/null $ANTIDOTE_RESET_ON_CHANGE)"
  local shas="$(cksum ${ANTIDOTE_RESET_ON_CHANGE})"

  local initcode=(
    '# this file is generated!!! do not modify!!!'
    '# recompilation triggers'
    ''
    'read -rd "" ages <<AGES; read -rd "" shas <<SHAS'
    '{{ages}}'
    'AGES'
    '{{shas}}'
    'SHAS'
    ''
    'if [[ -n "$ANTIDOTE_RESET_ON_CHANGE" \'
    '      && "$(stat -Lc "%Y" 2>/dev/null $ANTIDOTE_RESET_ON_CHANGE || \'
    '            stat -Lf "%m"             $ANTIDOTE_RESET_ON_CHANGE)" != "$ages" \'
    '      && "$(cksum                     $ANTIDOTE_RESET_ON_CHANGE)" != "$shas" ]]'
    'then'
    '  echo ''plugin: file change detected in $ANTIDOTE_RESET_ON_CHANGE; resetting plugins files...'''
    '  plugin reset'
    'fi'
    'source $ANTIDOTE_DIR/bundle.zsh'
  )

  initcode=${initcode:gs/{{ages}}/$ages}
  initcode=${initcode:gs/{{shas}}/$shas}
  echo "$initcode" >| $ANTIDOTE_DIR/init.zsh
  # write out bundle.zsh which has the actual plugin instructions
  plugin bundle < ${ZDOTDIR:-~}/.zpluginrc >| $ANTIDOTE_DIR/bundle.zsh
}

function antidote() {
  local cmd=$1
  if (( $+functions[antidote-${cmd}] )); then
    shift
    antidote-${cmd} "$@"
    return $?
  else
    >&2 echo "The plugin command doesn't exist: '$1'."
    return 1
  fi
}

#!/usr/bin/env zsh
0=${(%):-%x}
BASEDIR=${0:A:h:h}

source $BASEDIR/tests/ztap/ztap3.zsh
ztap_header "${0:t:r}"

# setup
source $BASEDIR/antidote.zsh
ANTIDOTE_HOME=
OLD_ZDOTDIR=$ZDOTDIR
function git {
  @echo mockgit "$@"
}

function setup_plugin {
  ZDOTDIR=$BASEDIR/.cache/tests/plugin_setopts
  ANTIDOTE_HOME=$ZDOTDIR/antidote
  [[ -d $ANTIDOTE_HOME ]] && rm -rf $ANTIDOTE_HOME

  # create a fake plugin
  local bundledir="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
  mkdir -p $bundledir
  REPLY=$bundledir/bar.zsh
  touch $REPLY
  echo $REPLY
}

() {
  local expected actual output exitcode plugin_file REPLY

  # setup
  # for this test we need to set up a fake plugin, ANTIDOTE_HOME, and ZDOTDIR
  setup_plugin &>/dev/null
  plugin_file=$REPLY
  echo "unsetopt noaliases" >$plugin_file
  echo "setopt autocd" >>$plugin_file
  echo "foo/bar" >$ZDOTDIR/.zsh_plugins.txt
  @echo "ANTIDOTE_HOME $ANTIDOTE_HOME"
  @echo "ZDOTDIR $ZDOTDIR"

  # verify initial state
  setopt noaliases
  actual=($(set -o | grep noaliases))
  expected=(noaliases on)
  @test "starting state noaliases val='on'" "$expected" = "$actual"
  actual=($(set -o | grep autocd))
  expected=(autocd off)
  @test "starting state autocd val='off'" "$expected" = "$actual"

  # load the plugin and see if the option is now on
  antidote load &>/dev/null; exitcode=$?
  @test "'antidote load' succeeds" $exitcode -eq 0
  actual=($(set -o | grep noaliases))
  expected=(noaliases off)
  @test "'antidote load' changed noaliases to 'off'" "$expected" = "$actual"
  actual=($(set -o | grep autocd))
  expected=(autocd on)
  @test "'antidote load' changed autocd to 'on'" "$expected" = "$actual"

  # teardown
  setopt local_options
  ZDOTDIR=$OLD_ZDOTDIR
}

# Run this test last!
# It sets nearly every option
# Cue Clark Grizwold lighting ceremony!!!
() {
  local opt_cmds all_the_opts ignore_opts
  typeset -a opt_cmds=()
  typeset -A all_the_opts=($(set -o))
  typeset -a ignore_opts=(
    emacs
    forcefloat
    noglobalrcs
    interactive
    kshoptionprint
    localoptions
    login
    monitor
    noexec
    norcs
    priviledged
    nopromptpercent
    restricted
    shinstdin
    singlecommand
    sourcetrace
    verbose
    vi
    xtrace
    zle
  )

  local key val
  for key val in "${(@kv)all_the_opts}"; do
    (($ignore_opts[(Ie)$key])) && continue
    if [[ "$val" == "off" ]]; then
      opt_cmds+=("setopt $key")
    else
      opt_cmds+=("unsetopt $key")
    fi
  done

  # generate a foo/bar plugin that sets all the options
  setup_plugin &>/dev/null
  local plugin_file=$REPLY
  printf "%s\n" ${(o)opt_cmds} >$plugin_file
  echo "foo/bar" >$ZDOTDIR/.zsh_plugins.txt

  local actual exitcode
  actual=($(setopt | wc -l))
  @test "few enabled options ($actual)" $actual -lt 10

  antidote load 2>&1; exitcode=$?
  @test "'antidote load' succeeds" $exitcode -eq 0

  actual=($(setopt | wc -l))
  setopt local_options
  @test "zillions of enabled options ($actual)" $actual -gt 150

  # teardown
  ZDOTDIR=$OLD_ZDOTDIR
}

ztap_footer

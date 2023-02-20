#!/usr/bin/env zsh
0=${(%):-%N}

fpath+=( ${0:A:h:h}/functions )
autoload -Uz $fpath[-1]/*(N.:t)
t_setup_ztap

() {
  local expected actual output exitcode plugin_file REPLY

  # setup: for this test we need to set up a fake plugin, ANTIDOTE_HOME, and ZDOTDIR
  t_setup
  plugin_file=$ZDOTDIR/antidote_home/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar/bar.plugin.zsh
  echo "unsetopt noaliases" >$plugin_file
  echo "setopt autocd" >>$plugin_file
  echo "foo/bar" >$ZDOTDIR/.zsh_plugins.txt

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
  t_teardown
}

() {
  t_setup
  setopt posix_identifiers
  local stderr exitcode

  stderr=$(antidote -v 3>&1 1>/dev/null 2>&3)
  exitcode=$?
  @test "'antidote -v' succeeds with 'setopt posix_identifiers'" "$exitcode" -eq 0
  @test "'antidote -v' empty stderr with 'setopt posix_identifiers'" "$stderr" = ""

  stderr=$(antidote -h 3>&1 1>/dev/null 2>&3)
  exitcode=$?
  @test "'antidote -h' succeeds with 'setopt posix_identifiers'" "$exitcode" -eq 0
  @test "'antidote -h' empty stderr with 'setopt posix_identifiers'" "$stderr" = ""

  stderr=$(antidote help 3>&1 1>/dev/null 2>&3)
  exitcode=$?
  @test "'antidote help' succeeds with 'setopt posix_identifiers'" "$exitcode" -eq 0
  @test "'antidote help' empty stderr with 'setopt posix_identifiers'" "$stderr" = ""

  # teardown
  setopt local_options
  t_teardown
}

# Run this test last!
# It sets nearly every option
# Cue Clark Grizwold lighting ceremony!!!
() {
  t_setup
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
  local plugin_file=$ZDOTDIR/antidote_home/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar/bar.plugin.zsh
  printf "%s\n" ${(o)opt_cmds} >$plugin_file
  echo "foo/bar" >$ZDOTDIR/.zsh_plugins.txt

  local actual exitcode
  actual=($(setopt | wc -l))
  @test "few enabled options (<10)" $actual -lt 10

  antidote load 2>&1; exitcode=$?
  actual=($(setopt | wc -l))

  setopt NO_posixstrings
  @test "'antidote load' succeeds" $exitcode -eq 0
  @test "zillions of enabled options (>150)" $actual -gt 150

  # teardown
  setopt local_options
  t_teardown
}

ztap_footer

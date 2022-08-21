#!/usr/bin/env zsh
0=${(%):-%x}
BASEDIR=${0:A:h:h}

source $BASEDIR/tests/ztap/ztap3.zsh
ztap_header "${0:t:r}"

expected_cmds=(
  bundle
  help
  home
  init
  install
  list
  load
  path
  purge
  update
)

() {
  local cmd
  for cmd in $expected_cmds; do
    @test "antidote command not yet defined: '$cmd'" $+functions[antidote-$cmd] -eq 0
  done
}

() {
  local cmd
  source $BASEDIR/antidote.zsh
  for cmd in $expected_cmds; do
    @test "antidote command defined: '$cmd'" $+functions[antidote-$cmd] -eq 1
  done
}

ztap_footer

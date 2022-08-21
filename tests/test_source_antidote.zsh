#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
ANTIDOTE_HOME=$BASEDIR/tests/fakezdotdir/antidote_home

() {
  @test "antidote function not yet defined" $+functions[antidote] -eq 0
}

() {
  source $BASEDIR/antidote.zsh
  @test "sourcing antidote.zsh succeeds" $? -eq 0
  @test "antidote function defined" $+functions[antidote] -eq 1
}

ztap_footer

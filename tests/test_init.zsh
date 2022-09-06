#!/usr/bin/env zsh

0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
source $BASEDIR/antidote.zsh

# -h|--help
() {
  antidote init -h &>/dev/null
  @test "'antidote init -h' succeeds" "$?" -eq 0
  antidote init --help &>/dev/null
  @test "'antidote init --help' succeeds" "$?" -eq 0
}

ztap_footer

#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
source $BASEDIR/antidote.zsh
@echo "ZSH_VERSION: $ZSH_VERSION"

() {
  antidote -v &>/dev/null
  @test "'antidote -v' succeeds" "$?" -eq 0
}

() {
  antidote --version &>/dev/null
  @test "'antidote --version' succeeds" $? -eq 0
}

() {
  local expected actual gitsha
  gitsha=$(git -C "$BASEDIR" rev-parse --short HEAD 2>/dev/null)
  expected="antidote version 1.6.3 ($gitsha)"
  actual="$(antidote -v 2>&1)"
  @test "'antidote -v' prints '$expected'" $expected = $actual
  @test "'-v' and '--version' print identical outputs" "$actual" = "$(antidote --version 2>&1)"
}

ztap_footer

#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# Tests for lazy-loading antidote
# https://github.com/mattmc3/antidote/issues/54

() {
  autoload -Uz $BASEDIR/functions/antidote
  antidote -v &>/dev/null
  @test "'antidote' succeeds with a lazy loaded config" "$?" -eq 0
}

ztap_footer

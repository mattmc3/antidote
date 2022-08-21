#!/usr/bin/env zsh

# bundles is just an alias for bundle, so we just need to test that it exists and
# calls 'bundle' for its actual behavior.
# Everything else should be tested in 'antidote bundle' tests.

0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
ZSHDIR=$BASEDIR/tests/fakezdotdir
function git {
  @echo mockgit "$@"
}
ANTIDOTE_HOME=$BASEDIR/tests/fakezdotdir/antidote_home
source $BASEDIR/antidote.zsh

() {
  antidote bundles &>/dev/null
  @test "'antidote bundles' succeeds" $? -eq 0
}

# bundles shortrepo
() {
  local actual expected bundle bundledir
  bundle="foo/bar"
  bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
  expected=(
    "fpath+=( $ANTIDOTE_HOME/$bundledir )"
    "source $ANTIDOTE_HOME/$bundledir/${bundle:t}.plugin.zsh"
  )
  actual=("${(@f)$(antidote bundles $bundle)}")
  @test "bundles shortrepo: '$bundle'" "$expected" = "$actual"
}

ztap_footer

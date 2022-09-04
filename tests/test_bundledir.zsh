#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
ANTIDOTE_HOME=$BASEDIR/tests/fakezdotdir/antidote_home
source $BASEDIR/antidote.zsh
zstyle ':antidote:bundle' use-friendly-names on

() {
  typeset -A repos=(
    foo/bar                     foo/bar
    http://github.com/bar/baz   bar/baz
    git@github.com:baz/qux.git  baz/qux
  )

  local bundle expected
  for bundle expected in ${(kv)repos}; do
    actual=$(__antidote_friendlyname $bundle)
    @test "friendlyname '$bundle' => $expected" "$actual" = "$ANTIDOTE_HOME/$expected"
  done
}

ztap_footer

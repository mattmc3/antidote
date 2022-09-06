#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
ANTIDOTE_HOME=$BASEDIR/tests/fakezdotdir/antidote_home
source $BASEDIR/antidote.zsh

() {
  local actual expected bundle
  local repos=(
    foo/bar
    https://github.com/foo/bar
    https://github.com/foo/bar.git
    git@github.com:foo/bar.git
  )

  for bundle in $repos; do
    if [[ $bundle = git@* ]]; then
      expected="git-AT-github.com-COLON-foo-SLASH-bar"
    else
      expected="https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
    fi
    actual=$(__antidote_bundledir $bundle)
    @test "'__antidote_bundledir $bundle' => $expected" "$actual" = "$ANTIDOTE_HOME/$expected"
  done

  # teardown
  zstyle -d ':antidote:bundle' use-friendly-names
}

# friendly name
() {
  local actual expected bundle repos
  typeset -A repos=(
    foo/bar                     foo/bar
    git@github.com:bar/baz.git  bar/baz
    https://github.com/baz/qux  baz/qux
  )

  zstyle ':antidote:bundle' use-friendly-names on
  for bundle expected in ${(kv)repos}; do
    actual=$(__antidote_bundledir $bundle)
    @test "'__antidote_bundledir $bundle' friendly-mode => $expected" "$actual" = "$ANTIDOTE_HOME/$expected"
  done

  # teardown
  zstyle -d ':antidote:bundle' use-friendly-names
}

ztap_footer

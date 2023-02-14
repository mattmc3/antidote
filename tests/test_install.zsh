#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
source $BASEDIR/antidote.zsh
function git { mockgit "$@" }

# -h|--help
() {
  antidote install -h &>/dev/null
  @test "'antidote install -h' succeeds" "$?" -eq 0
  antidote install --help &>/dev/null
  @test "'antidote install --help' succeeds" "$?" -eq 0
}

() {
  local actual expected exitcode

  setup_emptyzdotdir "install"
  local bundle="foo/bar"
  local bundledir="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
  local bundlefile="$ZDOTDIR/.zsh_plugins.txt"

  @test ".zsh_plugins.txt does not exist" ! -e $bundlefile
  @test "bundle '${bundledir:t}' dir does not exist" ! -e $bundledir

  expected=(
    "# antidote cloning foo/bar..."
    "Adding bundle to '$bundlefile':"
    "foo/bar"
  )
  actual=($(antidote install $bundle 2>&1)); exitcode=$?
  actual=("${(@f)actual}")

  @test "'antidote install $bundle' succeeded" $exitcode -eq 0
  @test "'antidote install $bundle' output correct" "$expected" = "$actual"

  @test "bundle '${bundledir:t}' dir exists" -e $bundledir
  @test ".zsh_plugins.txt exists" -e $bundlefile

  expected=( 'foo/bar' )
  actual=("${(f)"$(<$bundlefile)"}")
  @test "bundle file contains newly installed bundle" "$expected" = "$actual"

  # install a second bundle
  bundle="git@github.com:bar/baz"
  bundledir="$ANTIDOTE_HOME/git-AT-github.com-COLON-bar-SLASH-baz"
  @test "bundle '${bundledir:t}' dir does not exist" ! -e $bundledir
  antidote install $bundle &>/dev/null; exitcode=$?
  @test "bundle '${bundledir:t}' dir exists" -e $bundledir
  expected=(
    'foo/bar'
    'git@github.com:bar/baz'
  )
  actual=("${(f)"$(<$bundlefile)"}")
  @test "bundle file contains newly installed bundle" "$expected" = "$actual"

  # teardown
  ZDOTDIR=$OLD_ZDOTDIR
}

ztap_footer

# teardown
unfunction git

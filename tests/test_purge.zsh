#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
ANTIDOTE_HOME=$BASEDIR/tests/fakezdotdir/antidote_home
source $BASEDIR/antidote.zsh

# purge missing arg
() {
  local actual expected exitcode
  expected="antidote: error: required argument 'bundle' not provided, try --help"
  actual=$(antidote purge 2>&1)
  exitcode=$?
  @test "'antidote purge' with no args fails" $exitcode -ne 0
  @test "'antidote purge' with no args fail message" "$expected" = "$actual"
}

# purge missing bundle
() {
  # test with repo arg but repo does not exist
  local actual expected exitcode bundle bundledir
  bundle="bar/foo"
  bundledir="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-bar-SLASH-foo"
  expected="antidote: error: $bundle does not exist at the expected location: $bundledir"

  actual=$(antidote purge $bundle 2>&1)
  exitcode=$?
  @test "'antidote purge' missing bundle exit code" $exitcode -ne 0
  @test "'antidote purge' missing bundle fail message" "$expected" = "$actual"
}

# antidote purge removes dir and comments out bundle
() {
  local actual exitcode bundle bundledir
  local pluginsfile expectedfile diffout

  setup_fakezdotdir purge
  bundle="foo/bar"
  bundledir="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
  pluginsfile=${ZDOTDIR:-~}/.zsh_plugins.txt
  expectedfile=$FAKEZDOTDIR/.zsh_plugins_after_purge.txt

  # we don't need to test this, but it helps tell the test story
  @test "purge setup: bundle dir exists" -d "$bundledir"

  actual=$(antidote purge foo/bar 2>&1); exitcode=$?
  @test "'antidote purge foo/bar' succeeds" $exitcode -eq 0
  @test "'antidote purge foo/bar' bundle dir removed" ! -d "$bundledir"

  diffout=$(diff $pluginsfile $expectedfile); exitcode=$?
  @test "'antidote purge foo/bar' file diff succeeds" $exitcode -eq 0
  @test "'antidote purge foo/bar' commented out bundlefile correctly" -z "$diffout"

  # teardown
  ZDOTDIR=$OLD_ZDOTDIR
}

# antidote purge --all
() {
  local actual expected exitcode bundle bundledir
  local -a bakfiles

  # to test purging all bundles, we've got to make a full fake zdotdir
  setup_fakezdotdir purge_all
  local pluginsfile=${ZDOTDIR:-~}/.zsh_plugins.txt

  zstyle ':antidote:purge:all' answer 'n'
  actual=$(antidote purge --all 2>&1)
  exitcode=$?
  @test "'antidote purge --all' with answer=no fails" $exitcode -ne 0

  bakfiles=($ZDOTDIR/.zsh_plugins.*.bak(N))
  @test "No backup zsh_plugins file exists" $#bakfiles -eq 0

  zstyle ':antidote:purge:all' answer 'y'
  actual=$(antidote purge --all 2>&1)
  exitcode=$?
  @test "'antidote purge --all' with answer=yes succeeds" $exitcode -eq 0
  bakfiles=($ZDOTDIR/.zsh_plugins.*.bak(N))
  @test "A backup zsh_plugins file exists" $#bakfiles -eq 1

  # clean up
  zstyle -d ':antidote:purge:all' answer
}

ztap_footer

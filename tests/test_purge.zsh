#!/usr/bin/env zsh
0=${(%):-%x}
BASEDIR=${0:A:h:h}

source $BASEDIR/tests/ztap/ztap3.zsh
ztap_header "${0:t:r}"

# setup
ANTIDOTE_HOME=$BASEDIR/tests/fakezdotdir/antidote_home
source $BASEDIR/antidote.zsh

() {
  # test with no arg
  local actual expected exitcode
  expected="antidote: error: required argument 'bundle' not provided, try --help"
  actual=$(antidote purge 2>&1)
  exitcode=$?
  @test "'antidote purge' with no args fails" $exitcode -ne 0
  @test "'antidote purge' with no args fail message" "$expected" = "$actual"
}

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

() {
  local actual expected exitcode bundle bundledir

  # test actually purging a bundle
  # for this we just need to set up a fake ANTIDOTE_HOME so we can purge it
  ANTIDOTE_HOME=$BASEDIR/.cache/tests/purge
  [[ -d $ANTIDOTE_HOME ]] && rm -rf $ANTIDOTE_HOME

  bundle="foo/bar"
  bundledir="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"

  # we don't need to test this, but it makes for a nice test output story
  @test "purge setup: bundle directory does not exist" ! -d "$bundledir"
  mkdir -p $bundledir
  @test "purge setup: bundle directory exists" -d "$bundledir"

  # purge!
  actual=$(antidote purge $bundle 2>&1)
  exitcode=$?
  @test "'antidote purge' existing bundle succeeds" $exitcode -eq 0
  @test "'antidote purge' existing bundle correctly removed" ! -d "$bundledir"
}

ztap_footer

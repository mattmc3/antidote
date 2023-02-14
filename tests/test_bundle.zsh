#!/usr/bin/env zsh

# Many 'bundle' tests could just as well just be 'script' tests, so we rely on
# 'test_script.zsh' to find scripting issues and use this to test actual bundling,
# or things not handled by 'antidote script'. You can think of 'antidote script' as
# handling a single bundle, and 'antidote bundle' handling them in bulk.

0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
ZSHDIR=$BASEDIR/tests/zdotdir
function git { @echo mockgit "$@" }
ANTIDOTE_HOME=$BASEDIR/tests/zdotdir/antidote_home
source $BASEDIR/antidote.zsh

# empty bundle command succeeds
() {
  antidote bundle &>/dev/null
  @test "'antidote bundle' succeeds" $? -eq 0
}

# -h|--help
() {
  antidote bundle -h &>/dev/null
  @test "'antidote bundle -h' succeeds" "$?" -eq 0
  antidote bundle --help &>/dev/null
  @test "'antidote bundle --help' succeeds" "$?" -eq 0
}

# bundle annotation kind:defer
() {
  local actual expected
  local bundle="foo/bar kind:defer"
  local defer_dir='https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer'
  local foobar_dir='https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar'
  expected=(
    "if ! (( \$+functions[zsh-defer] )); then"
    "  fpath+=( \$ANTIDOTE_HOME/$defer_dir )"
    "  source \$ANTIDOTE_HOME/$defer_dir/zsh-defer.plugin.zsh"
    "fi"
   "fpath+=( \$ANTIDOTE_HOME/$foobar_dir )"
   "zsh-defer source \$ANTIDOTE_HOME/$foobar_dir/bar.plugin.zsh"
  )
  actual=("${(@f)$(antidote bundle $bundle)}")
  actual=("$(echo $actual | sed "s|$ANTIDOTE_HOME|\$ANTIDOTE_HOME|g")")
  @test "bundle annotation kind:defer: '$bundle'" "$expected" = "$actual"
}

# bundle annotation kind:autoload
() {
  local actual expected bundle exitcode
  local bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-baz-SLASH-qux"
  expected=(
    "fpath+=( $ANTIDOTE_HOME/$bundledir/functions )"
    "autoload -Uz \$fpath[-1]/*(N.:t)"
  )

  bundle="baz/qux path:functions kind:autoload"
  actual=("${(@f)$(antidote bundle $bundle)}")
  @test "bundle annotation kind:autoload" "$expected" = "$actual"
}

# bundle annotation conditionals
() {
  local actual expected bundle exitcode
  local bundledir="https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar"
  expected=(
    "if is-macos; then"
    "  fpath+=( $ANTIDOTE_HOME/$bundledir )"
    "  source $ANTIDOTE_HOME/$bundledir/bar.plugin.zsh"
    "fi"
  )

  bundle="foo/bar conditional:is-macos"
  actual=("${(@f)$(antidote bundle $bundle)}")
  @test "bundle annotation conditional" "$expected" = "$actual"
}

# full bundling with redirection
() {
  local expected actual exitcode
  local pluginsfile staticfile expectedfile diffout repodirs branched_plugin

  setup_fakezdotdir bundle2
  source $BASEDIR/antidote.zsh
  pluginsfile=${ZDOTDIR:-~}/.zsh_plugins.txt
  staticfile=${ZDOTDIR:-~}/.zsh_plugins.zsh
  expectedfile=$FAKEZDOTDIR/.zsh_plugins_expected.zsh

  @test "static cache file does not exist" ! -f "$staticfile"
  antidote bundle <$pluginsfile >$staticfile 2>/dev/null
  exitcode=$?
  @test "redirection: 'antidote bundle <~/.zsh_plugins.txt >~/.zsh_plugins.zsh' succeeds!" $exitcode -eq 0

  @test "static cache file exists" -f "$staticfile"
  [[ -f "$staticfile" ]] || return
  sed-i "s|$ANTIDOTE_HOME|\$ANTIDOTE_HOME|g" "$staticfile"
  diffout=$(diff $staticfile $expectedfile)
  @test "'antidote bundle' redirection: static file diff succeeds" $exitcode -eq 0
  @test "'antidote bundle' redirection: static file diff shows no differences" -z "$diffout"
}

ztap_footer

# teardown
unfunction git

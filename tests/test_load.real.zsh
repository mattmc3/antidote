#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

() {
  local expected actual exitcode
  local stdout staticfile expectedfile diffout repodirs clonelist

  setup_realzdotdir load1
  source $BASEDIR/antidote.zsh
  staticfile=${ZDOTDIR:-~}/.zsh_plugins.zsh
  expectedfile=$REALZDOTDIR/zsh_plugins_expected.zsh
  clonelist=$REALZDOTDIR/zsh_plugins_repolist.txt

  @test "static cache file does not exist" ! -f "$staticfile"
  repodirs=($(ls $ANTIDOTE_HOME))
  @test "\$ANTIDOTE_HOME is empty" $#repodirs -eq 0

  stdout=$(antidote load 2>/dev/null)
  exitcode=$?
  @test "antidote load succeeds" $exitcode -eq 0
  @test "antidote load produces no stdout" -z "$stdout"
  @test "static cache file exists" -f "$staticfile"
  [[ -f "$staticfile" ]] || @bailout "No further 'antidote load' tests can run"
  sed -i '' "s|$ANTIDOTE_HOME|\$ANTIDOTE_HOME|g" $staticfile
  diffout=$(diff $staticfile $expectedfile)
  @test "static file diff succeeds" $exitcode -eq 0
  @test "static file diff shows no differences" -z "$diffout"

  repodirs=($(ls $ANTIDOTE_HOME))
  expected=$(wc -l <$clonelist | tr -d ' ')
  @test "\$ANTIDOTE_HOME has $expected repos" $#repodirs -eq $expected
}

ztap_footer

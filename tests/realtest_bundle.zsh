#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

() {
  local expected actual exitcode
  local pluginsfile staticfile expectedfile diffout repodirs clonelist branched_plugin

  setup_realzdotdir bundle1
  source $BASEDIR/antidote.zsh
  pluginsfile=${ZDOTDIR:-~}/.zsh_plugins.txt
  staticfile=${ZDOTDIR:-~}/.zsh_plugins.zsh
  expectedfile=$REALZDOTDIR/zsh_plugins_expected.zsh
  clonelist=$REALZDOTDIR/zsh_plugins_repolist.txt

  @test "static cache file does not exist" ! -f "$staticfile"
  repodirs=($(ls $ANTIDOTE_HOME))
  @test "\$ANTIDOTE_HOME is empty" $#repodirs -eq 0

  antidote bundle <$pluginsfile >$staticfile 2>/dev/null
  exitcode=$?
  @test "antidote bundle succeeds" $exitcode -eq 0

  sed -i '' "s|$ANTIDOTE_HOME|\$ANTIDOTE_HOME|g" $staticfile
  diffout=$(diff $staticfile $expectedfile)
  @test "static file diff succeeds" $exitcode -eq 0
  @test "static file diff shows no differences" -z "$diffout"

  repodirs=($(ls $ANTIDOTE_HOME))
  expected=$(wc -l <$clonelist | tr -d ' ')
  @test "\$ANTIDOTE_HOME has $expected repos" $#repodirs -eq $expected

  branched_plugin="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-mattmc3-SLASH-antidote"
  actual="$(git -C $branched_plugin branch --show-current 2>/dev/null)"
  expected="pz"
  @test "'antidote bundle' switches branches properly" "$expected" = "$actual"
}

ztap_footer

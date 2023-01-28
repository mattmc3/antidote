#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# bundle static bundle file
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

  sed-i "s|$ANTIDOTE_HOME|\$ANTIDOTE_HOME|g" $staticfile
  diffout=$(diff $staticfile $expectedfile)
  exitcode=$?
  @test "static file diff succeeds" $exitcode -eq 0
  @test "static file diff shows no differences" -z "$diffout"

  repodirs=($(ls $ANTIDOTE_HOME))
  expected=$(wc -l <$clonelist | tr -d ' ')
  @test "\$ANTIDOTE_HOME has $expected repos" $#repodirs -eq $expected
  if [[ $#repodirs -ne $expected ]]; then
    @echo "Cloned repos..."
    local d; for d in $repodirs; do @echo $d; done
  fi

  branched_plugin="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-mattmc3-SLASH-antidote"
  actual="$(git -C $branched_plugin branch --show-current 2>/dev/null)"
  expected="pz"
  @test "'antidote bundle' switches branches properly" "$expected" = "$actual"
}

# bundle heredoc
() {
  local actual expected
  setup_realzdotdir bundle2

  actual=$(antidote bundle 2>/dev/null <<EOBUNDLES
  zsh-users/zsh-autosuggestions             # regular plugins
  ohmyzsh/ohmyzsh path:plugins/magic-enter  # path annotation
  https://github.com/zsh-users/zsh-history-substring-search  # URLs
  zdharma-continuum/fast-syntax-highlighting kind:defer      # deferred plugins
EOBUNDLES
)

  expected=$(cat <<EOS
if ! (( \$+functions[zsh-defer] )); then
  fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer )
  source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/magic-enter )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/magic-enter/magic-enter.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-history-substring-search )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-history-substring-search/zsh-history-substring-search.plugin.zsh
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zdharma-continuum-SLASH-fast-syntax-highlighting )
zsh-defer source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-zdharma-continuum-SLASH-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
EOS
)

  @test "'antidote bundle' heredoc works" "$expected" = "$actual"
}

ztap_footer

0=${(%):-%x}
@echo "=== ${0:t:r} ==="

zstyle ':antidote:tests' disable-git-mock 'yes'

autoload -Uz ${0:a:h}/functions/setup && setup

# different mocks
function git {
  echo >&2 "# real git $@"
  command git "$@"
}

ZSH_PLUGINS_TXT=${0:a:h}/misc/real_plugins.txt
ZSH_PLUGINS_ZSH=${ZSH_PLUGINS_TXT:r}.zsh

actual_repos=($ANTIDOTE_HOME/*(N/))
@test "nothing has been cloned" $#actual_repos -eq 0

# we need to redirect @echo fd3 output to somewhere
# logs, /dev/null, &1...
3>$ZTAP_LOG_HOME/${0:t:r}.git.log 2>$ZTAP_LOG_HOME/${0:t:r}.err antidote bundle <$ZSH_PLUGINS_TXT >/dev/null
@test "real 'antidote bundle' succeeded" $? -eq 0

actual_repo_count=$(ls $ANTIDOTE_HOME 2>/dev/null | wc -l | tr -d ' ')
expected_repo_count=$(cat ${0:a:h}/misc/real_clonelist.txt | wc -l | tr -d ' ')
@test "all $expected_repo_count repos have been cloned" $actual_repo_count -eq $expected_repo_count

STATICFILE=$ZTAP_LOG_HOME/${0:t:r}.actual.log
3>$ZTAP_LOG_HOME/${0:t:r}_2.git.log 2>$ZTAP_LOG_HOME/${0:t:r}_2.err antidote bundle <$ZSH_PLUGINS_TXT >$STATICFILE
sed -i '' "s|$ANTIDOTE_HOME|\$ANTIDOTE_HOME|g" $STATICFILE

branched_plugin="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-mattmc3-SLASH-antidote"
actual="$(git -C $branched_plugin branch --show-current 2>/dev/null)"
expected="pz"
@test "'antidote bundle' switches branches properly" "$expected" = "$actual"

actual=("${(f)$(<$STATICFILE)}")
expected=("${(f)$(<$ZSH_PLUGINS_ZSH)}")
@test "antidote bundle produces the expected output line count" $#expected -eq $#actual

# debuging help - let's not spam the output with the gory details
if [[ "$expected" = "$actual" ]]; then
  @test "antidote bundle produces the expected output" 1 -eq 1
else
  @test "antidote bundle produces the expected output" "compare $ZSH_PLUGINS_TXT" = "to $STATICFILE"
fi

# antidote list
# @echo $ANTIDOTE_HOME

teardown

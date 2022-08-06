0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup

# remove mock git
unfunction git

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

actual=("${(f)$(<$STATICFILE)}")
expected=("${(f)$(<$ZSH_PLUGINS_ZSH)}")
expected=(${expected//\$ANTIDOTE_HOME/$ANTIDOTE_HOME})

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

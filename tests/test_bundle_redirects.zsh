0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup
ZSH_PLUGINS_TXT=${0:a:h}/misc/zsh_plugins.txt
ZSH_PLUGINS_ZSH=${ZSH_PLUGINS_TXT:r}.zsh

# you can regenerate the .zsh file with this statement
# remember to use git diff to verify the output
# antidote bundle <$ZSH_PLUGINS_TXT >$ZSH_PLUGINS_ZSH 2>/dev/null
# sed -i '' "s|$ANTIDOTE_HOME|\$ANTIDOTE_HOME|g" $ZSH_PLUGINS_ZSH

actual_repos=($ANTIDOTE_HOME/*(N/))
@test "nothing has been cloned" $#actual_repos -eq 0

# we need to redirect @echo fd3 output to somewhere
# logs, /dev/null, &1...
3>$ZTAP_LOG_HOME/${0:t:r}.git.log 2>$ZTAP_LOG_HOME/${0:t:r}.err antidote bundle <$ZSH_PLUGINS_TXT >/dev/null
@test "antidote bundle succeeds" $? -eq 0

actual_repos=($ANTIDOTE_HOME/*(N/))
expected_repos=($TEST_HOME/fakerepos/*/*(N/))
@test "all repos have been cloned" $#actual_repos -eq $#expected_repos

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

teardown

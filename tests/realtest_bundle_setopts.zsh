0=${(%):-%x}
@echo "=== ${0:t:r} ==="

zstyle ':antidote:tests' disable-git-mock 'yes'

autoload -Uz ${0:a:h}/functions/setup && setup

# remove mocks
function git {
  echo >&2 "real git $@"
  command git "$@"
}

# set options that break things
# https://github.com/mattmc3/antidote/issues/36
# https://github.com/mattmc3/antidote/issues/28
setopt sh_word_split

ZSH_PLUGINS_TXT=${0:a:h}/misc/real_plugins.txt
ZSH_PLUGINS_ZSH=${ZSH_PLUGINS_TXT:r}.zsh

actual_repos=($ANTIDOTE_HOME/*(N/))
@test "nothing has been cloned" $#actual_repos -eq 0

STATICFILE=$ZTAP_LOG_HOME/${0:t:r}.actual.log
antidote bundle <$ZSH_PLUGINS_TXT >$STATICFILE 2>$ZTAP_LOG_HOME/${0:t:r}_2.err 3>$ZTAP_LOG_HOME/${0:t:r}_2.git.log
sed -i '' "s|$ANTIDOTE_HOME|\$ANTIDOTE_HOME|g" $STATICFILE

actual=("${(f)$(<$STATICFILE)}")
expected=("${(f)$(<$ZSH_PLUGINS_ZSH)}")
@test "antidote bundle produces the expected output line count" $#expected -eq $#actual

# debuging help - let's not spam the output with the gory details
if [[ "$expected" = "$actual" ]]; then
  @test "antidote bundle produces the expected output" 1 -eq 1
else
  @test "antidote bundle produces the expected output" "compare $ZSH_PLUGINS_TXT" = "to $STATICFILE"
fi

teardown

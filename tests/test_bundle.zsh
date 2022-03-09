0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup

source $PRJ_HOME/antidote.zsh
ZSH_PLUGINS_TXT=${0:a:h}/misc/zsh_plugins.txt
ZSH_PLUGINS_ZSH=${ZSH_PLUGINS_TXT:r}.zsh

# mocks
function _antidote_gitclone { _mock_gitclone "$@" }

antidote bundle <$ZSH_PLUGINS_TXT >| $PRJ_HOME/.cache/bundle_actual.txt
@test "antidote bundle succeeds" $? -eq 0

actual=("${(@f)$(antidote bundle <$ZSH_PLUGINS_TXT)}")
expected=("${(f)"$(<$ZSH_PLUGINS_ZSH)"}")
expected=(${expected//\$ANTIDOTE_HOME/$ANTIDOTE_HOME})

@test "antidote bundle produces the expected output line count" $#expected -eq $#actual

# debuging help
if [[ "$expected" != "$actual" ]]; then
  @test "antidote bundle produces the expected output" "see bundle_expected.txt" = "see bundle_actual.txt"
  printf "%s\n" "${expected[@]}" >| $PRJ_HOME/.cache/bundle_expected.txt
  printf "%s\n" "${actual[@]}" >| $PRJ_HOME/.cache/bundle_actual.txt
fi

teardown

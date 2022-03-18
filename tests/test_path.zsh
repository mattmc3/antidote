0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup
source $PRJ_HOME/antidote.zsh

repo="ohmyzsh/ohmyzsh"

antidote path $repo &>/dev/null
@test "'antidote path' fails when a bundle doesn't exist" $? -ne 0

expected="antidote: error: $repo does not exist in cloned paths"
actual=$(antidote path $repo 2>&1)
@test "'antidote path' fails with the expected message" "$expected" = "$actual"

# mock so we don't actually clone a repo
function _antidote_gitclone { _mock_gitclone "$@" }

# we need to redirect fd3 to somewhere when we mock cloning
# Also, we aren't testing 'antidote bundle' here - we already have tests for that.
# For this, we just need it to mock-clone so we can test the path command
3>/dev/null antidote bundle $repo &>/dev/null
@test "antidote bundle succeeded" $? -eq 0

antidote path $repo &>/dev/null
@test "'antidote path' succeeds when a bundle exists" $? -eq 0

expected="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh"
actual=$(antidote path $repo 2>&1)
@test "'antidote path' succeeds with the expected path output" "$expected" = "$actual"

teardown

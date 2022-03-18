0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup
source $PRJ_HOME/antidote.zsh

# mock so we don't accidentally clone a real repo
function _antidote_gitclone { _mock_gitclone "$@" }

# test with no arg
expected="antidote: error: required argument 'bundle' not provided, try --help"
actual=$(antidote purge 2>&1)
@test "'antidote purge' with no args fails" "$expected" = "$actual"

# test with repo arg but repo does not exist
repo="ohmyzsh/ohmyzsh"
bundledir="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh"

antidote purge $repo &>/dev/null
@test "'antidote purge' fails when a bundle doesn't exist" $? -ne 0

expected="antidote: error: $repo does not exist at the expected location: $bundledir"
actual=$(antidote purge $repo 2>&1)
@test "'antidote purge' fails with the expected message" "$expected" = "$actual"

# we need to redirect fd3 to somewhere when we mock cloning
# Also, we aren't testing 'antidote bundle' here - we already have tests for that.
# For this, we just need it to mock-clone so we can test the purge command
@test "bundle directory does not exist yet" ! -d "$bundledir"
3>/dev/null antidote bundle $repo &>/dev/null
@test "antidote bundle succeeded" $? -eq 0
@test "bundle directory exists" -d "$bundledir"

antidote purge $repo &>/dev/null
@test "'antidote purge' succeeds when a bundle exists" $? -eq 0
@test "bundle directory was actually removed" ! -d "$bundledir"

teardown

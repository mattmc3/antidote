0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup

@test "sourcing antidote.zsh succeeds" $? -eq 0

antidote -v &>/dev/null
@test "antidote -v succeeds" $? -eq 0

antidote --version &>/dev/null
@test "antidote --version succeeds" $? -eq 0

gitsha=$(git -C "$PRJ_HOME" rev-parse --short HEAD 2>/dev/null)
expected_ver="antidote version 1.4.0 ($gitsha)"
actual_ver="$(antidote -v)"

@test "antidote version is correct" "$expected_ver" = "$actual_ver"

teardown

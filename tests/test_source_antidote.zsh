0=${(%):-%x}
@echo "=== ${0:t:r} ==="

PRJ_HOME=${0:A:h:h}

@test "antidote function not yet defined" $+functions[antidote] -eq 0

source $PRJ_HOME/antidote.zsh
@test "sourcing antidote.zsh succeeds" $? -eq 0
@test "antidote function defined" $+functions[antidote] -eq 1

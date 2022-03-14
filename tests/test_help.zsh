0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup
source $PRJ_HOME/antidote.zsh
@test "sourcing antidote.zsh succeeds" $? -eq 0

antidote -h &>/dev/null
@test "antidote -h succeeds" $? -eq 0

antidote --help &>/dev/null
@test "antidote --help succeeds" $? -eq 0

cmds=('' bundle help home init install list load path purge update)
for c in $cmds; do
  actual_help=("${(@f)$(antidote -h $c 2>&1)}")
  @test "antidote help text exists for '$c'" "${#actual_help}" -gt 3
done

badcmds=(foo bar baz)
for c in $badcmds; do
  actual_help=("${(@f)$(antidote -h $c 2>&1)}")
  @test "antidote help should not exist for '$c'" "${#actual_help}" -eq 1
done

teardown

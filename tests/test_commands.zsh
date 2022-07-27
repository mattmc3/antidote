0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup --no-source

expected_cmds=(
  bundle
  help
  home
  init
  install
  list
  load
  path
  purge
  update
)

for cmd in $expected_cmds; do
  @test "antidote command not yet defined: '$cmd'" $+functions[antidote-$cmd] -eq 0
done

source $PRJ_HOME/antidote.zsh
@test "sourcing antidote.zsh succeeds" $? -eq 0

for cmd in $expected_cmds; do
  @test "antidote command defined: '$cmd'" $+functions[antidote-$cmd] -eq 1
done

teardown

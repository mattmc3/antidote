0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup

expected_funcdefs=(
  antidote-bundle
  antidote-help
  antidote-home
  antidote-init
  antidote-path
  antidote-purge
  antidote-update
)

for fndef in $expected_funcdefs; do
  @test "function not yet defined: '$fndef'" $+functions[$fndef] -eq 0
done

source $PRJ_HOME/antidote.zsh
@test "sourcing antidote.zsh succeeds" $? -eq 0

for fndef in $expected_funcdefs; do
  @test "function defined: '$fndef'" $+functions[$fndef] -eq 1
done

teardown

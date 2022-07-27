0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup

zstyle ':antidote:bundle' use-friendly-names on

typeset -A repos
repos=(
  ohmyzsh/ohmyzsh                      $ANTIDOTE_HOME/ohmyzsh/ohmyzsh
  http://github.com/sindresorhus/pure  $ANTIDOTE_HOME/sindresorhus/pure
)

for k in ${(k)repos}; do
  expected=$repos[$k]
  actual=$(_antidote_friendlyname $k)
  @test "friendlyname $k => $expected" "$actual" = "$expected"
done

teardown

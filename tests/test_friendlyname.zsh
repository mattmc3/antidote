0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup

zstyle ':antidote:bundle' use-friendly-names on

typeset -A repos
repos=(
  foo/bar                    $ANTIDOTE_HOME/foo/bar
  http://github.com/bar/baz  $ANTIDOTE_HOME/bar/baz
)

for k in ${(k)repos}; do
  expected=$repos[$k]
  actual=$(_antidote_friendlyname $k)
  @test "friendlyname $k => $expected" "$actual" = "$expected"
done

teardown

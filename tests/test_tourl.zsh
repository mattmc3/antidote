0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup
autoload -Uz $PRJ_HOME/functions/_antidote_tourl

typeset -A shortrepos
shortrepos=(
  ohmyzsh/ohmyzsh    https://github.com/ohmyzsh/ohmyzsh
  sindresorhus/pure  https://github.com/sindresorhus/pure
  foo/bar            https://github.com/foo/bar
)

for k in ${(k)shortrepos}; do
  expected=$shortrepos[$k]
  actual=$(_antidote_tourl $k)
  @test "tourl $k => $expected" "$actual" = "$expected"
done

fullrepos=(
  https://github.com/ohmyzsh/ohmyzsh
  http://github.com/ohmyzsh/ohmyzsh
  ssh://github.com/ohmyzsh/ohmyzsh
  git://github.com/ohmyzsh/ohmyzsh
  ftp://github.com/ohmyzsh/ohmyzsh

  git@github.com:sindresorhus/pure.git
)

for url in $fullrepos; do
  expected=$url
  actual=$(_antidote_tourl $url)
  @test "tourl $url is left unchanged" "$actual" = "$expected"
done

teardown

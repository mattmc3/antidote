#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
source $BASEDIR/antidote.zsh

() {
  local shortname repos expected actual
  typeset -A repos=(
    ohmyzsh/ohmyzsh    https://github.com/ohmyzsh/ohmyzsh
    sindresorhus/pure  https://github.com/sindresorhus/pure
    foo/bar            https://github.com/foo/bar
  )

  for shortname expected in "${(@kv)repos}"; do
    actual=$(__antidote_tourl $shortname)
    @test "tourl $shortname => $expected" "$expected" = "$actual"
  done
}

() {
  local repos expected actual url
  repos=(
    https://github.com/ohmyzsh/ohmyzsh
    http://github.com/ohmyzsh/ohmyzsh
    ssh://github.com/ohmyzsh/ohmyzsh
    git://github.com/ohmyzsh/ohmyzsh
    ftp://github.com/ohmyzsh/ohmyzsh
    git@github.com:sindresorhus/pure.git
  )

  for url in $repos; do
    expected=$url
    actual=$(__antidote_tourl $url)
    @test "tourl is unmodified for: $url" "$expected" = "$actual"
  done
}

ztap_footer

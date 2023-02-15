#!/usr/bin/env zsh
0=${(%):-%x}
autoload -Uz ${0:A:h}/functions/testinit && testinit
ztap_header "${0:t:r}"

# setup
source $BASEDIR/antidote.zsh
typeset -g ANTIDOTE_HOME=

() {
  antidote home &>/dev/null
  @test "'antidote home' succeeds" $? -eq 0
}

# -h|--help
() {
  antidote home -h &>/dev/null
  @test "'antidote home -h' succeeds" "$?" -eq 0
  antidote home --help &>/dev/null
  @test "'antidote home --help' succeeds" "$?" -eq 0
}

() {
  local actual
  typeset -g ANTIDOTE_HOME=$BASEDIR/tests/zdotdir/antidote_home
  @test "\$ANTIDOTE_HOME is set" -n "$ANTIDOTE_HOME"
  actual=$(antidote home)
  @test "'antidote home' prints \$ANTIDOTE_HOME when it is set" $ANTIDOTE_HOME = "$actual"
  typeset -g ANTIDOTE_HOME=
}

() {
  local actual
  @test "\$ANTIDOTE_HOME is unset" -z "$ANTIDOTE_HOME"
  actual=$(antidote home)
  @test "'antidote home' prints a value when \$ANTIDOTE_HOME is unset" -n "$actual"
  @test "'antidote home' prints an existing path when \$ANTIDOTE_HOME is unset" -d "$actual"
}

# macOS
() {
  local actual expected
  typeset -g OSTYPE=darwin21.3.0
  expected=$HOME/Library/Caches/antidote
  actual=$(antidote home)
  @test "'antidote home' on macOS is in ~/Library/Caches/antidote" "$actual" = "$expected"
}

# msys
() {
  local actual expected LOCALAPPDATA
  typeset -g OSTYPE=msys
  typeset -g LOCALAPPDATA=$HOME/AppData
  expected=$LOCALAPPDATA/antidote
  actual=$(antidote home)
  @test "'antidote home' on Windows is in ~/AppData/antidote" "$actual" = "$expected"
}

# foobar
() {
  local actual expected
  typeset -g OSTYPE=foobar
  typeset -g XDG_CACHE_HOME=$HOME/.xdgcache
  expected=$XDG_CACHE_HOME/antidote
  actual=$(antidote home)
  @test "'antidote home' on an OS with \$XDG_CACHE_HOME defined uses it" "$actual" = "$expected"
}

ztap_footer

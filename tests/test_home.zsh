0=${(%):-%x}
@echo "=== ${0:t:r} ==="

autoload -Uz ${0:a:h}/functions/setup && setup
autoload -Uz $PRJ_HOME/functions/antidote-home

ANTIDOTE_HOME=$HOME/.antidote/.cache
expected=$ANTIDOTE_HOME
actual=$(antidote-home)
@test "when \$ANTIDOTE_HOME is set it is used" "$actual" = "$expected"
ANTIDOTE_HOME=

OSTYPE=darwin21.3.0
expected=$HOME/Library/Caches/antidote
actual=$(antidote-home)
@test "antidote home on macOS is in ~/Library/Caches/antidote" "$actual" = "$expected"

OSTYPE=msys
LOCALAPPDATA=$HOME/AppData
expected=$LOCALAPPDATA/antidote
actual=$(antidote-home)
@test "antidote home on Windows is in ~/AppData/antidote" "$actual" = "$expected"

OSTYPE=foobar
XDG_CACHE_HOME=$HOME/.xdgcache
expected=$XDG_CACHE_HOME/antidote
actual=$(antidote-home)
@test "antidote home on an OS with \$XDG_CACHE_HOME defined uses \$XDG_CACHE_HOME" "$actual" = "$expected"


teardown

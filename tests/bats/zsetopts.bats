#!/usr/bin/env bats
# antidote respects setopts (ported from tests/test_zsetopts.md).
# These need run_session: the behavior under test is option state in
# the shell that runs `antidote load`.

load helpers/common

setup() { antidote_common_setup; }

@test "plugins that run setopts take effect through antidote load" {
  run_session <<'EOS'
plugin=$ANTIDOTE_HOME/fakegitsite.com/lampoon/xmas/xmas.plugin.zsh
mkdir -p $plugin:h
print 'unsetopt noaliases\nsetopt autocd' > $plugin
echo "lampoon/xmas" > $ZDOTDIR/.zsh_plugins.txt
setopt noaliases
echo "before: noaliases=$options[noaliases] autocd=$options[autocd]"
antidote load >/dev/null
echo "after: noaliases=$options[noaliases] autocd=$options[autocd]"
EOS
  expect "before: noaliases=on autocd=off
after: noaliases=off autocd=on"
}

# Ensure #86 stays fixed: no stderr noise under posix_identifiers.
@test "no stderr noise under posix_identifiers" {
  run_session <<'EOS'
setopt posix_identifiers
antidote -v 2>&1 >/dev/null && echo "-v: no stderr"
antidote -h 2>&1 >/dev/null && echo "-h: no stderr"
antidote help 2>&1 >/dev/null && echo "help: no stderr"
EOS
  expect "-v: no stderr
-h: no stderr
help: no stderr"
}

# Clark Grizwold lighting ceremony! A plugin that enables zillions of
# zsh options must have all of them take effect.
@test "grizwold plugin lights up all the zsh options" {
  run_session <<'EOS'
(( $(setopt | wc -l) < 10 )) && echo "few options enabled before load"
echo '$ZDOTDIR/custom/plugins/grizwold' > $ZDOTDIR/.zsh_plugins.txt
antidote load
(( $(setopt | wc -l) > 150 )) && echo "zillions of options enabled after load"
EOS
  expect "few options enabled before load
zillions of options enabled after load"
}

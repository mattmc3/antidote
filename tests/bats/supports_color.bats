#!/usr/bin/env bats
# Tests for supports_color.
# Runs antidote.zsh directly as a subprocess; no shell session state needed.
# bats captures stdout through a pipe, so the TTY check would always fail
# here. The :antidote:test tty style claims one, which is what lets the
# terminal capability rules be reached at all.

load lib/bats-support/load
load lib/bats-assert/load

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
  TTY="zstyle ':antidote:test' tty yes"
}

# Run supports_color with a scrubbed color environment plus the given
# VAR=value args.
probe() {
  env -u NO_COLOR -u CLICOLOR -u CLICOLOR_FORCE -u FORCE_COLOR \
    -u COLORTERM -u TERM -u ANTIDOTE_ZSTYLES \
    ANTIDOTE_CONFIG=/dev/null "$@" \
    zsh antidote.zsh __private__ supports_color
}

color()    { run probe "$@"; assert_success; }
no_color() { run probe "$@"; assert_failure 1; }

@test "color variables apply most explicit first" {
  # NO_COLOR first, then the force variables, where 0 means do not force.
  no_color TERM=xterm-256color NO_COLOR=1 FORCE_COLOR=1
  no_color TERM=xterm-256color NO_COLOR=1 CLICOLOR_FORCE=1
  color    TERM=xterm-256color FORCE_COLOR=1
  color    TERM=xterm-256color CLICOLOR_FORCE=1
  no_color TERM=xterm-256color FORCE_COLOR=0 CLICOLOR_FORCE=1

  # A force variable stands in for a terminal too, since CI runs with no
  # TERM, and it outranks CLICOLOR=0.
  color FORCE_COLOR=1 TERM=dumb
  color TERM=xterm-256color CLICOLOR=0 CLICOLOR_FORCE=1

  # No force and no terminal, then a terminal that opted out.
  no_color TERM=xterm-256color
  no_color TERM=xterm-256color CLICOLOR=0 ANTIDOTE_ZSTYLES="$TTY"
}

@test "a terminal is capable per terminfo, COLORTERM, or TERM" {
  local t
  # In every terminfo database, including the bare container ones. Note
  # xterm and screen have no 256 in the name, so the TERM pattern alone
  # would miss them.
  for t in xterm xterm-256color screen-256color tmux-256color rxvt; do
    color TERM=$t ANTIDOTE_ZSTYLES="$TTY"
  done

  # Terminals shipping their own terminfo entry can be absent from the
  # system database, which is what COLORTERM covers.
  for t in xterm-kitty foot ghostty wezterm; do
    color TERM=$t COLORTERM=truecolor ANTIDOTE_ZSTYLES="$TTY"
  done

  no_color TERM=dumb ANTIDOTE_ZSTYLES="$TTY"
  no_color TERM= ANTIDOTE_ZSTYLES="$TTY"
}

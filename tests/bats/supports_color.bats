#!/usr/bin/env bats
# Tests for supports_color (ported from tests/test_supports_color.md).
# Runs antidote.zsh directly as a subprocess; no shell session state needed.
# Note: bats captures stdout through a pipe, so [[ -t 1 ]] is always false
# here, same as the clitest harness.

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

# Run supports_color with a scrubbed color environment plus the given
# VAR=value overrides.
supports_color() {
  env -u NO_COLOR -u CLICOLOR_FORCE -u COLORTERM -u TERM \
    ANTIDOTE_CONFIG=/dev/null "$@" \
    zsh antidote.zsh __private__ supports_color
}

@test "NO_COLOR takes highest priority" {
  run supports_color TERM=xterm-256color CLICOLOR_FORCE=1 NO_COLOR=1
  [ "$status" -eq 1 ]
}

@test "CLICOLOR_FORCE bypasses TTY check" {
  run supports_color TERM=xterm-256color CLICOLOR_FORCE=1
  [ "$status" -eq 0 ]
}

@test "non-TTY disables colors" {
  run supports_color TERM=xterm-256color
  [ "$status" -eq 1 ]
}

@test "COLORTERM=truecolor is capable" {
  run supports_color CLICOLOR_FORCE=1 COLORTERM=truecolor
  [ "$status" -eq 0 ]
}

@test "COLORTERM=24bit is capable" {
  run supports_color CLICOLOR_FORCE=1 COLORTERM=24bit
  [ "$status" -eq 0 ]
}

@test "TERM=xterm-256color is capable" {
  run supports_color CLICOLOR_FORCE=1 TERM=xterm-256color
  [ "$status" -eq 0 ]
}

@test "TERM=rxvt is capable" {
  run supports_color CLICOLOR_FORCE=1 TERM=rxvt
  [ "$status" -eq 0 ]
}

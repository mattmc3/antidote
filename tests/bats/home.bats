#!/usr/bin/env bats
# antidote home tests (ported from tests/test_cmd_home.md).
# `antidote home -h` man routing is covered in help.bats.

load helpers/common

setup() {
  antidote_common_setup
  antidote_test_home
}

@test "ANTIDOTE_HOME is used if set" {
  run antidote home
  expect "$AHOME"
}

@test "home is ~/Library/Caches/antidote on macOS" {
  AHOME=""
  ZSTYLES="zstyle ':antidote:test:env' OSTYPE darwin21.3.0"
  run antidote home
  expect "$TESTHOME/Library/Caches/antidote"
}

@test "home is LOCALAPPDATA/antidote on msys" {
  AHOME=""
  ZSTYLES="zstyle ':antidote:test:env' OSTYPE msys
zstyle ':antidote:test:env' LOCALAPPDATA $TESTHOME/AppData"
  run antidote home
  expect "$TESTHOME/AppData/antidote"
}

@test "home uses XDG_CACHE_HOME on an OS that defines it" {
  AHOME=""
  ZSTYLES="zstyle ':antidote:test:env' OSTYPE foobar"
  EXTRA_ENV="XDG_CACHE_HOME=$TESTHOME/.xdg-cache"
  run antidote home
  expect "$TESTHOME/.xdg-cache/antidote"
}

@test "home falls back to HOME/.cache" {
  AHOME=""
  ZSTYLES="zstyle ':antidote:test:env' OSTYPE foobar"
  run antidote home
  expect "$TESTHOME/.cache/antidote"
}

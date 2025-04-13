#!/bin/zsh
() {
  emulate -L zsh
  setopt local_options

  0=${(%):-%x}
  local projdir="${0:A:h:h}"
  local testdir="${projdir}/tests"

  # setup test functions
  fpath+=( $testdir/functions )
  autoload -Uz $testdir/functions/*
}

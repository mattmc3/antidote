#!/usr/bin/env zsh
# Manual test for zstyle ':antidote:fzf' opts
# Run: zsh tests/bin/test_fzf_opts_manual.zsh

ANTIDOTE_ZSH=${0:a:h:h:h}/antidote.zsh

print "=== Without opts zstyle: default fzf picker (ANTIDOTE_FZF_DEFAULT_OPTS should be ignored) ==="
(
  export FZF_DEFAULT_OPTS="--color=fg:#ff00ff,bg:#222222,hl:#ffff00,fg+:#ffffff,bg+:#ff00ff,hl+:#00ffff,prompt:#ff0000,pointer:#00ff00 --layout=reverse-list --height=80%"
  source $ANTIDOTE_ZSH
  antidote snapshot restore
)

print "\n=== With opts zstyle: bright pink, centered, 80% height ==="
(
  zstyle ':antidote:fzf' opts "--color=fg:#ff00ff,bg:#222222,hl:#ffff00,fg+:#ffffff,bg+:#ff00ff,hl+:#00ffff,prompt:#ff0000,pointer:#00ff00 --layout=reverse-list --height=80%"
  source $ANTIDOTE_ZSH
  antidote snapshot restore
)

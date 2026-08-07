source "$BENCH_PRJDIR/antidote.zsh"

# Every other manager in this benchmark compiles to bytecode by default;
# antidote does not. This config turns it on so the comparison is like
# for like, and shows what the default costs.
zstyle ':antidote:*' zcompile 'yes'

autoload -Uz compinit && compinit -u -d "$ZDOTDIR/.zcompdump"
antidote load

source "$BENCH_PRJDIR/antidote.zsh"
autoload -Uz compinit && compinit -u -d "$ZDOTDIR/.zcompdump"
source <(antidote init)

# defaults
antidote bundle mattmc3/z1
antidote bundle mattmc3/use-xdg-basedirs

# utils
antidote bundle getantidote/contrib
antidote bundle mattmc3/zman
antidote bundle aloxaf/fzf-tab

# omz
antidote bundle ohmyzsh/ohmyzsh path:lib/clipboard.zsh
antidote bundle using:ohmyzsh/ohmyzsh path:plugins
antidote bundle copybuffer
antidote bundle copyfile
antidote bundle copypath
antidote bundle extract
antidote bundle fancy-ctrl-z
antidote bundle magic-enter

# misc
antidote bundle romkatv/zsh-bench kind:path
antidote bundle romkatv/zsh-no-ps2

# fishlike
antidote bundle zsh-users/zsh-autosuggestions
antidote bundle zsh-users/zsh-completions kind:fpath path:src
antidote bundle "zsh-users/zsh-history-substring-search post:'autoload -Uz bindkey-hss && bindkey-hss'"

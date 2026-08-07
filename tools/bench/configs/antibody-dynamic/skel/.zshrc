path=("$ZDOTDIR/.antibody/bin" $path)

autoload -Uz compinit && compinit -u -d "$ZDOTDIR/.zcompdump"
source <(antibody init)

# defaults
antibody bundle mattmc3/z1
antibody bundle mattmc3/use-xdg-basedirs

# utils
antibody bundle getantidote/contrib
antibody bundle mattmc3/zman
antibody bundle aloxaf/fzf-tab

# omz
# No using: directive here. Each bundle call is its own antibody process, so
# nothing carries the context to the next call and the bare names resolve to
# nothing. The static config keeps using: because it parses the file in one
# pass.
antibody bundle ohmyzsh/ohmyzsh path:lib/clipboard.zsh
antibody bundle ohmyzsh/ohmyzsh path:plugins/copybuffer
antibody bundle ohmyzsh/ohmyzsh path:plugins/copyfile
antibody bundle ohmyzsh/ohmyzsh path:plugins/copypath
antibody bundle ohmyzsh/ohmyzsh path:plugins/extract
antibody bundle ohmyzsh/ohmyzsh path:plugins/fancy-ctrl-z
antibody bundle ohmyzsh/ohmyzsh path:plugins/magic-enter

# misc
antibody bundle romkatv/zsh-bench kind:path
antibody bundle romkatv/zsh-no-ps2

# fishlike
# The whole line is quoted so the post: value survives argv as one word.
antibody bundle zsh-users/zsh-autosuggestions
antibody bundle zsh-users/zsh-completions kind:fpath path:src
antibody bundle "zsh-users/zsh-history-substring-search post:'autoload -Uz bindkey-hss && bindkey-hss'"

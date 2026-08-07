source "$ZDOTDIR/.antigen/bin/antigen.zsh"
autoload -Uz compinit && compinit -u -d "$ZDOTDIR/.zcompdump"

# defaults
antigen bundle mattmc3/z1 --branch=main
antigen bundle mattmc3/use-xdg-basedirs --branch=main

# utils
antigen bundle getantidote/contrib --branch=main
antigen bundle mattmc3/zman --branch=main
antigen bundle aloxaf/fzf-tab

# omz
antigen bundle ohmyzsh/ohmyzsh lib/clipboard.zsh
antigen bundle ohmyzsh/ohmyzsh plugins/copybuffer
antigen bundle ohmyzsh/ohmyzsh plugins/copyfile
antigen bundle ohmyzsh/ohmyzsh plugins/copypath
antigen bundle ohmyzsh/ohmyzsh plugins/extract
antigen bundle ohmyzsh/ohmyzsh plugins/fancy-ctrl-z
antigen bundle ohmyzsh/ohmyzsh plugins/magic-enter

# misc
antigen bundle romkatv/zsh-bench
antigen bundle romkatv/zsh-no-ps2

# fishlike
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions src
antigen bundle zsh-users/zsh-history-substring-search

antigen apply
autoload -Uz bindkey-hss && bindkey-hss

# Antigen's cache schedules its own compinit in a precmd hook, using -i (which
# silently drops insecure dirs) and a separate dump. That is a second compinit
# no other config runs, and it ends up with ~240 fewer completions. Drop the
# hook so every config here runs compinit exactly once, the same way.
autoload -Uz add-zsh-hook
add-zsh-hook -D precmd _antigen_compinit 2>/dev/null

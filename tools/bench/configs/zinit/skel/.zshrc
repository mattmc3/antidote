typeset -g ZINIT_HOME="$ZDOTDIR/.zinit"
source "$ZINIT_HOME/zinit.git/zinit.zsh"
autoload -Uz compinit && compinit -u -d "$ZDOTDIR/.zcompdump"

# defaults
zinit light mattmc3/z1
zinit light mattmc3/use-xdg-basedirs

# utils
zinit light getantidote/contrib
zinit light mattmc3/zman
zinit light aloxaf/fzf-tab

# omz
zinit snippet OMZL::clipboard.zsh
zinit snippet OMZP::copybuffer
zinit snippet OMZP::copyfile
zinit snippet OMZP::copypath
zinit snippet OMZP::extract
zinit snippet OMZP::fancy-ctrl-z
zinit snippet OMZP::magic-enter

# misc
zinit ice as'program' pick'zsh-bench'
zinit light romkatv/zsh-bench
zinit light romkatv/zsh-no-ps2

# fishlike
zinit light zsh-users/zsh-autosuggestions
zinit ice blockf atpull'zinit creinstall -q .'
zinit light zsh-users/zsh-completions
zinit ice atload'autoload -Uz bindkey-hss && bindkey-hss'
zinit light zsh-users/zsh-history-substring-search

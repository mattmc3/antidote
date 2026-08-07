source "$ZDOTDIR/.znap/znap.zsh"
autoload -Uz compinit && compinit -u -d "$ZDOTDIR/.zcompdump"

# defaults
znap source mattmc3/z1
znap source mattmc3/use-xdg-basedirs

# utils
znap source getantidote/contrib
znap source mattmc3/zman
znap source aloxaf/fzf-tab

# omz
znap source ohmyzsh/ohmyzsh \
  lib/clipboard.zsh \
  plugins/copybuffer \
  plugins/copyfile \
  plugins/copypath \
  plugins/extract \
  plugins/fancy-ctrl-z \
  plugins/magic-enter

# misc
znap clone romkatv/zsh-bench
path+=( ~[romkatv/zsh-bench] )
znap source romkatv/zsh-no-ps2

# fishlike
znap source zsh-users/zsh-autosuggestions
znap clone zsh-users/zsh-completions
fpath+=( ~[zsh-users/zsh-completions]/src )
znap source zsh-users/zsh-history-substring-search

autoload -Uz bindkey-hss && bindkey-hss

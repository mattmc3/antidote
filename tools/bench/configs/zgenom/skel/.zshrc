source "$ZDOTDIR/.zgenom/zgenom.zsh"
autoload -Uz compinit && compinit -u -d "$ZDOTDIR/.zcompdump"

if ! zgenom saved; then
  # defaults
  zgenom load mattmc3/z1
  zgenom load mattmc3/use-xdg-basedirs

  # utils
  zgenom load getantidote/contrib
  zgenom load mattmc3/zman
  zgenom load aloxaf/fzf-tab

  # omz
  zgenom ohmyzsh lib/clipboard.zsh
  zgenom ohmyzsh plugins/copybuffer
  zgenom ohmyzsh plugins/copyfile
  zgenom ohmyzsh plugins/copypath
  zgenom ohmyzsh plugins/extract
  zgenom ohmyzsh plugins/fancy-ctrl-z
  zgenom ohmyzsh plugins/magic-enter

  # misc
  zgenom bin romkatv/zsh-bench
  zgenom load romkatv/zsh-no-ps2

  # fishlike
  zgenom load zsh-users/zsh-autosuggestions
  zgenom load --completion zsh-users/zsh-completions src
  zgenom load zsh-users/zsh-history-substring-search

  zgenom save
fi

autoload -Uz bindkey-hss && bindkey-hss

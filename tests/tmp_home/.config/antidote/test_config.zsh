# antidote config - test overrides
# See templates/config.zsh for all available zstyles and their defaults.

zstyle ':antidote:git'      site       'fakegitsite.com'
# zstyle ':antidote:git'      protocol   'https'
# zstyle ':antidote:git'      cmd        'git'
# zstyle ':antidote:bundle'   path-style 'full'
zstyle ':antidote:defer'    bundle     'getantidote/zsh-defer'
zstyle ':antidote:fpath'    rule       'append'
zstyle ':antidote:static'   zcompile   'no'

zstyle ':antidote:tests' set-warn-options 'on'

# antidote config
#
# Place this file at: ${XDG_CONFIG_HOME:-$HOME/.config}/antidote/config.zsh
#
# All available zstyles are shown below with their default values.
# Uncomment and modify any lines you want to change.

# =============================================================================
# Git settings
# =============================================================================

# zstyle ':antidote:git' site     'github.com'    # default git hosting site
# zstyle ':antidote:git' protocol 'https'         # 'https' or 'ssh'
# zstyle ':antidote:git' cmd      'git'           # git executable to use

# =============================================================================
# Bundle settings
# =============================================================================

# zstyle ':antidote:bundle' path-style 'full'                                 # values: full, short, escaped
# zstyle ':antidote:bundle' file       '${ZDOTDIR:-$HOME}/.zsh_plugins.txt'   # plugins file location

## Per-bundle settings (glob patterns supported)
# zstyle ':antidote:bundle:*'       zcompile       'no'   # zcompile all cloned bundles
# zstyle ':antidote:bundle:*'       defer-options  ''     # extra options passed to zsh-defer for all bundles
# zstyle ':antidote:bundle:foo/bar' defer-options  ''     # extra options for a specific bundle

# =============================================================================
# Static file settings
# =============================================================================

# zstyle ':antidote:static' file     '${ZDOTDIR:-$HOME}/.zsh_plugins.zsh'  # generated static file location
# zstyle ':antidote:static' zcompile 'no'                                   # zcompile the static file

# =============================================================================
# Defer settings
# =============================================================================

# zstyle ':antidote:defer' bundle 'romkatv/zsh-defer'  # which zsh-defer plugin to use

# =============================================================================
# Fpath settings
# =============================================================================

# zstyle ':antidote:fpath' rule 'append'   # 'append' or 'prepend' fpath entries

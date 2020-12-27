# zplugr

> A humble zsh plugin manager

Too many plugin managers try to do too many things.
zplugr isn't a clever plugin manager, it's a smart one.
Simple. Easy to understand. Doesn't try to be too much.
Does everything you'd want a plugin manager to do and lets you do the rest.

## Usage

The help is pretty helpful:

```text
zplugr - A humble zsh plugin manager

usage: zplugr <cmd> [args...]

commands:
  clone   clone a zsh plugin's git repo
  pull    update a plugin, or all plugins
  path    show zplugr's root plugin path
  prompt  load a plugin as a prompt
  ls      list all cloned plugins
  source  source a plugin
  exists  check if a plugin is cloned
  help    show this message
```

### Cloning plugins

Examples:

```
zplugr clone mattmc3/zplugr
zplugr clone https://github.com/zsh-users/zsh-history-substring-search
zplugr clone git@github.com:zsh-users/zsh-history-substring-search.git
```

### Updating plugins

Update a single plugin:

```
zplugr pull mattmc3/zplugr
```

Updating all plugins:

```
zplugr pull mattmc3/zplugr
```

### Sourcing a plugin

If the plugin doesn't exist, it will be cloned prior to being sourced

```
zplugr source mattmc3/zplugr
```

### Prompts

You can source a prompt too

```
zplugr prompt sindresorhus/pure
```

## Installation

To install zplugr, add this to your `${ZDOTDIR:-$HOME}/.zshrc`

```shell
ZPLUGR_PLUGINS_DIR="${ZDOTDIR:-$HOME/.config/zsh}"/plugins
[[ -d $ZPLUGR_PLUGINS_DIR/zplugr ]] ||
  git clone --depth=1 --recursive https://github.com/mattmc3/zplugr.git $ZPLUGR_PLUGINS_DIR/zplugr
source $ZPLUGR_PLUGINS_DIR/zplugr/zplugr.zsh
```

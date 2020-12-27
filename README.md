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
  help    show this message
  clone   clone a zsh plugin's git repo
  list    list all cloned plugins
  prompt  load a plugin as a prompt
  pull    update a plugin, or all plugins
  source  source a plugin
```

### Cloning plugins

Examples:

```shell
zplugr clone mattmc3/zplugr
zplugr clone https://github.com/zsh-users/zsh-history-substring-search
zplugr clone git@github.com:zsh-users/zsh-history-substring-search.git
```

### Updating plugins

Update a single plugin:

```shell
zplugr pull mattmc3/zplugr
```

Updating all plugins:

```shell
zplugr pull
```

### Sourcing a plugin

If the plugin doesn't exist, it will be cloned prior to being sourced

```shell
zplugr source mattmc3/zplugr
```

### Prompts

You can source a prompt too

```shell
zplugr prompt sindresorhus/pure
```

## Installation

To install zplugr, simply clone the repo...

```shell
git clone --depth=1 --recursive https://github.com/mattmc3/zplugr.git ~/.config/zsh/plugins/zplugr
```

...and source zplugr from your .zshrc

```shell
source ~/.config/zsh/plugins/zplugr/zplugr.zsh
```

***- Or -***

You could add this snippet for total automation in your .zshrc

```shell
ZPLUGR_PLUGINS_DIR="${ZDOTDIR:-$HOME/.config/zsh}/plugins"
[[ -d $ZPLUGR_PLUGINS_DIR/zplugr ]] ||
  git clone --depth=1 --recursive https://github.com/mattmc3/zplugr.git $ZPLUGR_PLUGINS_DIR/zplugr
source $ZPLUGR_PLUGINS_DIR/zplugr/zplugr.zsh
```

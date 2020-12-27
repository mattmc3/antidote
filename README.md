# PZ

> PZ - Plugins for ZSH made easy-pz

Too many plugin managers try to do too many things.
PZ doesn't try to be _clever_ when it can be **smart**.
Simple. Fast. Easy to understand. With short, readable ZSH code.

PZ does just enough to manage your ZSH plugins really well, and then gets out of your way.

Small footprint, big impact - that's easy-pz.

## Usage

The help is pretty helpful. Run `pz help`:

```text
pz - Plugins for ZSH made easy-pz

usage: pz <cmd> [args...]

commands:
  help    show this message
  clone   clone a zsh plugin's git repo
  list    list all cloned plugins
  prompt  initialize a prompt theme plugin
  pull    update a plugin, or all plugins
  source  source a plugin
```

### Cloning

You can clone a plugin with partial or full git paths:

```shell
pz clone mattmc3/pz
pz clone https://github.com/zsh-users/zsh-history-substring-search
pz clone git@github.com:zsh-users/zsh-history-substring-search.git
```

### Updating plugins

You can update a single plugin:

```shell
pz pull mattmc3/pz
```

Or, update all plugins:

```shell
pz pull
```

### Sourcing

You can source a plugin to add its functionality to your ZSH.
If the plugin doesn't exist, it will be cloned prior to being sourced:

```shell
pz source mattmc3/pz
```

### Prompts

You can use prompt plugins too

```shell
pz prompt sindresorhus/pure
```

## Installation

To install pz, simply clone the repo...

```shell
git clone --depth=1 --recursive https://github.com/mattmc3/pz.git ~/.config/zsh/plugins/pz
```

...and source pz from your .zshrc

```shell
source ~/.config/zsh/plugins/pz/pz.zsh
```

***- Or -***

You could add this snippet for total automation in your .zshrc

```shell
PZ_PLUGINS_DIR="${ZDOTDIR:-$HOME/.config/zsh}/plugins"
[[ -d $PZ_PLUGINS_DIR/pz ]] ||
  git clone https://github.com/mattmc3/pz.git $PZ_PLUGINS_DIR/pz
source $PZ_PLUGINS_DIR/pz/pz.zsh
```

## .zshrc

A good example .zshrc might look like this:

```shell
### ${ZDOTDIR:-$HOME}/.zshrc

# setup pz
PZ_PLUGINS_DIR="${ZDOTDIR:-$HOME/.config/zsh}/plugins"
[[ -d $PZ_PLUGINS_DIR/pz ]] ||
  git clone https://github.com/mattmc3/pz.git $PZ_PLUGINS_DIR/pz
source $PZ_PLUGINS_DIR/pz/pz.zsh

# source plugins
pz source mattmc3/zsh-setopts
pz source mattmc3/zsh-history
pz source mattmc3/zfunctions
pz source mattmc3/zsh-xdg-basedirs
pz source zsh-users/zsh-autosuggestions
pz source zsh-users/zsh-history-substring-search
pz source zsh-users/zsh-completions
pz source mattmc3/zsh-compinit
pz source zsh-users/zsh-syntax-highlighting

# init prompt
pz prompt sindresorhus/pure
```

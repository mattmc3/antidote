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
  clone   download a plugin
  list    list all plugins
  prompt  load a prompt plugin
  pull    update a plugin, or all plugins
  source  load a plugin
```

### Cloning

You can clone a plugin with partial or full git paths:

```shell
pz clone zsh-users/zsh-autosuggestions
pz clone https://github.com/zsh-users/zsh-history-substring-search
pz clone git@github.com:zsh-users/zsh-completions.git
```

### Updating

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
pz source zsh-users/zsh-history-substring-search
```

### Prompts

You can use prompt plugins too

```shell
pz prompt sindresorhus/pure
```

## Installation

To install pz, simply clone the repo...

```shell
git clone https://github.com/mattmc3/pz.git ~/.config/zsh/plugins/pz
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

## Customizing

### Plugin location

PZ stores your plugins wherever you installed it.

You can change the default plugin location by setting this `zstyle` in your .zshrc:

```shell
zstyle :pz: plugins-dir $ZDOTDIR/plugins
```

### Git URL

Don't prefer to default to GitHub.com for your plugins? Feel free to change the default git URL with this `zstyle` in your .zshrc:

```shell
# bitbucket.org or gitlab.com or really any git service
zstyle :pz:clone: gitserver bitbucket.org
```

## .zshrc

An example `.zshrc` might look something like this:

```shell
### ${ZDOTDIR:-$HOME}/.zshrc

# setup your environment
...

# then setup pz
PZ_PLUGINS_DIR="${ZDOTDIR:-$HOME/.config/zsh}/plugins"
[[ -d $PZ_PLUGINS_DIR/pz ]] ||
  git clone https://github.com/mattmc3/pz.git $PZ_PLUGINS_DIR/pz
source $PZ_PLUGINS_DIR/pz/pz.zsh

# source plugins from github
pz source zsh-users/zsh-autosuggestions
pz source zsh-users/zsh-history-substring-search
pz source zsh-users/zsh-completions
pz source zsh-users/zsh-syntax-highlighting

# source ohmyzsh plugins
pz source ohmyzsh/ohmyzsh plugins/colored-man-pages

# set your prompt
pz prompt sindresorhus/pure

# -or- use oh-my-zsh themes instead of a prompt plugin
pz source ohmyzsh lib/git
pz source ohmyzsh lib/theme-and-appearance
pz source ohmyzsh themes/robbyrussell
```

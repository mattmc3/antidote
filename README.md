# PZ

> PZ - Plugins for ZSH made easy-pz

A plugin manager for ZSH doesn't have to be _complicated_ to be **powerful**.
PZ doesn't try to be _clever_ when it can be **smart**.
PZ is a full featured, fast, and easy to understand plugin manager encapsulated in single file with about 200 lines of clean ZSH.

PZ does just enough to manage your ZSH plugins really well, and then gets out of your way.

Plugins for ZSH made easy-pz.

## Usage

The help is pretty helpful. Run `pz help`:

```text
pz - Plugins for ZSH made easy-pz

usage:
  pz <command> [<flags...>|<arguments...>]

commands:
  help      show this message
  clone     download a plugin
  initfile  show the file that will be sourced to initialize a plugin
  list      list all plugins
  prompt    load a prompt plugin
  pull      update a plugin, or all plugins
  source    load a plugin
  zcompile  compile zsh files for your plugins
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
PZ_PLUGIN_HOME="${ZDOTDIR:-$HOME/.config/zsh}/plugins"
[[ -d $PZ_PLUGIN_HOME/pz ]] ||
  git clone https://github.com/mattmc3/pz.git $PZ_PLUGIN_HOME/pz
source $PZ_PLUGIN_HOME/pz/pz.zsh
```

### Downloading your plugins

You can clone a plugin with partial or full git paths:

```shell
pz clone zsh-users/zsh-autosuggestions
pz clone https://github.com/zsh-users/zsh-history-substring-search
pz clone git@github.com:zsh-users/zsh-completions.git
```

### Load your plugins

You can source a plugin to add its functionality to your ZSH.
If the plugin doesn't exist, it will be cloned prior to being sourced:

```shell
pz source zsh-users/zsh-history-substring-search
```

### Locad prompt plugins

You can use prompt plugins too

```shell
pz prompt sindresorhus/pure
```

### Updating your plugins

You can update a single plugin:

```shell
pz pull mattmc3/pz
```

Or, update all plugins:

```shell
pz pull
```

### Oh My Zsh

If you use [Oh My Zsh][ohmyzsh], you are probably familiar with `$ZSH_CUSTOM`, which is where you can add your own plugins to Oh My Zsh.
By default, `$ZSH_CUSTOM` resides in ~/.oh-my-zsh/custom, but you can put it anywhere.
PZ works well with Oh My Zsh, and you can simply set your `$PZ_PLUGIN_HOME` variable to `$ZSH_CUSTOM/plugins`.
For example, try adding this snippet to your `.zshrc`:

```shell
PZ_PLUGIN_HOME="${ZSH_CUSTOM:-$ZSH/custom}/plugins"
[[ -d $PZ_PLUGIN_HOME/pz ]] ||
  git clone https://github.com/mattmc3/pz.git $PZ_PLUGIN_HOME/pz
source $PZ_PLUGIN_HOME/pz/pz.zsh
```

## Customizing

### Plugin location

PZ stores your plugins wherever you installed PZ.
Peferrably, that would be in a `$ZDOTDIR/plugins` directory, because then you get can let PZ manage itself and auto-update with `pz pull`.
But, if you prefer something else, you can always change the default plugin location by setting the `PZ_PLUGIN_HOME` variable .zshrc:

```shell
# use a custom directory for pz plugins
PZ_PLUGIN_HOME=~/.pzplugins
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
PZ_PLUGIN_HOME="${ZDOTDIR:-$HOME/.config/zsh}/plugins"
[[ -d $PZ_PLUGIN_HOME/pz ]] ||
  git clone https://github.com/mattmc3/pz.git $PZ_PLUGIN_HOME/pz
source $PZ_PLUGIN_HOME/pz/pz.zsh

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

[ohmyzsh]: https://ohmyz.sh

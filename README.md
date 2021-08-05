# PZ

> PZ - Plugins for Zsh made easy-pz

A plugin manager for Zsh doesn't have to be _complicated_ to be **powerful**.
PZ doesn't try to be _clever_ when it can be **smart**.
PZ is a full featured, fast, and easy to understand plugin manager encapsulated in [a single, small, clean Zsh script][pz.zsh].

PZ does just enough to manage your Zsh plugins really well, and then gets out of your way.

Plugins for Zsh made easy-pz.

## Usage

The help is pretty helpful. Run `pz help`:

```text
pz - Plugins for Zsh made easy-pz

usage:
  pz <command> [<flags...>|<arguments...>]

commands:
  help      display this message
  clone     download a plugin
  initfile  display the plugin's init file
  list      list all plugins
  prompt    load a prompt plugin
  pull      update a plugin, or all plugins
  source    load a plugin
  zcompile  compile your plugins' zsh files
```

You can also get extended help for commands by running `pz help <command>`:

```text
$ pz help source
usage:
  pz source <plugin> [<subpath>]

args:
  plugin   shorthand user/repo or full git URL
  subpath  subpath within plugin to use instead of root path

examples:
  pz source ohmyzsh
  pz source ohmyzsh/ohmyzsh lib/git
  pz source ohmyzsh/ohmyzsh plugins/extract
  pz source zsh-users/zsh-autosuggestions
  pz source https://github.com/zsh-users/zsh-history-substring-search
  pz source git@github.com:zsh-users/zsh-completions.git
```

## Installation

To install pz, simply clone the repo...

```shell
git clone https://github.com/mattmc3/pz.git ~/.config/zsh/plugins/pz
```

...and source pz from your `.zshrc`

```shell
source ~/.config/zsh/plugins/pz/pz.zsh
```

***- Or -***

You could add this snippet for total automation in your `.zshrc`

```shell
PZ_PLUGIN_HOME="${ZDOTDIR:-$HOME/.config/zsh}/plugins"
[[ -d $PZ_PLUGIN_HOME/pz ]] ||
  git clone https://github.com/mattmc3/pz.git $PZ_PLUGIN_HOME/pz
source $PZ_PLUGIN_HOME/pz/pz.zsh
```

### Download your plugins

Downloading a plugin from a git repository referred to as cloning.
You can clone a plugin with partial or full git paths:

```shell
# clone with the user/repo shorthand (assumes github.com)
pz clone zsh-users/zsh-autosuggestions

# or, clone with a git URL
pz clone https://github.com/zsh-users/zsh-history-substring-search
pz clone git@github.com:zsh-users/zsh-completions.git
```

You can even rename a plugin if you prefer to call it something else:

```shell
# call it autosuggest instead
pz clone zsh-users/zsh-autosuggestions autosuggest
```

### Load your plugins

Loading a plugin means you source its primary plugin file.
You can source a plugin to use it in your interactive Zsh sessions.

```shell
pz source zsh-history-substring-search
```

If you haven't cloned a plugin already, you can still source it.
It will be cloned automatically, but in order to do that you will need to use its longer name or a full git URL:

```shell
pz source zsh-users/zsh-history-substring-search
pz source https://github.com/zsh-users/zsh-autosuggestions
```

### Load a prompt/theme plugin

You can use prompt plugins too, which will set your theme.
Prompt plugins are special and are handled a little differently than sourcing regular plugins.

```shell
pz prompt sindresorhus/pure
```

Zsh has builtin functionality for switching and managing prompts.
Running this Zsh builtin command will give you a list of the prompt themes you have available:

```shell
prompt -l
```

If you would like to make more prompt themes available, you can use the `-a` flag.
This will not set the theme, but make it available to easily switch during your Zsh session.

For example, in your `.zshrc` add the following:

```shell
# .zshrc
# make a few other great prompts available
pz prompt -a miekg/lean
pz prompt -a romkatv/powerlevel10k

# and then set your default prompt to pure
pz prompt sindresorhus/pure
```

You can then switch to an available prompt in your interactive Zsh session:

```shell
$ # list available prompts
$ promp -l
Currently available prompt themes:
adam1 adam2 bart bigfade clint default elite2 elite fade fire off oliver pws redhat restore suse walters zefram lean pure

$ # now, switch to a different prompt
$ prompt lean
```

### Update your plugins

You can update a single plugin:

```shell
pz pull mattmc3/pz
```

Or, update all your plugins:

```shell
pz pull
```

### Oh My Zsh

If you use [Oh My Zsh][ohmyzsh], you are probably familiar with `$ZSH_CUSTOM`, which is where you can add your own plugins to Oh My Zsh.
By default, `$ZSH_CUSTOM` resides in `~/.oh-my-zsh/custom`, but you can put it anywhere.
PZ is a stand alone plugin manager, but it also works really well to augment Oh My Zsh.
This is handy since Oh My Zsh doesn't have a way to manage external plugins itself.
To use PZ to manage external Oh My Zsh plugins, simply set your `$PZ_PLUGIN_HOME` variable to `$ZSH_CUSTOM/plugins`.
For example, try adding this snippet to your `.zshrc`:

```shell
# set PZ's plugin home to your ZSH_CUSTOM
PZ_PLUGIN_HOME=$ZSH_CUSTOM/plugins

# get PZ if you haven't already
[[ -d $PZ_PLUGIN_HOME/pz ]] ||
  git clone https://github.com/mattmc3/pz.git $PZ_PLUGIN_HOME/pz

# no need to source pz.zsh yourself if you put it in your plugins array
plugins=(... pz)
```

## Customizing

### Plugin location

PZ stores your plugins in your `$ZDOTDIR/plugins` directory.
If you don's use `$ZDOTDIR`, then `~/.config/zsh/plugins` is used.

But, if you prefer to store your plugins someplace else, you can always change the default plugin location.
Do this by setting the `PZ_PLUGIN_HOME` variable in your `.zshrc` before sourcing PZ:

```shell
# use a custom directory for pz plugins
PZ_PLUGIN_HOME=~/.pzplugins
```

Also note that it is recommended that you store PZ in the same place as your other plugins so that `pz pull` will update PZ.

If you store your Zsh configuration in a [dotfiles][dotfiles] reporitory, it is recommended to add your preferred `$PZ_PLUGIN_HOME` to your `.gitignore` file.

### Git URL

Don't prefer to default to GitHub.com for your plugins? Feel free to change the default git URL with this `zstyle` in your `.zshrc`:

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
[dotfiles]: https://dotfiles.github.io
[pz.zsh]: https://github.com/mattmc3/pz/blob/main/pz.zsh

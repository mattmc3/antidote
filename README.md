# antidote

> A Zsh plugin manager that picks up where [Antibody][antibody] left off.

Antidote is a feature complete re-implementation of Antibody in Zsh.

## Installation

Add the following to your `.zshrc`

```zsh
[[ -d ${ZDOTDIR:-~}/.antidote ]] ||
  git clone https://github.com/mattmc3/antidote ${ZDOTDIR:-~}/.antidote
source ${ZDOTDIR:-~}/.antidote/antidote.zsh
```

## Usage

There are mainly two ways of using antidote: static and dynamic. We will also see how we
can keep a plugins file.

### Plugins file

A plugin file is basically any text file that has one plugin per line.

In our examples, let’s assume we have a `${ZDOTDIR:-~}/.zsh_plugins.txt` file with these
contents:

```zsh
# .zsh_plugins.txt
# comments are supported like this
zshzoo/zfunctions
zshzoo/zshrc.d
zsh-users/zsh-completions

# empty lines are skipped

# annotations are also allowed:
ohmyzsh/ohmyzsh path:plugins/colored-man-pages
romkatv/zsh-bench kind:path
olets/zsh-abbr kind:defer

zsh-users/zsh-syntax-highlighting
zsh-users/zsh-history-substring-search
zsh-users/zsh-autosuggestions
```

That being said, let’s look how can we load them!

### Dynamic loading

This is the most common way. Basically, every time the a new shell starts, antidote will
apply the plugins given to it.

For this to work, antidote needs to be wrapped into your `.zshrc`. To do that, run:

```zsh
# .zshrc
source <(antidote init)
```

And reload your current shell or open a new one.

Then, you will also need to tell antidote which plugins to bundle. This can also be done
in the `.zshrc` file:

```zsh
# .zshrc
antidote bundle < ${ZDOTDIR:-~}/.zsh_plugins.txt
```

### Static loading

This is the faster alternative. Basically, you’ll run antidote only when you change your
plugins, and then you can just load the "static" plugins file.

Note that in this case, **we should not put `antidote init` on our `.zshrc`**. If you
did that already, remove it from your .zshrc and start a fresh terminal session.

Assuming the same `.zsh_plugins.txt` as before, we can run:

```zsh
antidote bundle < ${ZDOTDIR:-~}/.zsh_plugins.txt > ${ZDOTDIR:-~}/.zsh_plugins.zsh
```

We can run this at any time to update our `.zsh_plugins.zsh` file. Now, we just need to
source that file in our `.zshrc`:

```zsh
# .zshrc
source ${ZDOTDIR:-~}/.zsh_plugins.zsh
```

And that’s it!

## CleanMyMac and others

If you use CleanMyMac or similar tools, make sure to set it up to ignore the `antidote
home` folder, otherwise it may delete your plugins.

You may also change Antidote’s home folder, for example:

```zsh
export ANTIDOTE_HOME=~/Libary/antidote
```

## Options

There are a few options you can use that should cover most common use cases. Let’s take
a look!

### Kind

The `kind` annotation can be used to determine how a bundle should be treated.

#### zsh

The default is `kind:zsh`, which will look for files that match these globs:

- `*.plugin.zsh`
- `*.zsh`
- `*.sh`
- `*.zsh-theme`

And `source` them.

Example:

```zsh
$ antidote bundle zsh-users/zsh-autosuggestions kind:zsh
fpath+=( /Users/matt/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions )
source /Users/matt/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
```

#### path

The `kind:path` mode will just put the plugin folder in your `$PATH`.

Example:

```
$ antidote bundle romkatv/zsh-bench kind:path
export PATH="/Users/matt/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-bench:$PATH"
```

#### fpath

The `kind:fpath` only puts the plugin folder on the fpath, doing nothing else. It can be
especially useful for completion scripts that aren't intended to be sourced directly, or
for prompts that support `promptinit`.

Example:

```zsh
antidote bundle sindresorhus/pure kind:fpath
fpath+=( /Users/matt/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-sindresorhus-SLASH-pure )
```

#### clone

The `kind:clone` only gets the plugin, doing nothing else. It can be useful for managing
a package that isn’t directly used as a shell plugin.

Example:

```zsh
$ antidote bundle mbadolato/iTerm2-Color-Schemes kind:clone
```

#### defer

The `kind:defer` option defers loading of a plugin. This can be useful for plugins you
don't need available right away or are slow to load. Use with caution.

Example:

```zsh
$ antidote bundle olets/zsh-abbr kind:defer
fpath+=( /Users/matt/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer )
source /Users/matt/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer/zsh-defer.plugin.zsh
fpath+=( /Users/matt/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-olets-SLASH-zsh-abbr )
zsh-defer source /Users/matt/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-olets-SLASH-zsh-abbr/zsh-abbr.plugin.zsh
```

## Friendly Names

You can also change how Antidote names the plugin directories by adding this to your
`.zshrc`:

```zsh
zstyle ':antidote:bundle' use-friendly-names 'yes'
```

Now, the directories where plugins are stored is nicer to read:

```zsh
fpath+=( /Users/matt/Library/Caches/antidote/zsh-users__zsh-autosuggestions )
source /Users/matt/Library/Caches/antidote/zsh-users__zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
```

[antibody]:  https://getantibody.github.io

# antidote

> The fast, native, Zsh plugin manager

Antidote is a feature complete Zsh implementation of the legacy [Antibody][antibody]
plugin manager.

## Installation

### Recommended install

To get the best performance and a seamless install of antidote, the recommended method
would be to add the following snippet to your `.zshrc`:

```zsh
# clone antidote if necessary and generate a static plugin file
zhome=${ZDOTDIR:-$HOME}
if [[ ! $zhome/.zsh_plugins.zsh -nt $zhome/.zsh_plugins.txt ]]; then
  [[ -e $zhome/.antidote ]]        || git clone --depth=1 https://github.com/mattmc3/antidote.git $zhome/.antidote
  [[ -e $zhome/.zsh_plugins.txt ]] || touch $zhome/.zsh_plugins.txt
  (
    source $zhome/.antidote/antidote.zsh
    antidote bundle <$zhome/.zsh_plugins.txt >$zhome/.zsh_plugins.zsh
  )
fi
source $zhome/.zsh_plugins.zsh
unset zhome
```

### Manual install
<details>
  <summary>Static plugins</summary>

  If you prefer an entirely manual installation with as little as possible in your
  `.zshrc`, you could always clone antidote yourself:

  ```zsh
  git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote
  ```

  Then create a `.zsh_plugins.txt` file with some plugins in it:

  ```zsh
  echo "zsh-users/zsh-syntax-highlighting"  >| ${ZDOTDIR:-~}/.zsh_plugins.txt
  echo "zsh-users/zsh-autosuggestions"     >>| ${ZDOTDIR:-~}/.zsh_plugins.txt
  ```

  Then generate your static plugins zsh file:

  ```zsh
  antidote bundle <${ZDOTDIR:-~}/.zsh_plugins.txt >${ZDOTDIR:-~}/.zsh_plugins.zsh
  ```

  Then source your static plugins files from your `.zshrc`:

  ```zsh
  # .zshrc
  source ${ZDOTDIR:-~}/.zsh_plugins.zsh
  ```

  You will need to manually regenerate your `.zsh_plugins.zsh` yourself every time you
  change your plugins.
</details>

<details>
  <summary>Dynamic plugins</summary>

  **Note:** _This installation method is provided for legacy purposes only, and is not
  recommended._

  Clone antidote:

  ```zsh
  git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote
  ```

  Add the following snippet to your `.zshrc`

  ```zsh
  # zshrc

  # initialize antidote for dynamic plugins
  source ${ZDOTDIR:-~}/.antidote/antidote.zsh
  source <(antidote init)

  # bundle plugins individually
  antidote bundle zsh-users/zsh-syntax-highlighting
  antidote bundle zsh-users/zsh-autosuggestions

  # or bundle using a plugins file
  antidote bundle <${ZDOTDIR:-~}/.zsh_plugins.txt
  ```
</details>

## Usage

Antidote achieves its speed by doing all the work of cloning plugins up front and
generating the code your `.zshrc` needs to source those plugins. Typically, we want to
do this via a plugins file.

### Plugins file

A plugins file is basically any text file that has one plugin per line.

In our examples, let's assume we have a `${ZDOTDIR:-~}/.zsh_plugins.txt` file with these
contents:

```zsh
# .zsh_plugins.txt

# comments are supported like this
zshzoo/zfunctions
zshzoo/zshrc.d
zsh-users/zsh-completions

# empty lines are skipped

# annotations are also allowed:
ohmyzsh/ohmyzsh   path:lib/clipboard.zsh
ohmyzsh/ohmyzsh   path:plugins/colored-man-pages
romkatv/zsh-bench kind:path
olets/zsh-abbr    kind:defer

zsh-users/zsh-syntax-highlighting
zsh-users/zsh-history-substring-search
zsh-users/zsh-autosuggestions
```

Now that we have a plugins file, let's look how can we load them!

### Loading plugins

If you followed the [recommended install procedure](#recommended-install), your plugins
will be loaded via a statically generated plugins file. Basically, antidote will only
need to run when you change your `.zsh_plugins.txt` file, and then it will regenerate
the static file.

_Note that in this case, we will never want to call `antidote init`. **Be sure that's not
in your `.zshrc`**. If you did that, remove it from your `.zshrc` and start a fresh
terminal session. `antidote init` is a wrapper provided for backwards compatibility
with antibody and antigen, but no longer recommended._

Assuming the `.zsh_plugins.txt` be created above, we can run:

```zsh
antidote bundle < ${ZDOTDIR:-~}/.zsh_plugins.txt > ${ZDOTDIR:-~}/.zsh_plugins.zsh
```

We can run this at any time to update our `.zsh_plugins.zsh` file, however if you
followed the recommended install procedure you won't need to do this yourself.

Finally, the static generated plugins file gets sourced in your `.zshrc`.

```zsh
# .zshrc
source ${ZDOTDIR:-~}/.zsh_plugins.zsh
```

### Loading without a .zsh_plugins file

<details>
  <summary>Show details</summary>
  **Note:** _This method is provided for legacy purposes, but is slower and not
  recommended._

  For this to work, `antidote` needs to be wrapped into your `.zshrc`. To do that, run:

  ```zsh
  # .zshrc
  source <(antidote init)
  ```

  And reload your current shell or open a new one.

  Then, you will also need to tell antidote which plugins to bundle. This can also be done
  in the `.zshrc` file:

  ```zsh
  # .zshrc
  antidote bundle zsh-users/zsh-history-substring-search
  antidote bundle zsh-users/zsh-autosuggestions
  ```
</details>

## CleanMyMac or similar tools

If you use CleanMyMac or similar tools, make sure to set it up to ignore the `antidote
home` folder, otherwise it may delete your plugins.

You may also change Antidote's home folder, for example:

```zsh
export ANTIDOTE_HOME=~/Libary/antidote
```

## Options

There are a few options you can use that should cover most common use cases. Let's take
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
a package that isn't directly used as a shell plugin.

Example:

```zsh
$ antidote bundle mbadolato/iTerm2-Color-Schemes kind:clone
```

#### defer

The `kind:defer` option defers loading of a plugin. This can be useful for plugins you
don't need available right away or are slow to load. [Use with caution][deferred-init].

Example:

```zsh
$ antidote bundle olets/zsh-abbr kind:defer
fpath+=( /Users/matt/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer )
source /Users/matt/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer/zsh-defer.plugin.zsh
fpath+=( /Users/matt/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-olets-SLASH-zsh-abbr )
zsh-defer source /Users/matt/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-olets-SLASH-zsh-abbr/zsh-abbr.plugin.zsh
```

### Branch

You can also specify a branch to download, if you don't want the `main` branch for
whatever reason.

Example:

```zsh
$ antidote bundle zsh-users/zsh-autosuggestions branch:develop
fpath+=( /Users/matt/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions )
source /Users/matt/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
```

# Path

You may specify a subfolder or a specific file if the repo you are bundling contains
multiple plugins. This is especially useful for frameworks like [Oh-My-Zsh][ohmyzsh].

File Example:

```zsh
$ antidote bundle ohmyzsh/ohmyzsh path:lib/clipboard.zsh
source /Users/matt/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/lib/clipboard.zsh
```

Folder Example:

```zsh
$ antidote bundle ohmyzsh/ohmyzsh path:plugins/magic-enter
fpath+=( /Users/matt/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/magic-enter )
source /Users/matt/Library/Caches/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/plugins/magic-enter/magic-enter.plugin.zsh
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

## Benchmarks

You can see how antidote compares with other setups [here][benchmarks].

## Plugin authors

If you authored a Zsh plugin, the recommended antidote snippet to tell your users how to
install your plugin would be this:

```zsh
echo gh_user/gh_repo >>|${ZDOTDIR:~}/.zsh_plugins.txt
```

If that's too ugly, you can also recommend they run:

```zsh
source ${ZDOTDIR:-~}/.antidote/antidote.zsh
antidote install gh_user/gh_repo
```

## Credits

A big thank you to [Carlos](https://twitter.com/caarlos0) for all his work on
[antibody] over the years.

[antibody]:       https://getantibody.github.io
[benchmarks]:     https://github.com/romkatv/zsh-bench/blob/master/doc/linux-desktop.md
[deferred-init]:  https://github.com/romkatv/zsh-bench#deferred-initialization
[ohmyzsh]:        https://github.com/ohmyzsh/ohmyzsh

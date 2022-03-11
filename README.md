# antidote

<a title="GetAntidote"
   href="https://getantidote.github.io"
   align="right">
<img align="right"
     height="80"
     alt="GetAntidote Logo"
     src="https://avatars.githubusercontent.com/u/101279220?s=80&v=4">
</a>

> Get the cure - Zsh plugin management made awesome</blockquote>

Antidote is a feature complete Zsh implementation of the legacy [Antibody][antibody]
plugin manager.

## Documentation

The full documentation can be found at [https://getantidote.github.io][getantidote]

## History

> Antigen < Antibody < Antidote

The short version:

The original [Antigen][antigen] plugin manager was slow. [Antibody][antibody] was
written to address this, but was written in [Go][go], not Zsh. Other native Zsh plugin
managers caught up on speed, so it was deprecated. But Antibody had some other nice
features that aren't in other Zsh plugin managers. So [Antidote][getantidote] was
created to be the 3rd generation of antigen-compatible Zsh plugin managers.

## Installation

### Recommended install

The simplest way to use antidote is to call the `antidote load` command from your
`.zshrc`:

```zsh
# clone antidote if necessary
[[ -e ~/.antidote ]] || git clone https://github.com/mattmc3/antidote.git ~/.antidote

# source antidote
. ~/.antidote/antidote.zsh

# generate and source your static plugins file
antidote load
```

### Ultra high performance install

To squeeze out every last drop of performance, you can do all the things
`antidote load` does for you on your own. This snippet shows you how:

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

This method boils down to only the essentials. However, note that you'll really only be
saving small fractions of a second over using `antidote load` directly.

## Benchmarks

You can see how antidote compares with other setups [here][benchmarks].

## Plugin authors

If you authored a Zsh plugin, the recommended antidote snippet to tell your users how to
install your plugin would be this:

```zsh
antidote install gh_user/gh_repo
```

You can also do it more explicitly this way:

```zsh
echo gh_user/gh_repo >>|${ZDOTDIR:~}/.zsh_plugins.txt
```

## Credits

A big thank you to [Carlos](https://twitter.com/caarlos0) for all his work on
[antibody] over the years.

[antigen]:        https://github.com/zsh-users/antigen
[antibody]:       https://github.com/getantibody/antibody
[getantidote]:    https://getantidote.github.io
[go]:             https://go.dev
[benchmarks]:     https://github.com/romkatv/zsh-bench/blob/master/doc/linux-desktop.md

# antidote

[![MIT License](https://img.shields.io/badge/license-MIT-007EC7.svg)](/LICENSE)
![version](https://img.shields.io/badge/version-v1.8.6-df5e88)

<a title="GetAntidote"
   href="https://getantidote.github.io"
   align="right">
<img align="right"
     height="80"
     alt="GetAntidote Logo"
     src="https://avatars.githubusercontent.com/u/101279220?s=80&v=4">
</a>

> [Get the cure][getantidote]</blockquote>

[Antidote][getantidote] is a feature-complete Zsh implementation of the legacy [Antibody][antibody] plugin manager, which in turn was derived from [Antigen][antigen]. Antidote not only aims to provide continuity for those legacy plugin managers, but also to delight new users with high-performance, easy-to-use Zsh plugin management.

## Documentation

The full documentation can be found at [https://getantidote.github.io][getantidote]

## Help getting started

If you want to see a full-featured example Zsh configuration using antidote, you can have a look at this [example zdotdir](https://github.com/getantidote/zdotdir) project. Feel free to incorporate code or plugins from it into your own dotfiles, or you can fork it to get started building your own Zsh config from scratch driven by antidote.

## Installation

### Install with git

You can install the latest release of antidote by cloning it with `git`:

```zsh
# first, run this from an interactive zsh terminal session:
git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote
```

### Install with a package manager

antidote may also be available in your system's package manager:

- [macOS homebrew](https://formulae.brew.sh/formula/antidote): `brew install antidote`
- [Arch AUR](https://aur.archlinux.org/packages/zsh-antidote): `yay -S zsh-antidote`

### .zshrc

After installation, the simplest way to use antidote is to call the `antidote load` command from your `.zshrc`:

```zsh
# now, simply add these two lines in your ~/.zshrc

# source antidote
source ${ZDOTDIR:-~}/.antidote/antidote.zsh

# initialize plugins statically with ${ZDOTDIR:-~}/.zsh_plugins.txt
antidote load
```

More details available can be found at [https://getantidote.github.io][getantidote].

## Benchmarks

You can see how antidote compares with other setups [here][benchmarks].

## Plugin authors

If you authored a Zsh plugin, the recommended snippet for antidote is:

```zsh
antidote install gh_user/gh_repo
```

If your plugin is hosted somewhere other than GitHub, you can use this:

```zsh
antidote install https://bitbucket.org/bb_user/bb_repo
```

## Credits

A big thank you to [Carlos](https://twitter.com/caarlos0) for all his work on
[antibody] over the years.

[antigen]:        https://github.com/zsh-users/antigen
[antibody]:       https://github.com/getantibody/antibody
[getantidote]:    https://getantidote.github.io
[getantibody]:    https://github.com/getantibody/antibody
[benchmarks]:     https://github.com/romkatv/zsh-bench/blob/master/doc/linux-desktop.md
[zsh]:            https://www.zsh.org

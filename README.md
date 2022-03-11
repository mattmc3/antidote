# antidote

[![MIT License](https://img.shields.io/badge/license-MIT-007EC7.svg)](/LICENSE)
![version](https://img.shields.io/badge/version-v1.1.0-df5e88)

<a title="GetAntidote"
   href="https://getantidote.github.io"
   align="right">
<img align="right"
     height="80"
     alt="GetAntidote Logo"
     src="https://avatars.githubusercontent.com/u/101279220?s=80&v=4">
</a>

> [Get the cure][getantidote]</blockquote>

Antidote is a feature complete Zsh implementation of the legacy [Antibody][antibody]
plugin manager.

## Documentation

The full documentation can be found at [https://getantidote.github.io][getantidote]

## Installation

The recommended way to use antidote is to call the `antidote load` command from your
`.zshrc`:

```zsh
# clone antidote if necessary
[[ -e ~/.antidote ]] || git clone https://github.com/mattmc3/antidote.git ~/.antidote

# source antidote
. ~/.antidote/antidote.zsh

# generate and source plugins from ~/.zsh_plugins.txt
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
[go]:             https://go.dev
[benchmarks]:     https://github.com/romkatv/zsh-bench/blob/master/doc/linux-desktop.md
[zsh]:            https://www.zsh.org


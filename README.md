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

## Static loading of plugins

List your plugins in `${ZDOTDIR:-~}/.zsh_plugins.txt`. Then generate the static file:

```zsh
antidote bundle < ${ZDOTDIR:-~}/.zsh_plugins.txt > ${ZDOTDIR:-~}/.zsh_plugins.zsh
```

Finally, source the static file in your `.zshrc`:

```zsh
source ${ZDOTDIR:-~}/.zsh_plugins.zsh
```

## Customizing

You can change where Antidote stores your plugins by adding this to your `.zshrc`:

```zsh
ANTIDOTE_HOME=${ZDOTDIR:-~}/.antidote/.cache
```

You can also change how Antidote names the plugin directories by adding this to your
`.zshrc`:

```zsh
zstyle ':antidote:bundle' use-friendly-names
```

[antibody]:  https://getantibody.github.io

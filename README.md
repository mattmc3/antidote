# antidote

[![MIT License](https://img.shields.io/badge/license-MIT-007EC7.svg)](/LICENSE)
![version](https://img.shields.io/badge/version-v1.9.10-df5e88)

<a title="GetAntidote"
   href="https://antidote.sh"
   align="right">
<img align="right"
     height="80"
     alt="GetAntidote Logo"
     src="https://avatars.githubusercontent.com/u/101279220?s=80&v=4">
</a>

> [Get the cure][antidote]</blockquote>

[Antidote][antidote] is a feature-complete Zsh implementation of the legacy
[Antibody][antibody] plugin manager, which in turn was derived from [Antigen][antigen].
Antidote not only aims to provide continuity for those legacy plugin managers, but also
to delight new users with high-performance, easy-to-use Zsh plugin management.

## NOTICE

**The planned upcoming 2.0 release will stop defaulting to compatibility with
antibody.** If maintaining compatibility with antibody is important to you, you can
ensure that your config remains compatible by add the following `zstyle` to your config
**now**, before the 2.0 release goes live:

```zsh
zstyle ':antidote:compatibility-mode' 'antibody' 'on'
```

Breaking compatibility by default will allow antidote to continue to grow and gain new
features, as well as fix some long-standing issues that have always been present in
antibody, for example:

- In 2.0, `fpath` can be fully set at the beginning of your bundles in you static file,
  making setting up completion bundles properly way easier and less frustrating
  ([#74](https://github.com/mattmc3/antidote/discussions/74),
  [#144](https://github.com/mattmc3/antidote/issues/144)).
- bundles will no longer default to using fugly directory names
  ($ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar), making
  `zstyle ':antidote:bundle' use-friendly-names on` obsolete.
- probably some other minor deviations as well

Just to be clear, if you don't specifically care about backwards compatibility with
antibody, you do not need to change a thing. 2.x will not break your 1.x antidote
config. If you do care, be sure to add the compatibility mode `zstyle` above to your
config **now**, before the 2.0 release.

## Usage

Basic usage should look really familiar to you if you have used Antibody or Antigen.
Bundles (aka: Zsh plugins) are stored in a file typically called `.zsh_plugins.txt`.

```zsh
# .zsh_plugins.txt
rupa/z              # some bash plugins work too
sindresorhus/pure   # enhance your prompt

# you can even use Oh My Zsh plugins
getantidote/use-omz
ohmyzsh/ohmyzsh path:lib
ohmyzsh/ohmyzsh path:plugins/extract

# add fish-like features
zsh-users/zsh-syntax-highlighting
zsh-users/zsh-autosuggestions
zsh-users/zsh-history-substring-search
```

A typical `.zshrc` might then look like:

```zsh
# .zshrc
source /path-to-antidote/antidote.zsh
antidote load ${ZDOTDIR:-$HOME}/.zsh_plugins.txt
```

The full documentation can be found at [https://antidote.sh][antidote].

## Help getting started

If you want to see a full-featured example Zsh configuration using antidote, you can
have a look at this [example zdotdir](https://github.com/getantidote/zdotdir) project.
Feel free to incorporate code or plugins from it into your own dotfiles, or you can fork
it to get started building your own Zsh config from scratch driven by antidote.

## Installation

### Install with git

You can install the latest release of antidote by cloning it with `git`:

```zsh
# first, run this from an interactive zsh terminal session:
git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-$HOME}/.antidote
```

### Install with a package manager

antidote may also be available in your system's package manager:

- [macOS homebrew](https://formulae.brew.sh/formula/antidote): `brew install antidote`
- [Arch AUR](https://aur.archlinux.org/packages/zsh-antidote): `yay -S zsh-antidote`
- [Nix Home-Manager](https://mipmip.github.io/home-manager-option-search/?query=antidote) : `programs.zsh.antidote.enable = true;`

## Performance

antidote supports ultra-high performance plugin loads using a static plugin file.
It also allows deferred loading for [plugins that support it](https://github.com/romkatv/zsh-defer#caveats).

```zsh
# .zsh_plugins.txt
# some plugins support deferred loading
zdharma-continuum/fast-syntax-highlighting kind:defer
zsh-users/zsh-autosuggestions kind:defer
zsh-users/zsh-history-substring-search kind:defer
```

```zsh
# .zshrc
# Lazy-load antidote and generate the static load file only when needed
zsh_plugins=${ZDOTDIR:-$HOME}/.zsh_plugins
if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
  (
    source /path-to-antidote/antidote.zsh
    antidote bundle <${zsh_plugins}.txt >${zsh_plugins}.zsh
  )
fi
source ${zsh_plugins}.zsh
```

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

A big thank you to [Carlos](https://github.com/caarlos0) for all his work on
[antibody] over the years.

[antigen]:        https://github.com/zsh-users/antigen
[antibody]:       https://github.com/getantibody/antibody
[antidote]:       https://antidote.sh
[benchmarks]:     https://github.com/romkatv/zsh-bench/blob/master/doc/linux-desktop.md
[zsh]:            https://www.zsh.org

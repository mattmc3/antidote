# antidote bundle tests

## Setup

```zsh
% source ./tests/_setup.zsh
% source ./antidote.zsh
%
```

## Version

Show antidote's version:

```zsh
% antidote --version
antidote version 1.9.7
%
```

## Help

Show antidote's functionality:

```zsh
% antidote --help
antidote - the cure to slow zsh plugin management

usage: antidote [<flags>] <command> [<args> ...]

flags:
  -h, --help           Show context-sensitive help
  -v, --version        Show application version

commands:
  help      Show documentation
  load      Statically source all bundles from the plugins file
  bundle    Clone bundle(s) and generate the static load script
  install   Clone a new bundle and add it to your plugins file
  update    Update antidote and its cloned bundles
  purge     Remove a cloned bundle
  home      Print where antidote is cloning bundles
  list      List cloned bundles
  path      Print the path of a cloned bundle
  init      Initialize the shell for dynamic bundles
%
```

## Bundling

Bundle a repo at https://github.com/foobar/foo

```zsh
% which git
% antidote bundle foobar/foo
# antidote cloning foobar/foo...
fpath+=( $HOME/.cache/antidote/foobar/foo )
source $HOME/.cache/antidote/foobar/foo/foo.plugin.zsh
% tree $ANTIDOTE_HOME
%
```

## Teardown

```zsh
% t_teardown
%
```

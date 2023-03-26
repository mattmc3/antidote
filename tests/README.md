# antidote tests

Tests are run using two different test runners:
- [clitest](https://github.com/aureliojargas/clitest)
- [ztap](https://github.com/mattmc3/ztap)

`clitest` is used for the more straightforward testing, where the tests are in simple command/response format. The bulk of antidote's tests are now written in `clitest`, and utilize markdown files in this folder to house the tests in a literate format.

`ztap` is used for more in-depth testing where more sophisticated tests are needed. Examples are testing things that require larger code blocks, tests the deep inner workings of antidote, true integration tests, environmental testing (like `local_options` use and `setopt` side effects from plugins), or really anything else which benefits from proper throwaway Zsh sessions.

## Setup

A simple setup consists of:

- Remove existing antidote zstyles
- Don't really git things
- Setup antidote

```zsh
source <(zstyle -L ':antidote:*' | awk '{print "zstyle -d",$2}')
function git { echo "$@" }
ANTIDOTE_HOME=$PWD/tests/zdotdir/antidote_home
source ./antidote.zsh
```

But you probably just want to source setup...

```zsh
% source ./tests/_setup.zsh
%
```

## General

`antidote` with no args displays its help:

```zsh
% antidote
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

## Version

The `-v/--version` flag displays the current version:

```zsh
% antidote --version
antidote version 1.8.3
%
```

## Teardown

```zsh
% t_teardown
%
```

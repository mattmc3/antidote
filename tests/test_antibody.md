# Antibody

[antibody][antibody] is the legacy plugin manager antidote is based upon. antidote ships
with a full Zsh implementation of antibody as a standalone script as of version 1.9.8.

## clitest

This README serves as testable documentation using [clitest][clitest]. It can be tested
with:

```
clitest --list-run --prompt '%' --progress dot --color always \
  ./tests/test_antibody.md
```

We need a convenience function, `scrub`, so that test output doesn't have to have named
directories embedded and we can instead use variables like `$PWD` and `$HOME`.

```sh
% scrub() { sed -e "s|$PWD|\$PWD|g" -e "s|$HOME|\$HOME|g"; }
%
```

Also, adding the current directory to path allows us to avoid having to do `./antibody`
every time we call it, and can simply call `antibody` without the leading `./`.

```sh
% PATH=$PWD:$PATH
%
```

## Commands

### Version

Show version with `-v, --version`.

```sh
% antibody --version
antibody version 1.9.7
%
```

The `-v, --version` short and long flags are equivalent.

```sh
% test "$(antibody -v)" = "$(antibody --version)"  #=> --exit 0
%
```

### Help

Show help with the help command.

```sh
% antibody help
usage: antibody [<flags>] <command> [<args> ...]

A pure Zsh implementation of the legacy antibody plugin manager
Packaged with the antidote plugin manager

Flags:
  -h, --help           Show context-sensitive help.
  -v, --version        Show application version.

Commands:
  help [<command>...]
    Show help.

  bundle [<bundles>...]
    downloads a bundle and prints its source line

  update
    updates all previously bundled bundles

  home
    prints where antibody is cloning the bundles

  purge <bundle>
    purges a bundle from your computer

  list
    lists all currently installed bundles

  path <bundle>
    prints the path of a currently cloned bundle

  init
    initializes the shell so Antibody can work as expected

%
```

The`-h, --help` flags show help too.

```sh
% test "$(antibody help)" = "$(antibody -h)"  #=> --exit 0
% test "$(antibody -h)" = "$(antibody --help)"  #=> --exit 0
%
```

### Init

Use `source <(antibody init)` to initialize antibody. The `init` command produces a
script that wraps antibody for dynamic plugin loading.

See what the output produces:

```sh
% antibody init | scrub
#!/usr/bin/env zsh
antibody() {
  case "$1" in
  bundle)
    source <( $PWD/antibody $@ ) || $PWD/antibody $@
    ;;
  *)
    $PWD/antibody $@
    ;;
  esac
}

_antibody() {
  IFS=' ' read -A reply <<< "help bundle update home purge list path init"
}
compctl -K _antibody antibody
%
```

### Home

You can also see where antibody is keeping the plugins with the home command. The home
is different per system.

```sh
% T_ANTIBODY_OSTYPE=linux antibody home | scrub
$HOME/.cache/antibody
% T_ANTIBODY_OSTYPE=darwin antibody home | scrub
$HOME/Library/Caches/antibody
% T_ANTIBODY_OSTYPE=msys LOCALAPPDATA=C:\\Users\\testuser\\AppData\\Local antibody home | scrub
C:\Users\testuser\AppData\Local\antibody
%
```

You can also change Antibody’s home folder by manually setting `ANTIBODY_HOME` to a path
of your choosing:

```sh
% export ANTIBODY_HOME=$HOME/path/to/antibody/home
% antibody home | scrub
$HOME/path/to/antibody/home
%
```

Set ANTIBODY_HOME for remaining tests.

```sh
% export ANTIBODY_HOME="$HOME/.cache/antibody"
%
```

### Bundle

Bundling outputs the Zsh code necessary to load a Zsh plugin.

```sh
% antibody bundle ohmyzsh/ohmyzsh
source $HOME/.cache/antibody/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh/oh-my-zsh.sh
fpath+=( $HOME/.cache/antibody/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh )
%
```

### Path

You can see the path being used for a cloned bundle.

```sh
% antibody path ohmyzsh/ohmyzsh | scrub
$HOME/.cache/antibody/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh
%
```

This is particularly useful for projects like oh-my-zsh that rely on storing its path in
the $ZSH environment variable:

```sh
% ZSH=$(antibody path ohmyzsh/ohmyzsh)
%
```

### List

You can list bundles with `antibody list`:

```sh
% antibody list | scrub
https://github.com/ohmyzsh/ohmyzsh                               $HOME/.cache/antibody/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh
%
```

### Update

You can update bundles with `antibody update`:

```sh
% antibody update | scrub
Updating all bundles in $HOME/.cache/antibody...
antibody: updating: https://github.com/ohmyzsh/ohmyzsh
%
```

### Purge

Remove bundles with `antibody purge <bundle>`:

```sh
% export T_ANTIBODY_PURGE=0
% antibody purge ohmyzsh/ohmyzsh | scrub
Removing ohmyzsh/ohmyzsh...
rm -rf -- $HOME/.cache/antibody/https-COLON--SLASH--SLASH-github.com-SLASH-ohmyzsh-SLASH-ohmyzsh
removed!
%
```

## Misuse

Test bad subcommand:

```sh
% antibody foo  #=> --exit 1
% antibody foo 2>&1
antibody: error: expected command but got "foo", try --help
%
```

## Shellcheck

Here's how we know things were written well:

sh
$ shellcheck -e SC3043 $PWD/antibody
$


[antibody]: https://github.com/getantibody/antibody
[clitest]: https://github.com/aureliojargas/clitest

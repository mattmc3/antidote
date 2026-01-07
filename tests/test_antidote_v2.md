# antidote v2 tests

## Setup

```zsh
% path+=($PWD/bin)
% path+=($PWD/tests/bin)
% export ANTIDOTE_DEBUG=true
% export ANTIDOTE_SCRIPT="$PWD/bin/antidote.sh"
% export ANTIDOTE_HOME="$(antidote.sh home)"
% alias antidote2="$ANTIDOTE_SCRIPT"
%
```

## Passes shellcheck

Antidote is POSIX compliant:

```zsh
% shellcheck --shell sh "$ANTIDOTE_SCRIPT"
%
```

## antidote --version

Show antidote's version:

```zsh
% antidote2 --version
antidote version 2.0.0
%
```

## antidote help

Show antidote's functionality:

```zsh
% antidote2 --help
antidote - the cure to slow zsh plugin management

Usage: antidote [<flags>] <command> [<args> ...]

Flags:
  -h, --help           Show context-sensitive help
  -v, --version        Show application version

Commands:
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
% [ "$(antidote2 --help)" = "$(antidote2 -h)" ] || echo "antidote -h is broken"
% [ "$(antidote2 --help)" = "$(antidote2 help)" ] || echo "antidote help is broken"
%
```

Show bundle command help:

```zsh
% antidote2 bundle --help
Usage: antidote bundle [<bundles>...]

Clones a bundle and prints its source line.

Flags:
  -h, --help   Show context-sensitive help.

Args:
  [<bundles>]  Bundle list.
% [ "$(antidote2 bundle --help)" = "$(antidote2 bundle -h)" ] || echo "antidote bundle -h is broken"
% [ "$(antidote2 bundle --help)" = "$(antidote2 help bundle)" ] || echo "antidote help bundle is broken"
%
```

Show home command help:

```zsh
% antidote2 home --help
Usage: antidote home

Prints where antidote is cloning bundles.

Flags:
  -h, --help   Show context-sensitive help.
% [ "$(antidote2 home --help)" = "$(antidote2 home -h)" ] || echo "antidote home -h is broken"
% [ "$(antidote2 home --help)" = "$(antidote2 help home)" ] || echo "antidote help home is broken"
%
```

Show init command help:

```zsh
% antidote2 init --help
Usage: antidote init

Initializes the shell so antidote can load bundles dynmically.

Flags:
  -h, --help   Show context-sensitive help.
% [ "$(antidote2 init --help)" = "$(antidote2 init -h)" ] || echo "antidote init -h is broken"
% [ "$(antidote2 init --help)" = "$(antidote2 help init)" ] || echo "antidote help init is broken"
%
```

Show list command help:

```zsh
% antidote2 list --help
Usage: antidote list [-d|--details] [-bcprsu]

Lists all currently installed bundles

Flags:
  -h, --help     Show context-sensitive help.
  -d, --detail   Show full bundle details.

Format flags:
  -b             Bundle's branch.
  -c             Bundle's last commit date.
  -p             Bundle's path.
  -r             Bundle's short repo name.
  -s             Bundle's SHA.
  -u             Bundle's URL.
% [ "$(antidote2 list --help)" = "$(antidote2 list -h)" ] || echo "antidote list -h is broken"
% [ "$(antidote2 list --help)" = "$(antidote2 help list)" ] || echo "antidote help list is broken"
%
```

Show path command help:

```zsh
% antidote2 path --help
Usage: antidote path <bundle>

Prints the path of a currently cloned bundle.

Flags:
  -h, --help   Show context-sensitive help.

Args:
  <bundle>     The Bundle path to print.
% [ "$(antidote2 path --help)" = "$(antidote2 path -h)" ] || echo "antidote path -h is broken"
% [ "$(antidote2 path --help)" = "$(antidote2 help path)" ] || echo "antidote help path is broken"
%
```

Show purge command help:

```zsh
% antidote2 purge --help
Usage: antidote purge <bundle>

Purges a bundle from your computer.

Flags:
  -h, --help   Show context-sensitive help.

Args:
  <bundle>     The bundle to be purged.
% [ "$(antidote2 purge --help)" = "$(antidote2 purge -h)" ] || echo "antidote purge -h is broken"
% [ "$(antidote2 purge --help)" = "$(antidote2 help purge)" ] || echo "antidote help purge is broken"
%
```

Show update command help:

```zsh
% antidote2 update --help
Usage: antidote update [-b|--bundles] [-s|--self]
       antidote update <bundle>

Updates cloned bundle(s) and antidote itself.

Flags:
  -h, --help     Show context-sensitive help.
  -s, --self     Update antidote.
  -b, --bundles  Update bundles.

Args:
  <bundle>     The bundle to be updated.
%
```

## antidote home

```zsh
% antidote2 home | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME
%
```

Turn off ANTIDOTE_HOME variable

```zsh
% unset ANTIDOTE_HOME
%
```

macOS home

```zsh
% ANTIDOTE_OSTYPE=darwin antidote2 home | subenv
$HOME/Library/Caches/antidote
%
```

Linux home

```zsh
% ANTIDOTE_OSTYPE=linux antidote2 home | subenv
$HOME/.cache/antidote
%
```

Windows home

```zsh
% ANTIDOTE_OSTYPE=msys LOCALAPPDATA=C:\\Users\\FooBar\\AppData\\Local antidote2 home
C:\Users\FooBar\AppData\Local\antidote
%
```

Errors

```zsh
% antidote2 home foo; echo "err: $?"
antidote: error: unexpected 'foo'.
err: 1
%
```

Turn on ANTIDOTE_HOME variable

```zsh
% unset ANTIDOTE_OSTYPE
% export ANTIDOTE_HOME="$(antidote2 home)"
%
```

## antidote init

Show antidote's functionality:

```zsh
% antidote2 init | subenv ANTIDOTE_SCRIPT
#!/usr/bin/env zsh
function antidote {
  case "$1" in
    bundle)
      source <( "$ANTIDOTE_SCRIPT" "$@" ) || "$ANTIDOTE_SCRIPT" "$@"
      ;;
    *)
      "$ANTIDOTE_SCRIPT" "$@"
      ;;
  esac
}
%
```

## antidote --debug bundle_info

```zsh
% export ANTIDOTE_HOME="$(antidote2 home)"
% antidote2 --debug bundle_info foo/bar | subenv ANTIDOTE_HOME
BUNDLE_QUERY="foo/bar"
BUNDLE_NAME="bar"
BUNDLE_TYPE="repo"
BUNDLE_REPO="foo/bar"
BUNDLE_URL="https://github.com/foo/bar"
BUNDLE_PATH="$ANTIDOTE_HOME/foo/bar"
%
```

## antidote path <bundle>

```zsh
% antidote2 path
antidote: error: required argument 'bundle' not provided
% antidote2 path foo/bar
antidote: error: 'foo/bar' does not exist in cloned paths
%
```

## Teardown

```zsh
% # TODO
%
```

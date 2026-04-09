# antidote bundle tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## Version

Show antidote's version:

```zsh
% antidote --version  #=> --regex antidote version [0-9]+\.[0-9]+\.[0-9]+ \([a-f0-9]+\)
% zstyle ':antidote:test:version' show-sha off
% antidote --version
antidote version 2.1.0
% zstyle -d ':antidote:test:version' show-sha
%
```

## Help

Show antidote's functionality:

```zsh
% antidote --help
antidote - the cure to slow zsh plugin management

usage: antidote [<flags>] <command> [<args> ...]

flags:
  -h, --help            Show context-sensitive help
  -v, --version         Show application version
      --diagnostics     Show antidote and system diagnostics

commands:
  bundle    Clone bundle(s) and generate the static load script
  install   Clone a new bundle and add it to your plugins file
  update    Update antidote and its cloned bundles
  purge     Remove a cloned bundle
  home      Print where antidote is cloning bundles
  list      List cloned bundles
  path      Print the path of a cloned bundle
  snapshot  Save, restore, or list bundle snapshots
  init      Initialize the shell for dynamic bundles
  help      Show documentation
  load      Statically source all bundles from the plugins file
%
```

## Bundling

Bundle a repo at foo/bar

```zsh
% antidote bundle foo/bar
# antidote cloning foo/bar...
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"
%
```

Bundle a repo at https://fakegitsite.com/foo/bar

```zsh
% antidote bundle https://fakegitsite.com/foo/bar
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"
%
```

Bundle a repo at git@fakegitsite.com:foo/qux

```zsh
% antidote bundle git@fakegitsite.com:foo/qux
# antidote cloning git@fakegitsite.com:foo/qux...
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/qux" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/qux/qux.plugin.zsh"
% command rm -rf $ANTIDOTE_HOME/*
%
```

Bundle the foo/bar repo using escaped path-style directories:

```zsh
% zstyle ':antidote:bundle' path-style escaped
% antidote bundle foo/bar | subenv HOME
# antidote cloning foo/bar...
fpath+=( "$HOME/.cache/antidote/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar" )
source "$HOME/.cache/antidote/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar/bar.plugin.zsh"
% zstyle -d ':antidote:bundle' path-style
%
```

Bundle a specific branch of a repo with `branch:<branch>`.

Clean up

```zsh
% t_reset
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
%
```

Bundle a specific branch of a repo with `branch:<branch>`.

```zsh
% antidote purge foo/bar &>/dev/null
% antidote bundle foo/bar branch:dev
# antidote cloning foo/bar...
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"
% git -C $(antidote path foo/bar) rev-parse --abbrev-ref HEAD
dev
%
```

### Annotations: kind

Bundles support a `kind:` annotation. The default is `kind:zsh`.

```zsh
% antidote bundle foo/bar kind:zsh
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"
%
```

Bundle foo/bar with `kind:path` to add it to your `$PATH`.

```zsh
% antidote bundle foo/bar kind:path
export PATH="$HOME/.cache/antidote/fakegitsite.com/foo/bar:$PATH"
%
```

Bundle foo/bar with `kind:fpath` to add it to your `$fpath`.

```zsh
% antidote bundle foo/bar kind:fpath
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
%
```

Bundle foo/bar with `kind:clone` to just clone the repo, but do nothing to load it.

```zsh
% antidote bundle foo/bar kind:clone
%
```

Autoload a path within foo/bar with the `kind:autoload` annotation.

```zsh
% antidote bundle foo/baz kind:autoload path:functions
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz/functions" )
builtin autoload -Uz $fpath[-1]/*(N.:t)
%
```

Defer loading the foo/bar bundle with the `kind:defer` annotation.

```zsh
% antidote bundle foo/baz kind:defer
if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$HOME/.cache/antidote/fakegitsite.com/getantidote/zsh-defer" )
  source "$HOME/.cache/antidote/fakegitsite.com/getantidote/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/baz" )
zsh-defer source "$HOME/.cache/antidote/fakegitsite.com/foo/baz/baz.plugin.zsh"
%
```

### Annotations: path

Use the `path:<path>` annotation to load subplugins.

```zsh
% antidote bundle ohmy/ohmy path:plugins/docker
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/plugins/docker" )
source "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/plugins/docker/docker.plugin.zsh"
%
```

Use `path:<lib>` to load a whole directory full of files.

```zsh
% antidote bundle ohmy/ohmy path:lib
fpath+=( "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/lib" )
source "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/lib/lib1.zsh"
source "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/lib/lib2.zsh"
source "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/lib/lib3.zsh"
%
```

Use `path:<file>` to load a specific file.

```zsh
% antidote bundle ohmy/ohmy path:custom/themes/pretty.zsh-theme
source "$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy/custom/themes/pretty.zsh-theme"
%
```

### Annotations: conditional

Use a existing boolean function to wrap a bundle in `if` logic:

```zsh
% is-macos() { [[ "$OSTYPE" == "darwin"* ]]; }
% antidote bundle foo/bar conditional:is-macos
if is-macos; then
  fpath+=( "$HOME/.cache/antidote/fakegitsite.com/foo/bar" )
  source "$HOME/.cache/antidote/fakegitsite.com/foo/bar/bar.plugin.zsh"
fi
%
```

## Dynamic bundling

If you run `source <(antidote init)`, antidote will emit a wrapper so that you can
dynamically bundle.

```zsh
% antidote init
#!/usr/bin/env zsh
function antidote {
  case "$1" in
    bundle)
      source <( ANTIDOTE_DYNAMIC=true antidote-dispatch $@ ) || ANTIDOTE_DYNAMIC=true antidote-dispatch $@
      ;;
    *)
      ANTIDOTE_DYNAMIC=true antidote-dispatch $@
      ;;
  esac
}
%
```

## Home

Show where antidote stores its bundles:

```zsh
% antidote home | subenv HOME
$HOME/.cache/antidote
%
```

## List bundles

List path and URL (default):

```zsh
% antidote list | sort | subenv HOME | sed $'s/\t/    /g'
$HOME/.cache/antidote/fakegitsite.com/bar/baz    https://fakegitsite.com/bar/baz
$HOME/.cache/antidote/fakegitsite.com/foo/bar    https://fakegitsite.com/foo/bar
$HOME/.cache/antidote/fakegitsite.com/foo/baz    https://fakegitsite.com/foo/baz
$HOME/.cache/antidote/fakegitsite.com/foo/qux    git@fakegitsite.com:foo/qux
$HOME/.cache/antidote/fakegitsite.com/getantidote/zsh-defer    https://fakegitsite.com/getantidote/zsh-defer
$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy    https://fakegitsite.com/ohmy/ohmy
%
```

List directories:

```zsh
% antidote list --dirs | subenv HOME
$HOME/.cache/antidote/fakegitsite.com/bar/baz
$HOME/.cache/antidote/fakegitsite.com/foo/bar
$HOME/.cache/antidote/fakegitsite.com/foo/baz
$HOME/.cache/antidote/fakegitsite.com/foo/qux
$HOME/.cache/antidote/fakegitsite.com/getantidote/zsh-defer
$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy
%
```

## Bundle paths

Show the path to a bundle:

```zsh
% ZSH=$(antidote path ohmy/ohmy)
% echo $ZSH | subenv HOME
$HOME/.cache/antidote/fakegitsite.com/ohmy/ohmy
%
```

## Update bundles

```zsh
% zstyle ':antidote:test:version' show-sha off
% zstyle ':antidote:test:git' autostash off
% antidote update
Updating bundles...
antidote: checking for updates: bar/baz
antidote: checking for updates: foo/bar
antidote: checking for updates: foo/baz
antidote: checking for updates: git@fakegitsite.com:foo/qux
antidote: checking for updates: getantidote/zsh-defer
antidote: checking for updates: ohmy/ohmy
Waiting for bundle updates to complete...

Bundle updates complete.

Updating antidote...
antidote self-update complete.

antidote version 2.1.0
%
```

## Teardown

```zsh
% t_teardown
%
```

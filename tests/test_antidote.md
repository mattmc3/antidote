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
% antidote --version
antidote version 1.9.10 (abcd123)
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
% antidote bundle foobar/foo
# antidote cloning foobar/foo...
fpath+=( "$HOME/.cache/antidote/foobar/foo" )
source "$HOME/.cache/antidote/foobar/foo/foo.plugin.zsh"
%
```

Bundle a repo at https://gitlab.com/foobar/bar

```zsh
% antidote bundle https://gitlab.com/foobar/bar
# antidote cloning foobar/bar...
fpath+=( "$HOME/.cache/antidote/foobar/bar" )
source "$HOME/.cache/antidote/foobar/bar/bar.plugin.zsh"
%
```

Bundle a repo at git@bitbucket.org:foobar/baz

```zsh
% antidote bundle git@bitbucket.org:foobar/baz
# antidote cloning foobar/baz...
fpath+=( "$HOME/.cache/antidote/foobar/baz" )
source "$HOME/.cache/antidote/foobar/baz/baz.plugin.zsh"
%
```

Bundle the foo/bar repo using old antibody style directories:

```zsh
% zstyle ':antidote:bundle' use-friendly-names off
% antidote bundle foo/bar
# antidote cloning foo/bar...
fpath+=( "$HOME/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar" )
source "$HOME/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar/bar.plugin.zsh"
% zstyle ':antidote:bundle' use-friendly-names on
%
```

Bundle a specific branch of a repo with `branch:<branch>`.

```zsh
% antidote bundle foobar/foo branch:dev
# antidote cloning foobar/foo...
fpath+=( "$HOME/.cache/antidote/foobar/foo" )
source "$HOME/.cache/antidote/foobar/foo/foo.plugin.zsh"
%
```

Clean up

```zsh
% t_reset
%
```

### Annotations: kind

Bundles support a `kind:` annotation. The default is `kind:zsh`.

```zsh
% antidote bundle foo/bar kind:zsh
fpath+=( "$HOME/.cache/antidote/foo/bar" )
source "$HOME/.cache/antidote/foo/bar/bar.plugin.zsh"
%
```

Bundle foo/bar with `kind:path` to add it to your `$PATH`.

```zsh
% antidote bundle foo/bar kind:path
export PATH="$HOME/.cache/antidote/foo/bar:$PATH"
%
```

Bundle foo/bar with `kind:fpath` to add it to your `$fpath`.

```zsh
% antidote bundle foo/bar kind:fpath
fpath+=( "$HOME/.cache/antidote/foo/bar" )
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
fpath+=( "$HOME/.cache/antidote/foo/baz/functions" )
builtin autoload -Uz $fpath[-1]/*(N.:t)
%
```

Defer loading the foo/bar bundle with the `kind:defer` annotation.

```zsh
% antidote bundle foo/baz kind:defer
if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$HOME/.cache/antidote/getantidote/zsh-defer" )
  source "$HOME/.cache/antidote/getantidote/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$HOME/.cache/antidote/foo/baz" )
zsh-defer source "$HOME/.cache/antidote/foo/baz/baz.plugin.zsh"
%
```

### Annotations: path

Use the `path:<path>` annotation to load subplugins.

```zsh
% antidote bundle ohmy/ohmy path:plugins/docker
fpath+=( "$HOME/.cache/antidote/ohmy/ohmy/plugins/docker" )
source "$HOME/.cache/antidote/ohmy/ohmy/plugins/docker/docker.plugin.zsh"
%
```

Use `path:<lib>` to load a whole directory full of files.

```zsh
% antidote bundle ohmy/ohmy path:lib
fpath+=( "$HOME/.cache/antidote/ohmy/ohmy/lib" )
source "$HOME/.cache/antidote/ohmy/ohmy/lib/lib1.zsh"
source "$HOME/.cache/antidote/ohmy/ohmy/lib/lib2.zsh"
source "$HOME/.cache/antidote/ohmy/ohmy/lib/lib3.zsh"
%
```

Use `path:<file>` to load a specific file.

```zsh
% antidote bundle ohmy/ohmy path:custom/themes/pretty.zsh-theme
source "$HOME/.cache/antidote/ohmy/ohmy/custom/themes/pretty.zsh-theme"
%
```

### Annotations: conditional

Use a existing boolean function to wrap a bundle in `if` logic:

```zsh
% is-macos() { [[ "$OSTYPE" == "darwin"* ]]; }
% antidote bundle foo/bar conditional:is-macos
if is-macos; then
  fpath+=( "$HOME/.cache/antidote/foo/bar" )
  source "$HOME/.cache/antidote/foo/bar/bar.plugin.zsh"
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
      source <( antidote-main $@ ) || antidote-main $@
      ;;
    *)
      antidote-main $@
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

List directories:

```zsh
% antidote list --dirs | subenv HOME
$HOME/.cache/antidote/foo/bar
$HOME/.cache/antidote/foo/baz
$HOME/.cache/antidote/foo/qux
$HOME/.cache/antidote/getantidote/zsh-defer
$HOME/.cache/antidote/ohmy/ohmy
%
```

List repo URLs:

```zsh
% antidote list --url
git@github.com:foo/qux
https://github.com/foo/bar
https://github.com/foo/baz
https://github.com/getantidote/zsh-defer
https://github.com/ohmy/ohmy
%
```

List short repos:

```zsh
% antidote list --short
foo/bar
foo/baz
getantidote/zsh-defer
git@github.com:foo/qux
ohmy/ohmy
%
```

## Bundle paths

Show the path to a bundle:

```zsh
% ZSH=$(antidote path ohmy/ohmy)
% echo $ZSH | subenv HOME
$HOME/.cache/antidote/ohmy/ohmy
%
```

## Update bundles

```zsh
% antidote update
Updating bundles...
antidote: checking for updates: https://github.com/foo/bar
antidote: checking for updates: https://github.com/foo/baz
antidote: checking for updates: git@github.com:foo/qux
antidote: checking for updates: https://github.com/getantidote/zsh-defer
antidote: checking for updates: https://github.com/ohmy/ohmy
Waiting for bundle updates to complete...

Bundle updates complete.

Updating antidote...
antidote self-update complete.

antidote version 1.9.10 (abcd123)
%
```

## Teardown

```zsh
% t_teardown
%
```

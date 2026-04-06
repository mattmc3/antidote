# antidote use: directive tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
% function bundle_parser() { antidote __private__ bundle_parser_serialize "$@"; }
%
```

## use: alone emits a single clone entry

```zsh
% echo 'use:foo/bar' | bundle_parser | print_parsed_bundle
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
%
```

## use: with path: — clone entry has no path, path is only a prefix for words

```zsh
% echo 'use:foo/bar path:plugins' | bundle_parser | print_parsed_bundle
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
%
```

## use: with kind: — kind becomes the default for words, clone entry is always clone

```zsh
% printf 'use:foo/bar path:plugins kind:fpath\nextract\n' | bundle_parser | print_parsed_bundle
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : fpath
path        : plugins/extract
%
```

## word after use: gets default kind:zsh and path prefix

```zsh
% printf 'use:foo/bar path:plugins\nextract\ngit\n' | bundle_parser | print_parsed_bundle
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : zsh
path        : plugins/extract
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : zsh
path        : plugins/git
%
```

## word-level kind: overrides use: default

```zsh
% printf 'use:foo/bar path:plugins kind:zsh\nextract kind:fpath\n' | bundle_parser | print_parsed_bundle
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : fpath
path        : plugins/extract
%
```

## use: annotations (branch, etc.) inherited by clone entry and all words

```zsh
% printf 'use:foo/bar path:plugins branch:baz\nextract\ngit\n' | bundle_parser | print_parsed_bundle
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
branch      : baz
kind        : clone
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
branch      : baz
kind        : zsh
path        : plugins/extract
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
branch      : baz
kind        : zsh
path        : plugins/git
%
```

## word-level annotation overrides inherited use: annotation

```zsh
% printf 'use:foo/bar path:plugins branch:main\nextract branch:dev\ngit\n' | bundle_parser | print_parsed_bundle
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
branch      : main
kind        : clone
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
branch      : dev
kind        : zsh
path        : plugins/extract
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
branch      : main
kind        : zsh
path        : plugins/git
%
```

## use: with no path: — word becomes the full path value

```zsh
% printf 'use:foo/bar\nextract\n' | bundle_parser | print_parsed_bundle
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : zsh
path        : extract
%
```

## word without active use context is left as-is

```zsh
% echo 'extract' | bundle_parser | print_parsed_bundle
__bundle__  : extract
__type__    : word
%
```

## full fixture: multiple use: blocks, non-word passthrough, branch inheritance, context persistence

```zsh
% antidote bundle <$T_TESTDATA/.zsh_plugins_using.txt | subenv ANTIDOTE_HOME  #=> --file testdata/.zsh_plugins_using.zsh
%
```

## Teardown

```zsh
% t_teardown
%
```

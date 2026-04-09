# antidote using: directive tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
% function bundle_parser() { antidote __private__ bundle_parser_serialize "$@"; }
%
```

## using: alone emits a single clone entry

```zsh
% echo 'using:foo/bar' | bundle_parser | print_parsed_bundle
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
%
```

## using: with path: — clone entry has no path, path is only a prefix for words

```zsh
% echo 'using:foo/bar path:plugins' | bundle_parser | print_parsed_bundle
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
%
```

## using: with kind: — kind becomes the default for words, clone entry is always clone

```zsh
% printf 'using:foo/bar path:plugins kind:fpath\nextract\n' | bundle_parser | print_parsed_bundle
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
kind        : fpath
path        : plugins/extract
%
```

## word after using: gets default kind:zsh and path prefix

```zsh
% printf 'using:foo/bar path:plugins\nextract\ngit\n' | bundle_parser | print_parsed_bundle
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
kind        : zsh
path        : plugins/extract
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
kind        : zsh
path        : plugins/git
%
```

## word-level kind: overrides using: default

```zsh
% printf 'using:foo/bar path:plugins kind:zsh\nextract kind:fpath\n' | bundle_parser | print_parsed_bundle
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
kind        : fpath
path        : plugins/extract
%
```

## using: annotations (branch, etc.) inherited by clone entry and all words

```zsh
% printf 'using:foo/bar path:plugins branch:baz\nextract\ngit\n' | bundle_parser | print_parsed_bundle
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
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
branch      : baz
kind        : zsh
path        : plugins/extract
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
branch      : baz
kind        : zsh
path        : plugins/git
%
```

## word-level annotation overrides inherited using: annotation

```zsh
% printf 'using:foo/bar path:plugins branch:main\nextract branch:dev\ngit\n' | bundle_parser | print_parsed_bundle
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
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
branch      : dev
kind        : zsh
path        : plugins/extract
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
branch      : main
kind        : zsh
path        : plugins/git
%
```

## using: with no path: — word becomes the full path value

```zsh
% printf 'using:foo/bar\nextract\n' | bundle_parser | print_parsed_bundle
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
kind        : zsh
path        : extract
%
```

## word without active using: context is an error

```zsh
% echo 'extract' | bundle_parser | print_parsed_bundle
__bundle__  : extract
__error__   : invalid bundle 'extract'. Are you missing a 'using:' directive?
__severity__: error
__type__    : using_subplugin
%
```

## using: with URL form

```zsh
% echo 'using:https://fakegitsite.com/foo/bar path:plugins' | bundle_parser | print_parsed_bundle | subenv ANTIDOTE_HOME
__bundle__  : https://fakegitsite.com/foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : url
__url__     : https://fakegitsite.com/foo/bar
kind        : clone
%
```

## using: with SSH URL form

```zsh
% echo 'using:git@fakegitsite.com:foo/bar path:plugins' | bundle_parser | print_parsed_bundle | subenv ANTIDOTE_HOME
__bundle__  : git@fakegitsite.com:foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : git@fakegitsite.com:foo/bar
__type__    : ssh_url
__url__     : git@fakegitsite.com:foo/bar
kind        : clone
%
```

## using: annotations like conditional: are inherited by words

```zsh
% printf 'using:foo/bar path:plugins conditional:is-macos\ndocker\n' | bundle_parser | print_parsed_bundle | subenv ANTIDOTE_HOME
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
conditional : is-macos
kind        : clone
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : using_subplugin
__url__     : https://fakegitsite.com/foo/bar
conditional : is-macos
kind        : zsh
path        : plugins/docker
%
```

## using: with empty target is an error

```zsh
% antidote bundle 'using:' 2>&1  #=> --exit 1
# antidote: error on line 1: invalid using: target ''
%
```

## using: with malformed target is an error

```zsh
% antidote bundle 'using:foo@bar' 2>&1  #=> --exit 1
# antidote: error on line 1: invalid using: target 'foo@bar'
%
```

## invalid bundle mixed with valid — error is shown but valid output is still produced

```zsh
% printf 'foo/bar\nfoo\n' | antidote bundle 2>&1  #=> --exit 1
# antidote: error on line 2: invalid bundle 'foo'. Are you missing a 'using:' directive?
source $ANTIDOTE_HOME/fakegitsite.com/foo/bar/foo_bar.plugin.zsh
%
```

## full fixture: multiple using: blocks, non-word passthrough, branch inheritance, context persistence

```zsh
% antidote bundle <$T_TESTDATA/.zsh_plugins_using.txt | subenv ANTIDOTE_HOME HOME ZDOTDIR  #=> --file testdata/.zsh_plugins_using.zsh
%
```

## Teardown

```zsh
% t_teardown
%
```

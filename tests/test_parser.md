# antidote bundle_parser tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## Test bundle parser associative arrays

The bundle parser takes the antidote bundle format and returns a flat key-value
string that can be read into an associative array.

Test empty:

```zsh
% echo | antidote __private__ bundle_parser
% echo '# This is a full line comment' | antidote __private__ bundle_parser
%
```

Test assoc array for repo

```zsh
% echo 'foo/bar' | antidote __private__ bundle_parser | print_aarr
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
%
```

Test assoc array for repo in escaped path

```zsh
% zstyle ':antidote:bundle' path-style escaped
% echo 'foo/bar' | antidote __private__ bundle_parser | print_aarr
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
% zstyle -d ':antidote:bundle' path-style
%
```

Test assoc array for path

```zsh
% echo '$ZSH_CUSTOM/foo' | antidote __private__ bundle_parser | print_aarr
__bundle__  : $ZSH_CUSTOM/foo
__type__    : path
%
```

Test assoc array for jibberish

```zsh
% echo 'a b c d:e:f' | antidote __private__ bundle_parser | print_aarr
__bundle__  : a
__error__   : error: Expecting 'key:value' form for annotation 'c'.
__type__    : word
d           : e:f
% echo 'foo bar:baz' | antidote __private__ bundle_parser | print_aarr
__bundle__  : foo
__type__    : word
bar         : baz
%
```

Test assoc array for everything

```zsh
% echo 'foo/bar branch:baz kind:zsh path:plugins/baz pre:precmd post:"post cmd"' | antidote __private__ bundle_parser | print_aarr
__bundle__  : foo/bar
__dir__     : $ANTIDOTE_HOME/fakegitsite.com/foo/bar
__short__   : foo/bar
__type__    : repo
__url__     : https://fakegitsite.com/foo/bar
branch      : baz
kind        : zsh
path        : plugins/baz
post        : post cmd
pre         : precmd
%
```

## Test specific keys have known values

Test __bundle__:

```zsh
% echo 'foo/bar' | antidote __private__ bundle_parser | bundle_val __bundle__
foo/bar
%
```

Test __type__:

```zsh
% echo 'foo/bar' | antidote __private__ bundle_parser | bundle_val __type__
repo
% echo 'https://github.com/foo/bar' | antidote __private__ bundle_parser | bundle_val __type__
url
% echo 'git@bitbucket.org:foo/bar' | antidote __private__ bundle_parser | bundle_val __type__
ssh_url
% echo '$foo/bar' | antidote __private__ bundle_parser | bundle_val __type__
path
% echo '$foo/bar/baz.zsh' | antidote __private__ bundle_parser | bundle_val __type__
path
% echo '~foo/bar' | antidote __private__ bundle_parser | bundle_val __type__
path
% echo '~/foo' | antidote __private__ bundle_parser | bundle_val __type__
path
% echo './foo.zsh' | antidote __private__ bundle_parser | bundle_val __type__
path
% echo '../foo.zsh' | antidote __private__ bundle_parser | bundle_val __type__
path
% echo 'foo/bar/' | antidote __private__ bundle_parser | bundle_val __type__
relpath
% echo 'foo:bar' | antidote __private__ bundle_parser | bundle_val __type__
?
% echo 'bad@gitsite.com/foo/bar' | antidote __private__ bundle_parser | bundle_val __type__
?
% echo 'http:/badsite.com/foo/bar' | antidote __private__ bundle_parser | bundle_val __type__
?
% echo 'https://badsite.com/foo/bar/baz' | antidote __private__ bundle_parser | bundle_val __type__
malformed_url
% echo 'https://badsite.com/foo' | antidote __private__ bundle_parser | bundle_val __type__
malformed_url
%
```

Test __url__:

```zsh
% echo 'foo/bar' | antidote __private__ bundle_parser | bundle_val __url__
https://fakegitsite.com/foo/bar
% echo 'https://github.com/foo/bar' | antidote __private__ bundle_parser | bundle_val __url__
https://github.com/foo/bar
% echo 'git@bitbucket.org:foo/bar' | antidote __private__ bundle_parser | bundle_val __url__
git@bitbucket.org:foo/bar
% echo '$foo/bar' | antidote __private__ bundle_parser | bundle_val __url__

% echo 'bad@gitsite.com/foo/bar' | antidote __private__ bundle_parser | bundle_val __url__

% echo 'http:/badsite.com/foo/bar' | antidote __private__ bundle_parser | bundle_val __type__
?
% echo 'https://badsite.com/foo/bar/baz' | antidote __private__ bundle_parser | bundle_val __url__
https://badsite.com/foo/bar/baz
% echo 'https://badsite.com/foo' | antidote __private__ bundle_parser | bundle_val __url__
https://badsite.com/foo
%
```

## Test __bundle__ for various bundle types

```zsh
% echo 'foo/bar' | antidote __private__ bundle_parser | bundle_val __bundle__
foo/bar
% echo 'https://github.com/foo/bar' | antidote __private__ bundle_parser | bundle_val __bundle__
https://github.com/foo/bar
% echo 'git@bitbucket.org:foo/bar' | antidote __private__ bundle_parser | bundle_val __bundle__
git@bitbucket.org:foo/bar
% echo '$foo/bar' | antidote __private__ bundle_parser | bundle_val __bundle__
$foo/bar
% echo '$foo/bar/baz.zsh' | antidote __private__ bundle_parser | bundle_val __bundle__
$foo/bar/baz.zsh
% echo '~foo/bar' | antidote __private__ bundle_parser | bundle_val __bundle__
~foo/bar
% echo '~/foo' | antidote __private__ bundle_parser | bundle_val __bundle__
~/foo
% echo './foo.zsh' | antidote __private__ bundle_parser | bundle_val __bundle__
./foo.zsh
% echo '../foo.zsh' | antidote __private__ bundle_parser | bundle_val __bundle__
../foo.zsh
% echo 'foo/bar/' | antidote __private__ bundle_parser | bundle_val __bundle__
foo/bar/
% echo 'foo:bar' | antidote __private__ bundle_parser | bundle_val __bundle__
foo:bar
% echo 'bad@gitsite.com/foo/bar' | antidote __private__ bundle_parser | bundle_val __bundle__
bad@gitsite.com/foo/bar
% echo 'http:/badsite.com/foo/bar' | antidote __private__ bundle_parser | bundle_val __bundle__
http:/badsite.com/foo/bar
% echo 'https://badsite.com/foo/bar/baz' | antidote __private__ bundle_parser | bundle_val __bundle__
https://badsite.com/foo/bar/baz
% echo 'https://badsite.com/foo' | antidote __private__ bundle_parser | bundle_val __bundle__
https://badsite.com/foo
%
```

## Teardown

```zsh
% t_teardown
%
```

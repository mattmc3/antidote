# antidote core tests

## Setup

```zsh
% source $PWD/tests/scripts/setup.zsh
%
```

## Helpers

### Bundle type

```zsh
% __antidote_bundle_type $PWD/antidote.zsh
file
% __antidote_bundle_type $PWD/functions
dir
% __antidote_bundle_type 'git@github.com:foo/bar.git'
sshurl
% __antidote_bundle_type 'https://github.com/foo/bar'
url
% __antidote_bundle_type 'https:/bad.com/foo/bar.git'
unk
% __antidote_bundle_type ''
empty
% __antidote_bundle_type '    '
empty
% __antidote_bundle_type /foo/bar
path
% __antidote_bundle_type /foobar
path
% __antidote_bundle_type foobar/
relpath
% __antidote_bundle_type '~/foo/bar'
path
% __antidote_bundle_type '$foo/bar'
path
% __antidote_bundle_type foo/bar
repo
% __antidote_bundle_type bar/baz.git
repo
% __antidote_bundle_type foo/bar/baz
relpath
% __antidote_bundle_type foobar
word
% __antidote_bundle_type foo bar baz
word
% __antidote_bundle_type 'foo bar baz'
word
%
```

### Bundle name

```zsh
% __antidote_bundle_name $HOME/.zsh/custom/lib/lib1.zsh
$HOME/.zsh/custom/lib/lib1.zsh
% __antidote_bundle_name $HOME/.zsh/plugins/myplugin
$HOME/.zsh/plugins/myplugin
% __antidote_bundle_name 'git@github.com:foo/bar.git'
foo/bar
% __antidote_bundle_name 'https://github.com/foo/bar'
foo/bar
% __antidote_bundle_name 'https:/bad.com/foo/bar.git'
https:/bad.com/foo/bar.git
% __antidote_bundle_name ''

% __antidote_bundle_name /foo/bar
/foo/bar
% __antidote_bundle_name /foobar
/foobar
% __antidote_bundle_name foobar/
foobar/
% __antidote_bundle_name '~/foo/bar'
$HOME/foo/bar
% __antidote_bundle_name '$foo/bar'
$foo/bar
% __antidote_bundle_name foo/bar
foo/bar
% __antidote_bundle_name bar/baz.git
bar/baz.git
% __antidote_bundle_name foo/bar/baz
foo/bar/baz
% __antidote_bundle_name foobar
foobar
% __antidote_bundle_name foo bar baz
foo
% __antidote_bundle_name 'foo bar baz'
foo bar baz
%
```

### Collect

```zsh
% printf '%s\n' x y z | __antidote_collect --foo --bar a b c
--foo
--bar
a
b
c
x
y
z
%
```

### To URL

Short repos:

```zsh
% __antidote_tourl ohmyzsh/ohmyzsh
https://github.com/ohmyzsh/ohmyzsh
% __antidote_tourl sindresorhus/pure
https://github.com/sindresorhus/pure
% __antidote_tourl foo/bar
https://github.com/foo/bar
%
```

Proper URLs don't change:

```zsh
% __antidote_tourl https://github.com/ohmyzsh/ohmyzsh
https://github.com/ohmyzsh/ohmyzsh
% __antidote_tourl http://github.com/ohmyzsh/ohmyzsh
http://github.com/ohmyzsh/ohmyzsh
% __antidote_tourl ssh://github.com/ohmyzsh/ohmyzsh
ssh://github.com/ohmyzsh/ohmyzsh
% __antidote_tourl git://github.com/ohmyzsh/ohmyzsh
git://github.com/ohmyzsh/ohmyzsh
% __antidote_tourl ftp://github.com/ohmyzsh/ohmyzsh
ftp://github.com/ohmyzsh/ohmyzsh
% __antidote_tourl git@github.com:sindresorhus/pure.git
git@github.com:sindresorhus/pure.git
%
```

## Teardown

```zsh
% t_teardown
%
```

# antidote helper tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## Safe removal

Appease my paranoia and ensure that you can't remove a path you shouldn't be able to:

```zsh
% antidote __private__ del -rf -- /foo/bar
antidote: Blocked attempt to rm path: '/foo/bar'.
%
```

## Bundle type

```zsh
% antidote __private__ bundle_type $T_PRJDIR/antidote.zsh
file
% antidote __private__ bundle_type $T_PRJDIR/functions
dir
% antidote __private__ bundle_type '$T_PRJDIR/antidote.zsh'
file
% antidote __private__ bundle_type \$T_PRJDIR/functions
dir
% antidote __private__ bundle_type 'git@fakegitsite.com:foo/bar.git'
ssh_url
% antidote __private__ bundle_type 'https://fakegitsite.com/foo/bar'
url
% antidote __private__ bundle_type 'https:/bad.com/foo/bar.git'
?
% antidote __private__ bundle_type ''
empty
% antidote __private__ bundle_type '    '
empty
% antidote __private__ bundle_type /foo/bar
path
% antidote __private__ bundle_type /foobar
path
% antidote __private__ bundle_type foobar/
relpath
% antidote __private__ bundle_type '~/foo/bar'
path
% antidote __private__ bundle_type '$foo/bar'
path
% antidote __private__ bundle_type \$ZDOTDIR/foo
path
% antidote __private__ bundle_type \$ZDOTDIR/.zsh_plugins.txt
file
% touch ~/.zshenv
% antidote __private__ bundle_type '~/.zshenv'
file
% antidote __private__ bundle_type '~/null'
path
% antidote __private__ bundle_type foo/bar
repo
% antidote __private__ bundle_type bar/baz.git
repo
% antidote __private__ bundle_type foo/bar/baz
relpath
% antidote __private__ bundle_type foobar
word
% antidote __private__ bundle_type foo bar baz
word
% antidote __private__ bundle_type 'foo bar baz'
word
%
```

## Bundle name

```zsh
% antidote __private__ bundle_name $HOME/.zsh/custom/lib/lib1.zsh
$HOME/.zsh/custom/lib/lib1.zsh
% antidote __private__ bundle_name $HOME/.zsh/plugins/myplugin
$HOME/.zsh/plugins/myplugin
% antidote __private__ bundle_name 'git@fakegitsite.com:foo/bar.git'
foo/bar
% antidote __private__ bundle_name 'https://fakegitsite.com/foo/bar'
foo/bar
% antidote __private__ bundle_name 'https:/bad.com/foo/bar.git'
https:/bad.com/foo/bar.git
% antidote __private__ bundle_name ''

% antidote __private__ bundle_name /foo/bar
/foo/bar
% antidote __private__ bundle_name /foobar
/foobar
% antidote __private__ bundle_name foobar/
foobar/
% antidote __private__ bundle_name '~/foo/bar'
$HOME/foo/bar
% antidote __private__ bundle_name '$foo/bar'
$foo/bar
% antidote __private__ bundle_name foo/bar
foo/bar
% antidote __private__ bundle_name bar/baz.git
bar/baz.git
% antidote __private__ bundle_name foo/bar/baz
foo/bar/baz
% antidote __private__ bundle_name foobar
foobar
% antidote __private__ bundle_name foo bar baz
foo
% antidote __private__ bundle_name 'foo bar baz'
foo bar baz
%
```

## Bundle dir

```zsh
% zstyle ':antidote:bundle' path-style escaped
% # short repo
% antidote __private__ bundle_dir foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
% # repo url
% antidote __private__ bundle_dir https://fakegitsite.com/foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
% # repo url.git
% antidote __private__ bundle_dir https://fakegitsite.com/foo/bar.git | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-fakegitsite.com-SLASH-foo-SLASH-bar
% # repo ssh
% antidote __private__ bundle_dir git@fakegitsite.com:foo/bar.git | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/git-AT-fakegitsite.com-COLON-foo-SLASH-bar
% # local dir
% antidote __private__ bundle_dir ~/foo/bar | subenv HOME
$HOME/foo/bar
% # another local dir
% antidote __private__ bundle_dir $ZDOTDIR/bar/baz | subenv ZDOTDIR
$ZDOTDIR/bar/baz
% zstyle -d ':antidote:bundle' path-style
%
```

Use short names

```zsh
% # short repo - friendly name
% zstyle ':antidote:bundle' path-style short
% antidote __private__ bundle_dir foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/bar
% # repo url - friendly name
% antidote __private__ bundle_dir https://fakegitsite.com/bar/baz | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/bar/baz
% # ssh repo - friendly name
% antidote __private__ bundle_dir git@fakegitsite.com:foo/qux.git | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/qux
% zstyle -d ':antidote:bundle' path-style
%
```

Use full names

```zsh
% zstyle ':antidote:bundle' path-style full
% antidote __private__ bundle_dir foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/foo/bar
% antidote __private__ bundle_dir https://fakegitsite.com/bar/baz | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/bar/baz
% antidote __private__ bundle_dir git@fakegitsite.com:foo/qux.git | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/foo/qux
% zstyle -d ':antidote:bundle' path-style
%
```

Legacy: Use friendly names

```zsh
% # short repos style used to be called "use friendly names"
% zstyle -d ':antidote:bundle' path-style
% zstyle ':antidote:bundle' use-friendly-names on
% antidote __private__ bundle_dir foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/bar
% # repo url - friendly name
% antidote __private__ bundle_dir https://fakegitsite.com/bar/baz | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/bar/baz
% # ssh repo - friendly name
% antidote __private__ bundle_dir git@fakegitsite.com:foo/qux.git | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/qux
% zstyle -d ':antidote:bundle' use-friendly-names
%
```

### To URL

Short repos:

```zsh
% antidote __private__ tourl ohmyzsh/ohmyzsh
https://fakegitsite.com/ohmyzsh/ohmyzsh
% antidote __private__ tourl sindresorhus/pure
https://fakegitsite.com/sindresorhus/pure
% antidote __private__ tourl foo/bar
https://fakegitsite.com/foo/bar
%
```

Proper URLs don't change:

```zsh
% antidote __private__ tourl https://github.com/ohmyzsh/ohmyzsh
https://github.com/ohmyzsh/ohmyzsh
% antidote __private__ tourl http://github.com/ohmyzsh/ohmyzsh
http://github.com/ohmyzsh/ohmyzsh
% antidote __private__ tourl ssh://github.com/ohmyzsh/ohmyzsh
ssh://github.com/ohmyzsh/ohmyzsh
% antidote __private__ tourl git://github.com/ohmyzsh/ohmyzsh
git://github.com/ohmyzsh/ohmyzsh
% antidote __private__ tourl ftp://github.com/ohmyzsh/ohmyzsh
ftp://github.com/ohmyzsh/ohmyzsh
% antidote __private__ tourl git@github.com:sindresorhus/pure.git
git@github.com:sindresorhus/pure.git
%
```

## Teardown

```zsh
% t_teardown
%
```

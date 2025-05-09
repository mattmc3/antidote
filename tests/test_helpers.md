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
% __antidote_del -rf -- /foo/bar
antidote: Blocked attempt to rm path: '/foo/bar'.
%
```

## Pretty print path

```zsh
% __antidote_print_path /foo/bar
/foo/bar
% __antidote_print_path $HOME/foo/bar
$HOME/foo/bar
% zstyle ':antidote:compatibility-mode' 'antibody' 'on'
% __antidote_print_path $HOME/foo/bar | subenv T_TEMPDIR
$T_TEMPDIR/foo/bar
% zstyle -d ':antidote:compatibility-mode' 'antibody'
%
```

## Bundle type

```zsh
% __antidote_bundle_type $T_PRJDIR/antidote.zsh
file
% __antidote_bundle_type $T_PRJDIR/functions
dir
% __antidote_bundle_type '$T_PRJDIR/antidote.zsh'
file
% __antidote_bundle_type \$T_PRJDIR/functions
dir
% __antidote_bundle_type 'git@github.com:foo/bar.git'
sshurl
% __antidote_bundle_type 'https://github.com/foo/bar'
url
% __antidote_bundle_type 'https:/bad.com/foo/bar.git'
?
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
% __antidote_bundle_type \$ZDOTDIR/foo
path
% __antidote_bundle_type \$ZDOTDIR/.zsh_plugins.txt
file
% touch ~/.zshenv
% __antidote_bundle_type '~/.zshenv'
file
% __antidote_bundle_type '~/null'
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

## Bundle name

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

## Bundle dir

```zsh
% zstyle ':antidote:bundle' use-friendly-names off
% # short repo
% __antidote_bundle_dir foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar
% # repo url
% __antidote_bundle_dir https://github.com/foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar
% # repo url.git
% __antidote_bundle_dir https://github.com/foo/bar.git | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar
% # repo ssh
% __antidote_bundle_dir git@github.com:foo/bar.git | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/git-AT-github.com-COLON-foo-SLASH-bar
% # local dir
% __antidote_bundle_dir ~/foo/bar | subenv HOME
$HOME/foo/bar
% # another local dir
% __antidote_bundle_dir $ZDOTDIR/bar/baz | subenv ZDOTDIR
$ZDOTDIR/bar/baz
%
```

Use friendly names

```zsh
% # short repo - friendly name
% zstyle ':antidote:bundle' use-friendly-names on
% __antidote_bundle_dir foo/bar | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/bar
% # repo url - friendly name
% __antidote_bundle_dir https://github.com/bar/baz | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/bar/baz
% # ssh repo - friendly name
% __antidote_bundle_dir git@github.com:foo/qux.git | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/foo/qux
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

## Collect input

If we \<redirect input it should output that.

```zsh
% __antidote_collect_input <$ZDOTDIR/.zsh_plugins.txt #=> --file tmp_home/.zsh/.zsh_plugins.txt
%
```

If we \|pipe input it should output that.

```zsh
% cat $ZDOTDIR/.zsh_plugins.txt | __antidote_collect_input #=> --file tmp_home/.zsh/.zsh_plugins.txt
%
```

If we pass argument it should output that.

```zsh
% __antidote_collect_input 'a\nb\nc\n'
a
b
c

%
```

## Teardown

```zsh
% t_teardown
%
```

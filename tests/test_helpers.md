# antidote helper tests

## Setup

```zsh
% source ./tests/_setup.zsh
% source $T_PRJDIR/antidote.zsh
% antidote-bundle -h &>/dev/null  # force lazy-loading to not be lazy
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
% __antidote_scrub_home /foo/bar
/foo/bar
% __antidote_scrub_home $HOME/foo/bar
$HOME/foo/bar
% __antidote_scrub_home '~/foo/bar'
$HOME/foo/bar
% __antidote_scrub_home '~foo'
~foo
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
%

## More Bundle type checks

```zsh
% __antidote_bundle_type foobar
word
% __antidote_bundle_type foo bar baz
word
% __antidote_bundle_type 'foo bar baz'
word
%
```

## Bundle repo

```zsh
% __antidote_bundle_repo 'git@github.com:foo/bar.git'
foo/bar
% __antidote_bundle_repo 'https://github.com/foo/bar'
foo/bar
% __antidote_bundle_repo foo/bar
foo/bar
% __antidote_bundle_repo bar/baz.git
bar/baz.git
%
```

Non-repos

```zsh
% __antidote_bundle_repo $HOME/.zsh/custom/lib/lib1.zsh #=> --exit 1
% __antidote_bundle_repo $HOME/.zsh/plugins/myplugin #=> --exit 1
% __antidote_bundle_repo 'https:/bad.com/foo/bar.git' #=> --exit 1
% __antidote_bundle_repo '' #=> --exit 1
% __antidote_bundle_repo /foo/bar #=> --exit 1
% __antidote_bundle_repo /foobar #=> --exit 1
% __antidote_bundle_repo foobar/ #=> --exit 1
% __antidote_bundle_repo '~/foo/bar' #=> --exit 1
% __antidote_bundle_repo '$foo/bar' #=> --exit 1
% __antidote_bundle_repo foo/bar/baz #=> --exit 1
% __antidote_bundle_repo foobar #=> --exit 1
% __antidote_bundle_repo foo bar baz #=> --exit 1
% __antidote_bundle_repo 'foo bar baz' #=> --exit 1
%
```

## Bundle dir

```zsh
% zstyle ':antidote:compatibility-mode' 'antibody' 'on'
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
% zstyle ':antidote:compatibility-mode' 'antibody' 'off'
%
```

Use friendly names

```zsh
% # short repo - friendly name
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
% __antidote_bundle_url ohmyzsh/ohmyzsh
https://github.com/ohmyzsh/ohmyzsh
% __antidote_bundle_url sindresorhus/pure
https://github.com/sindresorhus/pure
% __antidote_bundle_url foo/bar
https://github.com/foo/bar
%
```

Proper URLs don't change:

```zsh
% __antidote_bundle_url https://github.com/ohmyzsh/ohmyzsh
https://github.com/ohmyzsh/ohmyzsh
% __antidote_bundle_url http://github.com/ohmyzsh/ohmyzsh
http://github.com/ohmyzsh/ohmyzsh
% __antidote_bundle_url ssh://github.com/ohmyzsh/ohmyzsh
ssh://github.com/ohmyzsh/ohmyzsh
% __antidote_bundle_url git://github.com/ohmyzsh/ohmyzsh
git://github.com/ohmyzsh/ohmyzsh
% __antidote_bundle_url ftp://github.com/ohmyzsh/ohmyzsh
ftp://github.com/ohmyzsh/ohmyzsh
% __antidote_bundle_url git@github.com:sindresorhus/pure.git
git@github.com:sindresorhus/pure.git
%
```

## Teardown

```zsh
% t_teardown
%
```

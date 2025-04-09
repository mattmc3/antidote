# antidote helper tests

## Setup

```zsh
% source ./tests/_setup.zsh
% source $PRJDIR/antidote.zsh
% antidote-bundle -h &>/dev/null  # force lazy-loading to not be lazy
%
```

## Bulk clone missing repos

Parse a bundle file to find a list of all missing repos so that we can clone them
in parallel.

```zsh
% __antidote_bulk_clone < $TESTDATA/.zsh_plugins_repos.txt
__antidote_legacy_scripter --kind clone --branch baz foobar/foobar &
__antidote_legacy_scripter --kind clone bar/baz &
__antidote_legacy_scripter --kind clone getantidote/zsh-defer &
__antidote_legacy_scripter --kind clone git@github.com:user/repo &
__antidote_legacy_scripter --kind clone http://github.com/user/repo.git &
__antidote_legacy_scripter --kind clone https://github.com/foo/baz &
__antidote_legacy_scripter --kind clone https://github.com/foo/qux &
__antidote_legacy_scripter --kind clone https://github.com/user/repo &
__antidote_legacy_scripter --kind clone user/repo &
wait
%
```

Test empty

```zsh
% __antidote_bulk_clone < $TESTDATA/.zsh_plugins_empty.txt
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
% __antidote_bundle_type $PRJDIR/antidote.zsh
file
% __antidote_bundle_type $PRJDIR/functions
dir
% __antidote_bundle_type '$PRJDIR/antidote.zsh'
file
% __antidote_bundle_type \$PRJDIR/functions
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
% pushd > /dev/null
% cd $HOME  # just in case there are stray foo files
% __antidote_bundle_type foobar
word
% __antidote_bundle_type foo bar baz
word
% __antidote_bundle_type 'foo bar baz'
word
% popd > /dev/null
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

## Clone command

Basic usage:

```zsh
% __antidote_clone_cmd foo/bar $ANTIDOTE_HOME/foo/bar | subenv ANTIDOTE_HOME
print -ru2 -- '# antidote cloning foo/bar...'
git clone --quiet --recurse-submodules --shallow-submodules foo/bar $ANTIDOTE_HOME/foo/bar &
%
```

Clone a branch:

```zsh
% __antidote_clone_cmd bar/baz $ANTIDOTE_HOME/bar/baz foo | subenv ANTIDOTE_HOME
print -ru2 -- '# antidote cloning bar/baz...'
git clone --quiet --recurse-submodules --shallow-submodules --branch foo bar/baz $ANTIDOTE_HOME/bar/baz &
%
```

Funky strings get escaped:

```zsh
% __antidote_clone_cmd foo/bar "$ANTIDOTE_HOME/foo bar" "baz's:qux" | subenv ANTIDOTE_HOME
print -ru2 -- '# antidote cloning foo/bar...'
git clone --quiet --recurse-submodules --shallow-submodules --branch baz\'s:qux foo/bar $ANTIDOTE_HOME/foo\ bar &
%
```

Test background flag:

```zsh
% __antidote_clone_cmd a b c 1
print -ru2 -- '# antidote cloning a...'
git clone --quiet --recurse-submodules --shallow-submodules --branch c a b &
% __antidote_clone_cmd a b c 0
print -ru2 -- '# antidote cloning a...'
git clone --quiet --recurse-submodules --shallow-submodules --branch c a b
%
```

Other checks:

```zsh
% __antidote_clone_cmd a b c
print -ru2 -- '# antidote cloning a...'
git clone --quiet --recurse-submodules --shallow-submodules --branch c a b &
% clone_cmd_array=( ${(@f)"$(__antidote_clone_cmd mygiturl mydir mybranch 2>&1)"} )
% echo ${#clone_cmd_array}
2
% print -l -- $clone_cmd_array
print -ru2 -- '# antidote cloning mygiturl...'
git clone --quiet --recurse-submodules --shallow-submodules --branch mybranch mygiturl mydir &
%
```

## Teardown

```zsh
% t_teardown
%
```

# antidote helper tests

## Setup

```zsh
% source ./tests/_setup.zsh
% source $T_PRJDIR/antidote.zsh
% antidote-bundle -h &>/dev/null  # force lazy-loading to not be lazy
%
```

## Bulk clone missing repos

Parse a bundle file to find a list of all missing repos so that we can clone them
in parallel.

```zsh
% __antidote_parse_bundles < $T_TESTDATA/.zsh_plugins_repos.txt | normalize_assoc_arr | subenv ANTIDOTE_HOME HOME
typeset -A parsed_bundle=( [_dir]=$ANTIDOTE_HOME/user/repo [_repo]=user/repo [_type]=repo [_url]=https://github.com/user/repo [name]=user/repo )
typeset -A parsed_bundle=( [_dir]=$ANTIDOTE_HOME/user/repo [_repo]=user/repo [_type]=url [_url]=https://github.com/user/repo [name]=https://github.com/user/repo )
typeset -A parsed_bundle=( [_dir]=$ANTIDOTE_HOME/user/repo [_repo]=user/repo [_type]=url [_url]=http://github.com/user/repo.git [name]=http://github.com/user/repo.git )
typeset -A parsed_bundle=( [_dir]=$ANTIDOTE_HOME/user/repo [_repo]=user/repo [_type]=url [_url]=https://github.com/user/repo [name]=https://github.com/user/repo )
typeset -A parsed_bundle=( [_dir]=$ANTIDOTE_HOME/user/repo [_repo]=user/repo [_type]=sshurl [_url]=git@github.com:user/repo [name]=git@github.com:user/repo )
typeset -A parsed_bundle=( [_dir]=$ANTIDOTE_HOME/bar/baz [_repo]=bar/baz [_type]=repo [_url]=https://github.com/bar/baz [name]=bar/baz [path]=plugins/qux )
typeset -A parsed_bundle=( [_dir]=$ANTIDOTE_HOME/bar/baz [_repo]=bar/baz [_type]=repo [_url]=https://github.com/bar/baz [name]=bar/baz [path]=themes/qux.zsh-theme )
typeset -A parsed_bundle=( [_dir]=$ANTIDOTE_HOME/foobar/foobar [_repo]=foobar/foobar [_type]=repo [_url]=https://github.com/foobar/foobar [branch]=baz [name]=foobar/foobar )
typeset -A parsed_bundle=( [_dir]=$ANTIDOTE_HOME/foo/qux [_repo]=foo/qux [_type]=url [_url]=https://github.com/foo/qux [kind]=defer [name]=https://github.com/foo/qux )
typeset -A parsed_bundle=( [_dir]=$ANTIDOTE_HOME/foo/baz [_repo]=foo/baz [_type]=url [_url]=https://github.com/foo/baz [kind]=defer [name]=https://github.com/foo/baz )
typeset -A parsed_bundle=( [_dir]=foo [_type]=word [name]=foo )
typeset -A parsed_bundle=( [_dir]=$HOME/.zplugins/bar [_type]=path [name]='~/.zplugins/bar' )
typeset -A parsed_bundle=( [_dir]='$ZDOTDIR/plugins/bar' [_type]=path [name]='$ZDOTDIR/plugins/bar' )
typeset -A parsed_bundle=( [_dir]=$ANTIDOTE_HOME/user/repo [_repo]=user/repo [_type]=repo [_url]=https://github.com/user/repo [name]=user/repo )
typeset -A parsed_bundle=( [_dir]=$ANTIDOTE_HOME/user/repo [_repo]=user/repo [_type]=url [_url]=https://github.com/user/repo [name]=https://github.com/user/repo )
%
```

```zsh
% __antidote_cloner < $T_TESTDATA/.zsh_plugins_repos.txt | subenv ANTIDOTE_HOME
() {
  emulate -L zsh; setopt local_options no_monitor pipefail
  print -ru2 -- '# antidote cloning user/repo...'
  git clone --quiet --recurse-submodules --shallow-submodules https://github.com/user/repo $ANTIDOTE_HOME/user/repo &
  print -ru2 -- '# antidote cloning bar/baz...'
  git clone --quiet --recurse-submodules --shallow-submodules https://github.com/bar/baz $ANTIDOTE_HOME/bar/baz &
  print -ru2 -- '# antidote cloning foobar/foobar...'
  git clone --quiet --recurse-submodules --shallow-submodules --branch baz https://github.com/foobar/foobar $ANTIDOTE_HOME/foobar/foobar &
}
wait
%
```

  print -ru2 -- '# antidote cloning romkatv/zsh-defer...'
  git clone --quiet --recurse-submodules --shallow-submodules https://github.com/romkatv/zsh-defer $ANTIDOTE_HOME/romkatv/zsh-defer &
  print -ru2 -- '# antidote cloning foo/qux...'
  git clone --quiet --recurse-submodules --shallow-submodules https://github.com/foo/qux $ANTIDOTE_HOME/foo/qux &
  print -ru2 -- '# antidote cloning foo/baz...'
  git clone --quiet --recurse-submodules --shallow-submodules https://github.com/foo/baz $ANTIDOTE_HOME/foo/baz &

antidote-script --kind clone --branch baz foobar/foobar &
antidote-script --kind clone bar/baz &
antidote-script --kind clone getantidote/zsh-defer &
antidote-script --kind clone git@github.com:user/repo &
antidote-script --kind clone http://github.com/user/repo.git &
antidote-script --kind clone https://github.com/foo/baz &
antidote-script --kind clone https://github.com/foo/qux &
antidote-script --kind clone https://github.com/user/repo &
antidote-script --kind clone user/repo &

Test empty

```zsh
% __antidote_cloner < $T_TESTDATA/.zsh_plugins_empty.txt
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

## Clone command

Basic usage:

```zsh
% __antidote_clone_cmd foo/bar https://fakegitsite.com/foo/bar $ANTIDOTE_HOME/foo/bar | subenv ANTIDOTE_HOME
print -ru2 -- '# antidote cloning foo/bar...'
git clone --quiet --recurse-submodules --shallow-submodules https://fakegitsite.com/foo/bar $ANTIDOTE_HOME/foo/bar &
%
```

Clone a branch:

```zsh
% __antidote_clone_cmd bar/baz https://fakegitsite.com/bar/baz $ANTIDOTE_HOME/bar/baz foo | subenv ANTIDOTE_HOME
print -ru2 -- '# antidote cloning bar/baz...'
git clone --quiet --recurse-submodules --shallow-submodules --branch foo https://fakegitsite.com/bar/baz $ANTIDOTE_HOME/bar/baz &
%
```

Funky strings get escaped:

```zsh
% __antidote_clone_cmd foo/bar https://git.com/a/b "$ANTIDOTE_HOME/foo bar" "baz's:qux" | subenv ANTIDOTE_HOME
print -ru2 -- '# antidote cloning foo/bar...'
git clone --quiet --recurse-submodules --shallow-submodules --branch baz\'s:qux https://git.com/a/b $ANTIDOTE_HOME/foo\ bar &
%
```

Test background flag:

```zsh
% __antidote_clone_cmd a https://git.com/b c d 1
print -ru2 -- '# antidote cloning a...'
git clone --quiet --recurse-submodules --shallow-submodules --branch d https://git.com/b c &
% __antidote_clone_cmd a https://git.com/b c d 0
print -ru2 -- '# antidote cloning a...'
git clone --quiet --recurse-submodules --shallow-submodules --branch d https://git.com/b c
%
```

Other checks:

```zsh
% __antidote_clone_cmd a https://git.com/b c d
print -ru2 -- '# antidote cloning a...'
git clone --quiet --recurse-submodules --shallow-submodules --branch d https://git.com/b c &
% clone_cmd_array=( ${(@f)"$(__antidote_clone_cmd repo https://mygiturl.com mydir mybranch 2>&1)"} )
% echo ${#clone_cmd_array}
2
% print -l -- $clone_cmd_array
print -ru2 -- '# antidote cloning repo...'
git clone --quiet --recurse-submodules --shallow-submodules --branch mybranch https://mygiturl.com mydir &
%
```

## Teardown

```zsh
% t_teardown
%
```

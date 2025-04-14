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
typeset -A bundle=( [_plugin]='$ANTIDOTE_HOME/user/repo' [_repo]=user/repo [_repodir]='$ANTIDOTE_HOME/user/repo' [_type]=repo [_url]=https://github.com/user/repo [name]=user/repo )
typeset -A bundle=( [_plugin]='$ANTIDOTE_HOME/user/repo' [_repo]=user/repo [_repodir]='$ANTIDOTE_HOME/user/repo' [_type]=url [_url]=https://github.com/user/repo [name]=https://github.com/user/repo )
typeset -A bundle=( [_plugin]='$ANTIDOTE_HOME/user/repo' [_repo]=user/repo [_repodir]='$ANTIDOTE_HOME/user/repo' [_type]=url [_url]=http://github.com/user/repo.git [name]=http://github.com/user/repo.git )
typeset -A bundle=( [_plugin]='$ANTIDOTE_HOME/user/repo' [_repo]=user/repo [_repodir]='$ANTIDOTE_HOME/user/repo' [_type]=url [_url]=https://github.com/user/repo [name]=https://github.com/user/repo )
typeset -A bundle=( [_plugin]='$ANTIDOTE_HOME/user/repo' [_repo]=user/repo [_repodir]='$ANTIDOTE_HOME/user/repo' [_type]=url [_url]=git@github.com:user/repo [name]=git@github.com:user/repo )
typeset -A bundle=( [_plugin]='$ANTIDOTE_HOME/bar/baz/plugins/qux' [_repo]=bar/baz [_repodir]='$ANTIDOTE_HOME/bar/baz' [_type]=repo [_url]=https://github.com/bar/baz [name]=bar/baz [path]=plugins/qux )
typeset -A bundle=( [_plugin]='$ANTIDOTE_HOME/bar/baz/themes/qux.zsh-theme' [_repo]=bar/baz [_repodir]='$ANTIDOTE_HOME/bar/baz' [_type]=repo [_url]=https://github.com/bar/baz [name]=bar/baz [path]=themes/qux.zsh-theme )
typeset -A bundle=( [_plugin]='$ANTIDOTE_HOME/foobar/foobar' [_repo]=foobar/foobar [_repodir]='$ANTIDOTE_HOME/foobar/foobar' [_type]=repo [_url]=https://github.com/foobar/foobar [branch]=baz [name]=foobar/foobar )
typeset -A bundle=( [_plugin]='$ANTIDOTE_HOME/foo/qux' [_repo]=foo/qux [_repodir]='$ANTIDOTE_HOME/foo/qux' [_type]=url [_url]=https://github.com/foo/qux [kind]=defer [name]=https://github.com/foo/qux )
typeset -A bundle=( [_plugin]='$ANTIDOTE_HOME/foo/baz' [_repo]=foo/baz [_repodir]='$ANTIDOTE_HOME/foo/baz' [_type]=url [_url]=https://github.com/foo/baz [kind]=defer [name]=https://github.com/foo/baz )
typeset -A bundle=( [_type]='?' [name]=foo )
typeset -A bundle=( [_plugin]='$HOME/.zplugins/bar' [_type]=path [name]='~/.zplugins/bar' )
typeset -A bundle=( [_plugin]='$ZDOTDIR/plugins/bar' [_type]=path [name]='$ZDOTDIR/plugins/bar' )
typeset -A bundle=( [_plugin]='$ANTIDOTE_HOME/user/repo' [_repo]=user/repo [_repodir]='$ANTIDOTE_HOME/user/repo' [_type]=repo [_url]=https://github.com/user/repo [name]=user/repo )
typeset -A bundle=( [_plugin]='$ANTIDOTE_HOME/user/repo' [_repo]=user/repo [_repodir]='$ANTIDOTE_HOME/user/repo' [_type]=url [_url]=https://github.com/user/repo [name]=https://github.com/user/repo )
%
```

```zsh
% __antidote_cloner < $T_TESTDATA/.zsh_plugins_repos.txt | subenv HOME
() {
  emulate -L zsh; setopt local_options no_monitor pipefail
  local ANTIDOTE_HOME="$HOME/.cache/antidote"
  print -ru2 -- '# antidote cloning user/repo...'
  git clone --quiet --recurse-submodules --shallow-submodules https://github.com/user/repo "$ANTIDOTE_HOME/user/repo" &
  print -ru2 -- '# antidote cloning bar/baz...'
  git clone --quiet --recurse-submodules --shallow-submodules https://github.com/bar/baz "$ANTIDOTE_HOME/bar/baz" &
  print -ru2 -- '# antidote cloning foobar/foobar...'
  git clone --quiet --recurse-submodules --shallow-submodules --branch baz https://github.com/foobar/foobar "$ANTIDOTE_HOME/foobar/foobar" &
  print -ru2 -- '# antidote cloning getantidote/zsh-defer...'
  git clone --quiet --recurse-submodules --shallow-submodules https://github.com/getantidote/zsh-defer "$ANTIDOTE_HOME/getantidote/zsh-defer" &
  print -ru2 -- '# antidote cloning foo/qux...'
  git clone --quiet --recurse-submodules --shallow-submodules https://github.com/foo/qux "$ANTIDOTE_HOME/foo/qux" &
  print -ru2 -- '# antidote cloning foo/baz...'
  git clone --quiet --recurse-submodules --shallow-submodules https://github.com/foo/baz "$ANTIDOTE_HOME/foo/baz" &
}
wait
%
```

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

## Clone command

Basic usage:

```zsh
% __antidote_clone_cmd foo/bar https://fakegitsite.com/foo/bar $ANTIDOTE_HOME/foo/bar | subenv ANTIDOTE_HOME
print -ru2 -- '# antidote cloning foo/bar...'
git clone --quiet --recurse-submodules --shallow-submodules https://fakegitsite.com/foo/bar "$ANTIDOTE_HOME/foo/bar" &
%
```

Clone a branch:

```zsh
% __antidote_clone_cmd bar/baz https://fakegitsite.com/bar/baz $ANTIDOTE_HOME/bar/baz foo | subenv ANTIDOTE_HOME
print -ru2 -- '# antidote cloning bar/baz...'
git clone --quiet --recurse-submodules --shallow-submodules --branch foo https://fakegitsite.com/bar/baz "$ANTIDOTE_HOME/bar/baz" &
%
```

Funky strings get escaped:

```zsh
% __antidote_clone_cmd foo/bar https://git.com/a/b "$ANTIDOTE_HOME/foo bar" "baz's:qux" | subenv ANTIDOTE_HOME
print -ru2 -- '# antidote cloning foo/bar...'
git clone --quiet --recurse-submodules --shallow-submodules --branch baz\'s:qux https://git.com/a/b "$ANTIDOTE_HOME/foo bar" &
%
```

Test background flag:

```zsh
% __antidote_clone_cmd a https://git.com/b c d 1
print -ru2 -- '# antidote cloning a...'
git clone --quiet --recurse-submodules --shallow-submodules --branch d https://git.com/b "c" &
% __antidote_clone_cmd a https://git.com/b c d 0
print -ru2 -- '# antidote cloning a...'
git clone --quiet --recurse-submodules --shallow-submodules --branch d https://git.com/b "c"
%
```

Other checks:

```zsh
% __antidote_clone_cmd a https://git.com/b c d
print -ru2 -- '# antidote cloning a...'
git clone --quiet --recurse-submodules --shallow-submodules --branch d https://git.com/b "c" &
% clone_cmd_array=( ${(@f)"$(__antidote_clone_cmd repo https://mygiturl.com mydir mybranch 2>&1)"} )
% echo ${#clone_cmd_array}
2
% print -l -- $clone_cmd_array
print -ru2 -- '# antidote cloning repo...'
git clone --quiet --recurse-submodules --shallow-submodules --branch mybranch https://mygiturl.com "mydir" &
%
```

## Teardown

```zsh
% t_teardown
%
```

# test antibody compat scripter

## Setup

```zsh
% source ./tests/_setup.zsh
% source $PRJDIR/antidote.zsh
% zstyle ':antidote:compatibility-mode' 'antibody' 'on'
% ANTIDOTE_HOME=$HOME/.cache/antibody
%
```

## Script Command

### Fails

```zsh
% __antidote_compat_antibody_scripter  #=> --exit 1
%
```

### Scripting types

`__antidote_compat_antibody_scripter` works with local files and directories, as well as remote repos.

Script a file:

```zsh
% __antidote_compat_antibody_scripter $ZDOTDIR/aliases.zsh | subenv ZDOTDIR
source $ZDOTDIR/aliases.zsh
%
```

Script a lib directory:

```zsh
% __antidote_compat_antibody_scripter $ZDOTDIR/custom/lib | subenv ZDOTDIR
fpath+=( $ZDOTDIR/custom/lib )
source $ZDOTDIR/custom/lib/lib1.zsh
source $ZDOTDIR/custom/lib/lib2.zsh
%
```

Script a plugin directory:

```zsh
% __antidote_compat_antibody_scripter $ZDOTDIR/custom/plugins/myplugin | subenv ZDOTDIR
fpath+=( $ZDOTDIR/custom/plugins/myplugin )
source $ZDOTDIR/custom/plugins/myplugin/myplugin.plugin.zsh
%
```

Script repos in antibody style:

```zsh
% __antidote_compat_antibody_scripter foo/bar                        | subenv ANTIDOTE_HOME  #=> --file ./testdata/antibody/script-foobar.zsh
% __antidote_compat_antibody_scripter https://github.com/foo/bar     | subenv ANTIDOTE_HOME  #=> --file ./testdata/antibody/script-foobar.zsh
% __antidote_compat_antibody_scripter https://github.com/foo/bar.git | subenv ANTIDOTE_HOME  #=> --file ./testdata/antibody/script-foobar.zsh
% __antidote_compat_antibody_scripter git@github.com:foo/qux.git     | subenv ANTIDOTE_HOME  #=> --file ./testdata/antibody/script-fooqux.zsh
%
```

## Annotations

### kind:clone

Nothing happens when the plugin already exists.

```zsh
% __antidote_compat_antibody_scripter --kind clone foo/bar
%
```

Clone a missing plugin.

Remember: antibody didn't actually print anything when cloning, so we won't see
"# antidote cloning fakeuser/fakerepo..."

```zsh
% __antidote_compat_antibody_scripter --kind clone https://fakegitsite.com/fakeuser/fakerepo
% # antidote cloning fakeuser/fakerepo...
%
```

### kind:zsh

```zsh
% __antidote_compat_antibody_scripter --kind zsh foo/bar | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar/bar.plugin.zsh
%
```

### kind:path

```zsh
% __antidote_compat_antibody_scripter --kind path foo/bar | subenv ANTIDOTE_HOME
export PATH="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar:$PATH"
%
```

### kind:fpath

```zsh
% __antidote_compat_antibody_scripter --kind fpath foo/bar | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar )
%
```

### path:plugin-dir

```zsh
% __antidote_compat_antibody_scripter --path plugins/extract ohmy/ohmy | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/extract )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/extract/extract.plugin.zsh
%
```

### path:file

```zsh
% __antidote_compat_antibody_scripter --path lib/lib1.zsh ohmy/ohmy | subenv ANTIDOTE_HOME
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib/lib1.zsh
%
```

### path:lib-dir

```zsh
% __antidote_compat_antibody_scripter --path lib ohmy/ohmy | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib/lib1.zsh
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib/lib2.zsh
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib/lib3.zsh
%
```

### path:theme

```zsh
% __antidote_compat_antibody_scripter --path themes/pretty.zsh-theme ohmy/ohmy | subenv ANTIDOTE_HOME
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/themes/pretty.zsh-theme
%
```

## Private functions

### __antidote_initfiles

setup

```zsh
% # load __antidote_initfiles from private funcs in __antidote_compat_antibody_scripter
% __antidote_compat_antibody_scripter -h &>/dev/null
% PLUGINDIR=$T_TEMPDIR/initfiles/myplugin
% mkdir -p $PLUGINDIR
% touch $PLUGINDIR/myplugin.plugin.zsh
% touch $PLUGINDIR/whatever.plugin.zsh
% touch $PLUGINDIR/file.zsh
% touch $PLUGINDIR/file.sh
% touch $PLUGINDIR/file.bash
% touch $PLUGINDIR/mytheme.zsh-theme
% touch $PLUGINDIR/README.md
% touch $PLUGINDIR/file
% mkdir -p $PLUGINDIR/lib
% touch $PLUGINDIR/lib/lib1.zsh
% touch $PLUGINDIR/lib/lib2.zsh
% touch $PLUGINDIR/lib/lib3.zsh
%
```

myplugin.plugin.zsh

```zsh
% __antidote_initfiles $PLUGINDIR | subenv PLUGINDIR
$PLUGINDIR/myplugin.plugin.zsh
% rm $PLUGINDIR/myplugin.plugin.zsh
%
```

whatever.plugin.zsh

```zsh
% __antidote_initfiles $PLUGINDIR | subenv PLUGINDIR
$PLUGINDIR/whatever.plugin.zsh
% rm $PLUGINDIR/whatever.plugin.zsh
%
```

file.zsh

```zsh
% __antidote_initfiles $PLUGINDIR | subenv PLUGINDIR
$PLUGINDIR/file.zsh
% rm $PLUGINDIR/file.zsh
%
```

file.sh

```zsh
% __antidote_initfiles $PLUGINDIR | subenv PLUGINDIR
$PLUGINDIR/file.sh
% rm $PLUGINDIR/file.sh
%
```

mytheme.zsh-theme

```zsh
% __antidote_initfiles $PLUGINDIR | subenv PLUGINDIR
$PLUGINDIR/mytheme.zsh-theme
% rm $PLUGINDIR/mytheme.zsh-theme
%
```

lib

```zsh
% __antidote_initfiles $PLUGINDIR/lib | subenv PLUGINDIR
$PLUGINDIR/lib/lib1.zsh
$PLUGINDIR/lib/lib2.zsh
$PLUGINDIR/lib/lib3.zsh
%
```

FAIL: no files left that match

```zsh
% __antidote_initfiles $PLUGINDIR  #=> --exit 1
%
```

FAIL: Empty

```zsh
% PLUGINDIR=$T_TEMPDIR/initfiles/foo
% mkdir -p $PLUGINDIR
% __antidote_initfiles $PLUGINDIR  #=> --exit 1
%
```

## Test helpers that use antibody compat mode

## Bundle dir

```zsh
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

## Teardown

```zsh
% t_teardown
%
```

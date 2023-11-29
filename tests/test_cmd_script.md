# antidote-script tests

## Setup

```zsh
% source ./tests/_setup.zsh
% source ./antidote.zsh
%
```

## Script Command

### Fails

```zsh
% antidote-script  #=> --exit 1
antidote: error: bundle argument expected
%
```

### Arg style

`antidote-script` accepts '--arg val', '--arg:val', '--arg=val' syntax

```zsh
% antidote-script --kind zsh foo/bar  #=> --exit 0
% antidote-script --kind:zsh foo/bar  #=> --exit 0
% antidote-script --kind=zsh foo/bar  #=> --exit 0
% antidote-script --kind+zsh foo/bar  #=> --exit 1
%
```

### Scripting types

`antidote-script` works with local files and directories, as well as remote repos.

Script a file:

```zsh
% antidote-script $ZDOTDIR/aliases.zsh | subenv ZDOTDIR
source $ZDOTDIR/aliases.zsh
%
```

Script a lib directory:

```zsh
% antidote-script $ZDOTDIR/custom/lib | subenv ZDOTDIR
fpath+=( $ZDOTDIR/custom/lib )
source $ZDOTDIR/custom/lib/lib1.zsh
source $ZDOTDIR/custom/lib/lib2.zsh
%
```

Script a plugin directory:

```zsh
% antidote-script $ZDOTDIR/custom/plugins/myplugin | subenv ZDOTDIR
fpath+=( $ZDOTDIR/custom/plugins/myplugin )
source $ZDOTDIR/custom/plugins/myplugin/myplugin.plugin.zsh
%
```

Script repos:

```zsh
% antidote-script foo/bar                        | subenv ANTIDOTE_HOME  #=> --file ./testdata/script-foobar.zsh
% antidote-script https://github.com/foo/bar     | subenv ANTIDOTE_HOME  #=> --file ./testdata/script-foobar.zsh
% antidote-script https://github.com/foo/bar.git | subenv ANTIDOTE_HOME  #=> --file ./testdata/script-foobar.zsh
% antidote-script git@github.com:baz/qux.git     | subenv ANTIDOTE_HOME  #=> --file ./testdata/script-bazqux.zsh
```

## Annotations

### kind:clone

Nothing happens when the plugin already exists.

```zsh
% antidote-script --kind clone foo/bar
%
```

Clone a missing plugin.

```zsh
% antidote-script --kind clone bar/foo
# antidote cloning bar/foo...
%
```

### kind:zsh

```zsh
% antidote-script --kind zsh foo/bar | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar/bar.plugin.zsh
%
```

### kind:path

```zsh
% antidote-script --kind path foo/bar | subenv ANTIDOTE_HOME
export PATH="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar:$PATH"
%
```

### kind:fpath

```zsh
% antidote-script --kind fpath foo/bar | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar )
%
```

### kind:autoload

```zsh
% antidote-script --kind autoload $ZDOTDIR/functions | subenv ZDOTDIR
fpath+=( $ZDOTDIR/functions )
builtin autoload -Uz $fpath[-1]/*(N.:t)
%
```

### kind:defer

```zsh
% antidote-script --kind defer foo/bar | subenv ANTIDOTE_HOME
if ! (( $+functions[zsh-defer] )); then
  fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer )
  source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar )
zsh-defer source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar/bar.plugin.zsh
%
```

Test defer zstyle settings

```zsh
% zstyle ':antidote:bundle:*' defer-options '-a'
% zstyle ':antidote:bundle:foo/bar' defer-options '-p'
% antidote-script --kind defer foo/bar | subenv ANTIDOTE_HOME
if ! (( $+functions[zsh-defer] )); then
  fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer )
  source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar )
zsh-defer -p source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar/bar.plugin.zsh
%
% # Uses different defer options due to zstyle matching
% antidote-script --kind defer bar/baz | subenv ANTIDOTE_HOME
if ! (( $+functions[zsh-defer] )); then
  fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer )
  source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-bar-SLASH-baz )
zsh-defer -a source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-bar-SLASH-baz/baz.plugin.zsh
% # cleanup
% t_reset
%
```

### path:plugin-dir

```zsh
% antidote-script --path plugins/extract ohmy/ohmy | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/extract )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/extract/extract.plugin.zsh
%
```

### path:file

```zsh
% antidote-script --path lib/lib1.zsh ohmy/ohmy | subenv ANTIDOTE_HOME
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib/lib1.zsh
%
```

### path:lib-dir

```zsh
% antidote-script --path lib ohmy/ohmy | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib/lib1.zsh
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib/lib2.zsh
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib/lib3.zsh
%
```

### path:theme

```zsh
% antidote-script --path themes/pretty.zsh-theme ohmy/ohmy | subenv ANTIDOTE_HOME
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/themes/pretty.zsh-theme
%
```

### conditional:testfunc

```zsh
% antidote-script --conditional is-macos --path plugins/macos ohmy/ohmy | subenv ANTIDOTE_HOME
if is-macos; then
  fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/macos )
  source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/macos/macos.plugin.zsh
fi
%
```

### autoload:funcdir

```zsh
% antidote-script --path plugins/macos --autoload functions ohmy/ohmy | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/macos/functions )
builtin autoload -Uz $fpath[-1]/*(N.:t)
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/macos )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/macos/macos.plugin.zsh
%
```

### fpath-rule:append/prepend

```zsh
% # append
% antidote-script --fpath-rule append --path plugins/docker ohmy/ohmy | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/docker )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/docker/docker.plugin.zsh
% # prepend
% antidote-script --fpath-rule prepend --path plugins/docker ohmy/ohmy | subenv ANTIDOTE_HOME
fpath=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/docker $fpath )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/docker/docker.plugin.zsh
% # whoops
% antidote-script --fpath-rule foobar --path plugins/docker ohmy/ohmy 2>&1
antidote: error: unexpected fpath rule: 'foobar'
%
```

### pre/post functions

```zsh
% # pre
% antidote-script --pre run_before foo/bar | subenv ANTIDOTE_HOME
run_before
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar/bar.plugin.zsh
% # post
% antidote-script --post run_after foo/bar | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar/bar.plugin.zsh
run_after
%
```

If a plugin is deferred, so is its post event
```zsh
% antidote-script --pre pre-event --post post-event --kind defer foo/bar | subenv ANTIDOTE_HOME
pre-event
if ! (( $+functions[zsh-defer] )); then
  fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer )
  source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar )
zsh-defer source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar/bar.plugin.zsh
zsh-defer post-event
%
```

## Private functions

### __antidote_initfiles

setup

```zsh
% # load __antidote_initfiles from private funcs in antidote-script
% antidote-script -h &>/dev/null
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

## Teardown

```zsh
% t_teardown
%
```

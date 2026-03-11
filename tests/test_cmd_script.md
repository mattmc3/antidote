# antidote zsh_script tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
%
```

## Script Command

### Fails

```zsh
% antidote __private__ zsh_script  #=> --exit 1
% antidote __private__ zsh_script
antidote: error: bundle argument expected
%
```

### Arg style

`zsh_script` accepts '--arg val', '--arg:val', '--arg=val' syntax

```zsh
% antidote __private__ zsh_script --kind zsh foo/bar  #=> --exit 0
% antidote __private__ zsh_script --kind:zsh foo/bar  #=> --exit 0
% antidote __private__ zsh_script --kind=zsh foo/bar  #=> --exit 0
% antidote __private__ zsh_script --kind+zsh foo/bar  #=> --exit 1
%
```

### Scripting types

`zsh_script` works with local files and directories, as well as remote repos.

Script a file:

```zsh
% antidote __private__ zsh_script $ZDOTDIR/aliases.zsh | subenv ZDOTDIR
source "$ZDOTDIR/aliases.zsh"
%
```

Script a lib directory:

```zsh
% antidote __private__ zsh_script $ZDOTDIR/custom/lib | subenv ZDOTDIR
fpath+=( "$ZDOTDIR/custom/lib" )
source "$ZDOTDIR/custom/lib/lib1.zsh"
source "$ZDOTDIR/custom/lib/lib2.zsh"
%
```

Script a plugin directory:

```zsh
% antidote __private__ zsh_script $ZDOTDIR/custom/plugins/myplugin | subenv ZDOTDIR
fpath+=( "$ZDOTDIR/custom/plugins/myplugin" )
source "$ZDOTDIR/custom/plugins/myplugin/myplugin.plugin.zsh"
%
```

Script repos in escaped path-style:

```zsh
% zstyle ':antidote:bundle' path-style escaped
% ANTIDOTE_HOME=$HOME/.cache/antibody
% antidote __private__ zsh_script foo/bar                            2>/dev/null | subenv ANTIDOTE_HOME  #=> --file ./testdata/antibody/script-foobar.zsh
% antidote __private__ zsh_script https://fakegitsite.com/foo/bar                | subenv ANTIDOTE_HOME  #=> --file ./testdata/antibody/script-foobar.zsh
% antidote __private__ zsh_script https://fakegitsite.com/foo/bar.git            | subenv ANTIDOTE_HOME  #=> --file ./testdata/antibody/script-foobar.zsh
% antidote __private__ zsh_script git@fakegitsite.com:foo/qux.git    2>/dev/null | subenv ANTIDOTE_HOME  #=> --file ./testdata/antibody/script-fooqux.zsh
% zstyle -d ':antidote:bundle' path-style
% ANTIDOTE_HOME=$HOME/.cache/antidote
%
```

## Annotations

### kind:clone

Nothing happens when the plugin already exists.

```zsh
% antidote __private__ zsh_script --kind clone foo/bar
%
```

Clone a missing plugin.

```zsh
% antidote __private__ zsh_script --kind clone themes/ohmytheme
# antidote cloning themes/ohmytheme...
%
```

### kind:zsh

```zsh
% antidote __private__ zsh_script --kind zsh foo/bar | subenv ANTIDOTE_HOME
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
%
```

### kind:path

```zsh
% antidote __private__ zsh_script --kind path foo/bar | subenv ANTIDOTE_HOME
export PATH="$ANTIDOTE_HOME/fakegitsite.com/foo/bar:$PATH"
%
```

### kind:fpath

```zsh
% antidote __private__ zsh_script --kind fpath foo/bar | subenv ANTIDOTE_HOME
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
%
```

### kind:autoload

```zsh
% antidote __private__ zsh_script --kind autoload $ZDOTDIR/functions | subenv ZDOTDIR
fpath+=( "$ZDOTDIR/functions" )
builtin autoload -Uz $fpath[-1]/*(N.:t)
%
```

### kind:defer

```zsh
% antidote __private__ zsh_script --kind defer foo/bar | subenv ANTIDOTE_HOME
if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer" )
  source "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
zsh-defer source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
%
```

Test skipping defer loading

```zsh
% antidote __private__ zsh_script --kind defer --skip-load-defer foo/bar | subenv ANTIDOTE_HOME
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
zsh-defer source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
%
```

Test defer zstyle settings

```zsh
% zstyle ':antidote:bundle:*' defer-options '-a'
% zstyle ':antidote:bundle:foo/bar' defer-options '-p'
% antidote __private__ zsh_script --kind defer foo/bar | subenv ANTIDOTE_HOME
if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer" )
  source "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
zsh-defer -p source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
%
% # Uses different defer options due to zstyle matching
% antidote __private__ zsh_script --kind defer bar/baz | subenv ANTIDOTE_HOME
if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer" )
  source "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/bar/baz" )
zsh-defer -a source "$ANTIDOTE_HOME/fakegitsite.com/bar/baz/baz.plugin.zsh"
% # cleanup
% t_reset
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
%
```

### path:plugin-dir

```zsh
% antidote __private__ zsh_script --path plugins/extract ohmy/ohmy | subenv ANTIDOTE_HOME
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/extract" )
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/extract/extract.plugin.zsh"
%
```

### path:file

```zsh
% antidote __private__ zsh_script --path lib/lib1.zsh ohmy/ohmy | subenv ANTIDOTE_HOME
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/lib/lib1.zsh"
%
```

### path:lib-dir

```zsh
% antidote __private__ zsh_script --path lib ohmy/ohmy | subenv ANTIDOTE_HOME
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/lib" )
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/lib/lib1.zsh"
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/lib/lib2.zsh"
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/lib/lib3.zsh"
%
```

### path:theme

```zsh
% antidote __private__ zsh_script --path themes/pretty.zsh-theme ohmy/ohmy | subenv ANTIDOTE_HOME
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/themes/pretty.zsh-theme"
%
```

### conditional:testfunc

```zsh
% antidote __private__ zsh_script --conditional is-macos --path plugins/macos ohmy/ohmy | subenv ANTIDOTE_HOME
if is-macos; then
  fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/macos" )
  source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/macos/macos.plugin.zsh"
fi
%
```

### autoload:funcdir

```zsh
% antidote __private__ zsh_script --path plugins/macos --autoload functions ohmy/ohmy | subenv ANTIDOTE_HOME
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/macos/functions" )
builtin autoload -Uz $fpath[-1]/*(N.:t)
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/macos" )
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/macos/macos.plugin.zsh"
%
```

### fpath-rule:append/prepend

```zsh
% # append
% antidote __private__ zsh_script --fpath-rule append --path plugins/docker ohmy/ohmy | subenv ANTIDOTE_HOME
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/docker" )
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/docker/docker.plugin.zsh"
% # prepend
% antidote __private__ zsh_script --fpath-rule prepend --path plugins/docker ohmy/ohmy | subenv ANTIDOTE_HOME
fpath=( "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/docker" $fpath )
source "$ANTIDOTE_HOME/fakegitsite.com/ohmy/ohmy/plugins/docker/docker.plugin.zsh"
% # whoops
% antidote __private__ zsh_script --fpath-rule foobar --path plugins/docker ohmy/ohmy 2>&1
antidote: error: unexpected fpath rule: 'foobar'
%
```

### pre/post functions

```zsh
% # pre
% antidote __private__ zsh_script --pre run_before foo/bar | subenv ANTIDOTE_HOME
run_before
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
% # post
% antidote __private__ zsh_script --post run_after foo/bar | subenv ANTIDOTE_HOME
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
run_after
%
```

If a plugin is deferred, so is its post event

```zsh
% antidote __private__ zsh_script --pre pre-event --post post-event --kind defer foo/bar | subenv ANTIDOTE_HOME
pre-event
if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer" )
  source "$ANTIDOTE_HOME/fakegitsite.com/getantidote/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/foo/bar" )
zsh-defer source "$ANTIDOTE_HOME/fakegitsite.com/foo/bar/bar.plugin.zsh"
zsh-defer post-event
%
```

## Private functions

### initfiles

setup

```zsh
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
% antidote __private__ initfiles $PLUGINDIR | subenv PLUGINDIR
$PLUGINDIR/myplugin.plugin.zsh
% rm $PLUGINDIR/myplugin.plugin.zsh
%
```

whatever.plugin.zsh

```zsh
% antidote __private__ initfiles $PLUGINDIR | subenv PLUGINDIR
$PLUGINDIR/whatever.plugin.zsh
% rm $PLUGINDIR/whatever.plugin.zsh
%
```

file.zsh

```zsh
% antidote __private__ initfiles $PLUGINDIR | subenv PLUGINDIR
$PLUGINDIR/file.zsh
% rm $PLUGINDIR/file.zsh
%
```

file.sh

```zsh
% antidote __private__ initfiles $PLUGINDIR | subenv PLUGINDIR
$PLUGINDIR/file.sh
% rm $PLUGINDIR/file.sh
%
```

mytheme.zsh-theme

```zsh
% antidote __private__ initfiles $PLUGINDIR | subenv PLUGINDIR
$PLUGINDIR/mytheme.zsh-theme
% rm $PLUGINDIR/mytheme.zsh-theme
%
```

lib

```zsh
% antidote __private__ initfiles $PLUGINDIR/lib | subenv PLUGINDIR
$PLUGINDIR/lib/lib1.zsh
$PLUGINDIR/lib/lib2.zsh
$PLUGINDIR/lib/lib3.zsh
%
```

FAIL: no files left that match

```zsh
% antidote __private__ initfiles $PLUGINDIR  #=> --exit 1
%
```

FAIL: Empty

```zsh
% PLUGINDIR=$T_TEMPDIR/initfiles/foo
% mkdir -p $PLUGINDIR
% antidote __private__ initfiles $PLUGINDIR  #=> --exit 1
%
```

## Teardown

```zsh
% t_teardown
%
```

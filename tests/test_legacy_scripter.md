# __antidote_compat_v1_scripter tests

## Setup

```zsh
% source ./tests/_setup.zsh
% source $T_PRJDIR/antidote.zsh
%
```

## Script Command

### Fails

```zsh
% __antidote_compat_v1_scripter  #=> --exit 1
antidote: error: bundle argument expected
%
```

### Arg style

`__antidote_compat_v1_scripter` accepts '--arg val', '--arg:val', '--arg=val' syntax

```zsh
% __antidote_compat_v1_scripter --kind zsh foo/bar  #=> --exit 0
% __antidote_compat_v1_scripter --kind:zsh foo/bar  #=> --exit 0
% __antidote_compat_v1_scripter --kind=zsh foo/bar  #=> --exit 0
% __antidote_compat_v1_scripter --kind+zsh foo/bar  #=> --exit 1
%
```

### Scripting types

`__antidote_compat_v1_scripter` works with local files and directories, as well as remote repos.

Script a file:

```zsh
% __antidote_compat_v1_scripter $ZDOTDIR/aliases.zsh | subenv ZDOTDIR
source $ZDOTDIR/aliases.zsh
%
```

Script a lib directory:

```zsh
% __antidote_compat_v1_scripter $ZDOTDIR/custom/lib | subenv ZDOTDIR
fpath+=( $ZDOTDIR/custom/lib )
source $ZDOTDIR/custom/lib/lib1.zsh
source $ZDOTDIR/custom/lib/lib2.zsh
%
```

Script a plugin directory:

```zsh
% __antidote_compat_v1_scripter $ZDOTDIR/custom/plugins/myplugin | subenv ZDOTDIR
fpath+=( $ZDOTDIR/custom/plugins/myplugin )
source $ZDOTDIR/custom/plugins/myplugin/myplugin.plugin.zsh
%
```

## Annotations

### kind:clone

Nothing happens when the plugin already exists.

```zsh
% __antidote_compat_v1_scripter --kind clone foo/bar
%
```

Clone a missing plugin.

```zsh
% __antidote_compat_v1_scripter --kind clone bar/foo
# antidote cloning bar/foo...
%
```

### kind:zsh

```zsh
% __antidote_compat_v1_scripter --kind zsh foo/bar | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/foo/bar )
source $ANTIDOTE_HOME/foo/bar/bar.plugin.zsh
%
```

### kind:path

```zsh
% __antidote_compat_v1_scripter --kind path foo/bar | subenv ANTIDOTE_HOME
export PATH="$ANTIDOTE_HOME/foo/bar:$PATH"
%
```

### kind:fpath

```zsh
% __antidote_compat_v1_scripter --kind fpath foo/bar | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/foo/bar )
%
```

### kind:autoload

```zsh
% __antidote_compat_v1_scripter --kind autoload $ZDOTDIR/functions | subenv ZDOTDIR
fpath+=( $ZDOTDIR/functions )
builtin autoload -Uz $fpath[-1]/*(N.:t)
%
```

### kind:defer

```zsh
% __antidote_compat_v1_scripter --kind defer foo/bar | subenv ANTIDOTE_HOME
if ! (( $+functions[zsh-defer] )); then
  fpath+=( $ANTIDOTE_HOME/getantidote/zsh-defer )
  source $ANTIDOTE_HOME/getantidote/zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/foo/bar )
zsh-defer source $ANTIDOTE_HOME/foo/bar/bar.plugin.zsh
%
```

Test defer zstyle settings

```zsh
% zstyle ':antidote:bundle:*' defer-options '-a'
% zstyle ':antidote:bundle:foo/bar' defer-options '-p'
% __antidote_compat_v1_scripter --kind defer foo/bar | subenv ANTIDOTE_HOME
if ! (( $+functions[zsh-defer] )); then
  fpath+=( $ANTIDOTE_HOME/getantidote/zsh-defer )
  source $ANTIDOTE_HOME/getantidote/zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/foo/bar )
zsh-defer -p source $ANTIDOTE_HOME/foo/bar/bar.plugin.zsh
%
% # Uses different defer options due to zstyle matching
% __antidote_compat_v1_scripter --kind defer foo/baz | subenv ANTIDOTE_HOME
if ! (( $+functions[zsh-defer] )); then
  fpath+=( $ANTIDOTE_HOME/getantidote/zsh-defer )
  source $ANTIDOTE_HOME/getantidote/zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/foo/baz )
zsh-defer -a source $ANTIDOTE_HOME/foo/baz/baz.plugin.zsh
% # cleanup
% t_reset
%
```

### path:plugin-dir

```zsh
% __antidote_compat_v1_scripter --path plugins/extract ohmy/ohmy | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/ohmy/ohmy/plugins/extract )
source $ANTIDOTE_HOME/ohmy/ohmy/plugins/extract/extract.plugin.zsh
%
```

### path:file

```zsh
% __antidote_compat_v1_scripter --path lib/lib1.zsh ohmy/ohmy | subenv ANTIDOTE_HOME
source $ANTIDOTE_HOME/ohmy/ohmy/lib/lib1.zsh
%
```

### path:lib-dir

```zsh
% __antidote_compat_v1_scripter --path lib ohmy/ohmy | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/ohmy/ohmy/lib )
source $ANTIDOTE_HOME/ohmy/ohmy/lib/lib1.zsh
source $ANTIDOTE_HOME/ohmy/ohmy/lib/lib2.zsh
source $ANTIDOTE_HOME/ohmy/ohmy/lib/lib3.zsh
%
```

### path:theme

```zsh
% __antidote_compat_v1_scripter --path themes/pretty.zsh-theme ohmy/ohmy | subenv ANTIDOTE_HOME
source $ANTIDOTE_HOME/ohmy/ohmy/themes/pretty.zsh-theme
%
```

### conditional:testfunc

```zsh
% __antidote_compat_v1_scripter --conditional is-macos --path plugins/macos ohmy/ohmy | subenv ANTIDOTE_HOME
if is-macos; then
  fpath+=( $ANTIDOTE_HOME/ohmy/ohmy/plugins/macos )
  source $ANTIDOTE_HOME/ohmy/ohmy/plugins/macos/macos.plugin.zsh
fi
%
```

### autoload:funcdir

```zsh
% __antidote_compat_v1_scripter --path plugins/macos --autoload functions ohmy/ohmy | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/ohmy/ohmy/plugins/macos/functions )
builtin autoload -Uz $fpath[-1]/*(N.:t)
fpath+=( $ANTIDOTE_HOME/ohmy/ohmy/plugins/macos )
source $ANTIDOTE_HOME/ohmy/ohmy/plugins/macos/macos.plugin.zsh
%
```

### fpath-rule:append/prepend

```zsh
% # append
% __antidote_compat_v1_scripter --fpath-rule append --path plugins/docker ohmy/ohmy | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/ohmy/ohmy/plugins/docker )
source $ANTIDOTE_HOME/ohmy/ohmy/plugins/docker/docker.plugin.zsh
% # prepend
% __antidote_compat_v1_scripter --fpath-rule prepend --path plugins/docker ohmy/ohmy | subenv ANTIDOTE_HOME
fpath=( $ANTIDOTE_HOME/ohmy/ohmy/plugins/docker $fpath )
source $ANTIDOTE_HOME/ohmy/ohmy/plugins/docker/docker.plugin.zsh
% # whoops
% __antidote_compat_v1_scripter --fpath-rule foobar --path plugins/docker ohmy/ohmy 2>&1
antidote: error: unexpected fpath rule: 'foobar'
%
```

### pre/post functions

```zsh
% # pre
% __antidote_compat_v1_scripter --pre run_before foo/bar | subenv ANTIDOTE_HOME
run_before
fpath+=( $ANTIDOTE_HOME/foo/bar )
source $ANTIDOTE_HOME/foo/bar/bar.plugin.zsh
% # post
% __antidote_compat_v1_scripter --post run_after foo/bar | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/foo/bar )
source $ANTIDOTE_HOME/foo/bar/bar.plugin.zsh
run_after
%
```

If a plugin is deferred, so is its post event
```zsh
% __antidote_compat_v1_scripter --pre pre-event --post post-event --kind defer foo/bar | subenv ANTIDOTE_HOME
pre-event
if ! (( $+functions[zsh-defer] )); then
  fpath+=( $ANTIDOTE_HOME/getantidote/zsh-defer )
  source $ANTIDOTE_HOME/getantidote/zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/foo/bar )
zsh-defer source $ANTIDOTE_HOME/foo/bar/bar.plugin.zsh
zsh-defer post-event
%
```

## Private functions

### __antidote_initfiles

setup

```zsh
% # load __antidote_initfiles from private funcs in __antidote_compat_v1_scripter
% __antidote_compat_v1_scripter -h &>/dev/null
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

Test empty

```zsh
% __antidote_bulk_clone < $T_TESTDATA/.zsh_plugins_empty.txt
%
```

## Awk Filter defers

Test that only the first defer block is kept...

```zsh
% __antidote_filter_defers $T_PRJDIR/tests/testdata/.zsh_plugins_multi_defer.zsh | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/zsh-users/zsh-history-substring-search )
source $ANTIDOTE_HOME/zsh-users/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh
if ! (( $+functions[zsh-defer] )); then
  fpath+=( $ANTIDOTE_HOME/getantidote/zsh-defer )
  source $ANTIDOTE_HOME/getantidote/zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/zsh-users/zsh-syntax-highlighting )
zsh-defer source $ANTIDOTE_HOME/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
if is-macos; then
  fpath+=( $ANTIDOTE_HOME/ohmy/ohmy/plugins/macos )
  source $ANTIDOTE_HOME/ohmy/ohmy/plugins/macos/macos.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions )
zsh-defer source $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
fpath+=( $ANTIDOTE_HOME/zdharma-continuum/fast-syntax-highlighting )
zsh-defer source $ANTIDOTE_HOME/zdharma-continuum/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
fpath+=( $ANTIDOTE_HOME/dracula/zsh )
source $ANTIDOTE_HOME/dracula/zsh/dracula.zsh-theme
fpath+=( $ANTIDOTE_HOME/peterhurford/up.zsh )
source $ANTIDOTE_HOME/peterhurford/up.zsh/up.plugin.zsh
fpath+=( $ANTIDOTE_HOME/rummik/zsh-tailf )
source $ANTIDOTE_HOME/rummik/zsh-tailf/tailf.plugin.zsh
fpath+=( $ANTIDOTE_HOME/rupa/z )
source $ANTIDOTE_HOME/rupa/z/z.sh
%
```

Test that with no defers, nothing is altered...

```zsh
% __antidote_filter_defers $T_PRJDIR/tests/testdata/.zsh_plugins_no_defer.zsh  #=> --file testdata/.zsh_plugins_no_defer.zsh
%
```

## Awk Bundle parser

Parse a simple repo:

```zsh
% echo foo/bar | __antidote_compat_v1_parser
__antidote_compat_v1_scripter foo/bar
%
```

```zsh
% echo 'https://github.com/foo/bar path:lib branch:dev' | __antidote_compat_v1_parser
__antidote_compat_v1_scripter --path lib --branch dev https://github.com/foo/bar
% echo 'git@github.com:foo/bar.git kind:clone branch:main' | __antidote_compat_v1_parser
__antidote_compat_v1_scripter --kind clone --branch main git@github.com:foo/bar.git
% echo 'foo/bar kind:fpath abc:xyz' | __antidote_compat_v1_parser
__antidote_compat_v1_scripter --kind fpath --abc xyz foo/bar
% echo 'foo/bar path:plugins/myplugin kind:path  # trailing comment' | __antidote_compat_v1_parser
__antidote_compat_v1_scripter --path plugins/myplugin --kind path foo/bar
%
```

Handle funky whitespace

```zsh
% cr=$'\r'; lf=$'\n'; tab=$'\t'
% echo "foo/bar${tab}kind:path${cr}${lf}" | __antidote_compat_v1_parser
__antidote_compat_v1_scripter --kind path foo/bar
%
```

The bundle parser is an awk script that turns the bundle DSL into __antidote_compat_v1_scripter statements.

```zsh
% __antidote_compat_v1_parser $ZDOTDIR/.zsh_plugins.txt
__antidote_compat_v1_scripter ~/foo/bar
__antidote_compat_v1_scripter --path plugins/myplugin \$ZSH_CUSTOM
__antidote_compat_v1_scripter foo/bar
__antidote_compat_v1_scripter git@github.com:foo/qux.git
__antidote_compat_v1_scripter --kind clone getantidote/zsh-defer
__antidote_compat_v1_scripter --kind zsh foo/bar
__antidote_compat_v1_scripter --kind fpath foo/bar
__antidote_compat_v1_scripter --kind path foo/bar
__antidote_compat_v1_scripter --path lib ohmy/ohmy
__antidote_compat_v1_scripter --path plugins/extract ohmy/ohmy
__antidote_compat_v1_scripter --path plugins/magic-enter --kind defer ohmy/ohmy
__antidote_compat_v1_scripter --path custom/themes/pretty.zsh-theme ohmy/ohmy
%
```

## Teardown

```zsh
% t_teardown
%
```

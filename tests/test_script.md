# antidote-script tests

## Setup

```zsh
% source $PWD/tests/scripts/setup.zsh
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
% antidote-script $ZDOTDIR/aliases.zsh | subvar ZDOTDIR
source $ZDOTDIR/aliases.zsh
%
```

Script a lib directory:

```zsh
% antidote-script $ZDOTDIR/custom/lib | subvar ZDOTDIR
fpath+=( $ZDOTDIR/custom/lib )
source $ZDOTDIR/custom/lib/lib1.zsh
source $ZDOTDIR/custom/lib/lib2.zsh
%
```

Script a plugin directory:

```zsh
% antidote-script $ZDOTDIR/custom/plugins/myplugin | subvar ZDOTDIR
fpath+=( $ZDOTDIR/custom/plugins/myplugin )
source $ZDOTDIR/custom/plugins/myplugin/myplugin.plugin.zsh
%
```

Script repos:

```zsh
% antidote-script foo/bar                        | subvar ANTIDOTE_HOME  #=> --file ./testdata/script-foobar.zsh
% antidote-script https://github.com/foo/bar     | subvar ANTIDOTE_HOME  #=> --file ./testdata/script-foobar.zsh
% antidote-script https://github.com/foo/bar.git | subvar ANTIDOTE_HOME  #=> --file ./testdata/script-foobar.zsh
% antidote-script git@github.com:baz/qux.git     | subvar ANTIDOTE_HOME  #=> --file ./testdata/script-bazqux.zsh
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
% antidote-script --kind zsh foo/bar | subvar ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar/bar.plugin.zsh
%
```

### kind:path

```zsh
% antidote-script --kind path foo/bar | subvar ANTIDOTE_HOME
export PATH="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar:$PATH"
%
```

### kind:fpath

```zsh
% antidote-script --kind fpath foo/bar | subvar ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar )
%
```

### kind:autoload

```zsh
% antidote-script --kind autoload $ZDOTDIR/functions | subvar ZDOTDIR
fpath+=( $ZDOTDIR/functions )
autoload -Uz $fpath[-1]/*(N.:t)
%
```

### kind:defer

```zsh
% antidote-script --kind defer foo/bar | subvar ANTIDOTE_HOME
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
% zstyle ':antidote:plugin:*' defer-options '-a'
% zstyle ':antidote:plugin:foo/bar' defer-options '-p'
% antidote-script --kind defer foo/bar | subvar ANTIDOTE_HOME
if ! (( $+functions[zsh-defer] )); then
  fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer )
  source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar )
zsh-defer -p source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar/bar.plugin.zsh
%
% # Uses different defer options due to zstyle matching
% antidote-script --kind defer bar/baz | subvar ANTIDOTE_HOME
if ! (( $+functions[zsh-defer] )); then
  fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer )
  source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-romkatv-SLASH-zsh-defer/zsh-defer.plugin.zsh
fi
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-bar-SLASH-baz )
zsh-defer -a source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-bar-SLASH-baz/baz.plugin.zsh
%
```

### path:plugin-dir

```zsh
% antidote-script --path plugins/extract ohmy/ohmy | subvar ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/extract )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/extract/extract.plugin.zsh
%
```

### path:file

```zsh
% antidote-script --path lib/lib1.zsh ohmy/ohmy | subvar ANTIDOTE_HOME
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib/lib1.zsh
%
```

### path:lib-dir

```zsh
% antidote-script --path lib ohmy/ohmy | subvar ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib/lib1.zsh
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib/lib2.zsh
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib/lib3.zsh
%
```

### path:theme

```zsh
% antidote-script --path themes/pretty.zsh-theme ohmy/ohmy | subvar ANTIDOTE_HOME
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/themes/pretty.zsh-theme
%
```

### conditional:testfunc

```zsh
% antidote-script --conditional is-macos --path plugins/macos ohmy/ohmy | subvar ANTIDOTE_HOME
if is-macos; then
  fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/macos )
  source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/macos/macos.plugin.zsh
fi
%
```

### autoload:funcdir

```zsh
% antidote-script --path plugins/macos --autoload functions ohmy/ohmy | subvar ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/macos/functions )
autoload -Uz $fpath[-1]/*(N.:t)
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/macos )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/macos/macos.plugin.zsh
%
```

## Teardown

```zsh
% t_teardown
%
```

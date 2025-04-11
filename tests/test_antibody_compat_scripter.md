# test antibody compat scripter

## Setup

```zsh
% source ./tests/_setup.zsh
% source $T_PRJDIR/antidote.zsh
% zstyle ':antidote:compatibility-mode' 'antibody' 'on'
% ANTIDOTE_HOME=$HOME/.cache/antibody
%
```

## Script Command

### Scripting types

`__antidote_scripter` works with local files and directories, as well as remote repos.

Script a file:

```zsh
% __antidote_scripter "$ZDOTDIR/aliases.zsh" | subenv ZDOTDIR
source $ZDOTDIR/aliases.zsh
%
```

Script a lib directory:

```zsh
% __antidote_scripter "$ZDOTDIR/custom/lib" | subenv ZDOTDIR
fpath+=( $ZDOTDIR/custom/lib )
source $ZDOTDIR/custom/lib/lib1.zsh
source $ZDOTDIR/custom/lib/lib2.zsh
%
```

Script a plugin directory:

```zsh
% __antidote_scripter '$ZDOTDIR/custom/plugins/myplugin' | subenv ZDOTDIR
fpath+=( $ZDOTDIR/custom/plugins/myplugin )
source $ZDOTDIR/custom/plugins/myplugin/myplugin.plugin.zsh
%
```

Script repos in antibody style:

```zsh
% __antidote_scripter 'foo/bar'                        | subenv ANTIDOTE_HOME  #=> --file ./testdata/antibody/script-foobar.zsh
% __antidote_scripter 'https://github.com/foo/bar'     | subenv ANTIDOTE_HOME  #=> --file ./testdata/antibody/script-foobar.zsh
% __antidote_scripter 'https://github.com/foo/bar.git' | subenv ANTIDOTE_HOME  #=> --file ./testdata/antibody/script-foobar.zsh
% __antidote_scripter 'git@github.com:foo/qux.git'     | subenv ANTIDOTE_HOME  #=> --file ./testdata/antibody/script-fooqux.zsh
%
```

## Annotations

### kind:clone

Nothing to do (no ouputs) on kind:clone.

```zsh
% __antidote_scripter 'foo/bar kind:clone'
%
```

### kind:zsh

kind:zsh is implied

```zsh
% __antidote_scripter 'foo/bar' | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar/bar.plugin.zsh
%
```

Or, kind:zsh can be specified

```zsh
% __antidote_scripter 'foo/bar kind:zsh' | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar/bar.plugin.zsh
%
```

### kind:path

```zsh
% __antidote_scripter 'foo/bar kind:path' | subenv ANTIDOTE_HOME
export PATH="$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar:$PATH"
%
```

### kind:fpath

```zsh
% __antidote_scripter 'foo/bar kind:fpath' | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-foo-SLASH-bar )
%
```

### path:plugin-dir

```zsh
% __antidote_scripter 'ohmy/ohmy path:plugins/extract' | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/extract )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/plugins/extract/extract.plugin.zsh
%
```

### path:file

```zsh
% __antidote_scripter 'ohmy/ohmy path:lib/lib1.zsh' | subenv ANTIDOTE_HOME
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib/lib1.zsh
%
```

### path:lib-dir

```zsh
% __antidote_scripter 'ohmy/ohmy path:lib' | subenv ANTIDOTE_HOME
fpath+=( $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib )
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib/lib1.zsh
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib/lib2.zsh
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/lib/lib3.zsh
%
```

### path:theme

```zsh
% __antidote_scripter 'ohmy/ohmy path:themes/pretty.zsh-theme'
source $ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-ohmy-SLASH-ohmy/themes/pretty.zsh-theme
%
```

## Teardown

```zsh
% t_teardown
%
```

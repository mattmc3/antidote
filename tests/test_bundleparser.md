# antidote bundle parser tests

## Setup

```zsh
% AWKDIR=$PWD/functions/scripts
% TESTDATA=$PWD/tests/testdata
% source $PWD/tests/scripts/setup.zsh
%
```

### awk bundle parser

The bundle parser is an awk script that turns the bundle DSL into antidote-script statements.

```zsh
% awk -f $AWKDIR/bundle-parser.awk $ZDOTDIR/.zsh_plugins.txt
antidote-script foo/bar
antidote-script git@github.com:baz/qux.git
antidote-script --kind clone romkatv/zsh-defer
antidote-script --kind zsh foo/bar
antidote-script --kind fpath foo/bar
antidote-script --kind path foo/bar
antidote-script --path lib ohmy/ohmy
antidote-script --path plugins/extract ohmy/ohmy
antidote-script --path plugins/magic-enter --kind defer ohmy/ohmy
antidote-script --path custom/themes/pretty.zsh-theme ohmy/ohmy
%
```

## Teardown

```zsh
% t_teardown
%
```

# Test arg collector

## Setup

```zsh
% source ./tests/_setup.zsh
% source $T_PRJDIR/antidote.zsh
%
```

## Collect input

If we \<redirect input it should output that.

```zsh
% __antidote_argcollector <$ZDOTDIR/.zsh_plugins.txt #=> --file tmp_home/.zsh/.zsh_plugins.txt
%
```

If we \|pipe input it should output that.

```zsh
% cat $ZDOTDIR/.zsh_plugins.txt | __antidote_argcollector #=> --file tmp_home/.zsh/.zsh_plugins.txt
%
```

If we pass argument it should output that.

```zsh
% __antidote_argcollector 'a\nb\nc\n'
a
b
c

%
```

## Teardown

```zsh
% t_teardown
%
```

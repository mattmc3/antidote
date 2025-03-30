# Test git mocking

```zsh
% source ./tests/__init__.zsh
% function git { mockgit "$@" }
%
```

Mock: `git --version`

```zsh
% git --version
mockgit version 0.0.0
%
```

Mock: SHA

```zsh
% git rev-parse HEAD
abcd1230abcd1230abcd1230abcd1230abcd1230
% git rev-parse --short HEAD
abcd123
%
```

Mock: clone

```zsh
% T_TEMPDIR=${$(mktemp -d -t t_antidote.XXXXXXXX):A}
% # echo $T_TEMPDIR
% rm -rf -- $T_TEMPDIR
%
```

Mock: pull

```zsh
% git pull --quiet
% git pull
MOCKGIT: Already up to date.
%
```

Mock: no-op commands

```zsh
% git submodule sync #=> --exit 0
% git submodule sync
% git submodule update #=> --exit 0
% git submodule update
%
```

Mock: non-recognized

```zsh
% git status -sb #=> --exit 1
% git status -sb
mocking not implemented for git command: git status -sb
%
```

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

Mock: pull

```zsh
% git pull --quiet
% git pull
MOCKGIT: Already up to date.
%
```

Mock: clone

Setup...

```zsh
% T_TEMPDIR=${$(mktemp -d -t t_antidote.XXXXXXXX):A}
%
```

```zsh
% % test -d $T_TEMPDIR/fakeuser #=> --exit 1
% git clone --quiet --depth 1 --recurse-submodules --shallow-submodules https://fakegitsite.com/fakeuser/fakerepo $T_TEMPDIR/fakeuser
% test -d $T_TEMPDIR/fakeuser #=> --exit 0
% test -e $T_TEMPDIR/fakeuser/fakerepo/fakerepo.plugin.zsh #=> --exit 0
%
```

Clean up

```zsh
% rm -rf -- $T_TEMPDIR
%
```

Mock: clone missing

```zsh
% git clone --depth 1 --recurse-submodules --shallow-submodules https://fakegitsite.com/testy/mctestface
MOCKGIT: Cloning into 'mctestface'...
MOCKGIT: Repository not found.
MOCKGIT: repository 'https://fakegitsite.com/testy/mctestface' not found
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

# antidote real lockfile tests

## Setup

```zsh
% TESTDATA=$T_PRJDIR/tests/testdata/real
% source ./tests/__init__.zsh
% t_setup_real
% # copy the lockfile into place (pinned to 2024-01-01 SHAs)
% command cp -f -- "$T_TESTDATA/.zsh_plugins.lock" "$ZDOTDIR/.zsh_plugins.lock"
%
```

## Bundle with lockfile

Clone all plugins and verify the lockfile constrains them to the locked SHAs.

```zsh
% antidote bundle <$ZDOTDIR/.zsh_plugins.txt >$ZDOTDIR/.zsh_plugins.zsh 2>/dev/null
%
```

## Verify locked SHAs

Each cloned repo should be checked out at the exact SHA from the lockfile.

```zsh
% git -C $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions rev-parse HEAD
11d17e7fea9fba8067f992b3d95e884c20a4069c
% git -C $ANTIDOTE_HOME/zsh-users/zsh-history-substring-search rev-parse HEAD
8dd05bfcc12b0cd1ee9ea64be725b3d9f713cf64
% git -C $ANTIDOTE_HOME/zsh-users/zsh-syntax-highlighting rev-parse HEAD
dcc99a86497491dfe41fb8b0d5f506033546a8c0
% git -C $ANTIDOTE_HOME/zsh-users/antigen rev-parse HEAD
64de2dcd95d6a8e879cd2244c763d99f0144e78e
% git -C $ANTIDOTE_HOME/sindresorhus/pure rev-parse HEAD
4e0ce0a2f8576894e5dad83857e9a9851faa0f5b
% git -C $ANTIDOTE_HOME/romkatv/zsh-bench rev-parse HEAD
3b4896c4840c64bea8e79b8392a93dfdc5a0a096
% git -C $ANTIDOTE_HOME/mattmc3/zman rev-parse HEAD
40483a43f262698476d3d3c740c3c865e15ac01e
% git -C $ANTIDOTE_HOME/ohmyzsh/ohmyzsh rev-parse HEAD
fa770f9678477febe0ed99566d9f3331f3714eca
% git -C $ANTIDOTE_HOME/mattmc3/antidote rev-parse HEAD
de71516a7bdca8fbf17eda1d08129772ff6e8622
% git -C $ANTIDOTE_HOME/zdharma-continuum/fast-syntax-highlighting rev-parse HEAD
cf318e06a9b7c9f2219d78f41b46fa6e06011fd9
% git -C $ANTIDOTE_HOME/dracula/zsh rev-parse HEAD
75ea3f5e1055291caf56b4aea6a5d58d00541c41
% git -C $ANTIDOTE_HOME/peterhurford/up.zsh rev-parse HEAD
c8cc0d0edd6be2d01f467267e3ed385c386a0acb
% git -C $ANTIDOTE_HOME/rummik/zsh-tailf rev-parse HEAD
92b04527b784a70a952efde20e6a7269278fb17d
% git -C $ANTIDOTE_HOME/rupa/z rev-parse HEAD
d37a763a6a30e1b32766fecc3b8ffd6127f8a0fd
% git -C $ANTIDOTE_HOME/romkatv/zsh-defer rev-parse HEAD
1c75faff4d8584afe090b06db11991c8c8d62055
%
```

## Teardown

```zsh
% t_teardown
%
```

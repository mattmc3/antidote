# antidote real lockfile tests

## Setup

```zsh
% TESTDATA=$T_PRJDIR/tests/testdata/real
% source ./tests/__init__.zsh
% t_setup_real
%
```

## Bundle with 2024 lockfile

Clone all plugins constrained to 2024-01-01 SHAs.

```zsh
% command cp -f -- "$T_TESTDATA/.zsh_plugins.2024.lock" "$ZDOTDIR/.zsh_plugins.lock"
% antidote bundle <$ZDOTDIR/.zsh_plugins.txt >$ZDOTDIR/.zsh_plugins.zsh 2>/dev/null
%
```

## Verify 2024 SHAs

```zsh
% git -C $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions rev-parse HEAD
11d17e7fea9fba8067f992b3d95e884c20a4069c
% git -C $ANTIDOTE_HOME/zsh-users/zsh-history-substring-search rev-parse HEAD
8dd05bfcc12b0cd1ee9ea64be725b3d9f713cf64
% git -C $ANTIDOTE_HOME/sindresorhus/pure rev-parse HEAD
4e0ce0a2f8576894e5dad83857e9a9851faa0f5b
% git -C $ANTIDOTE_HOME/romkatv/zsh-bench rev-parse HEAD
3b4896c4840c64bea8e79b8392a93dfdc5a0a096
% git -C $ANTIDOTE_HOME/romkatv/zsh-defer rev-parse HEAD
1c75faff4d8584afe090b06db11991c8c8d62055
% git -C $ANTIDOTE_HOME/ohmyzsh/ohmyzsh rev-parse HEAD
fa770f9678477febe0ed99566d9f3331f3714eca
% git -C $ANTIDOTE_HOME/mattmc3/zman rev-parse HEAD
40483a43f262698476d3d3c740c3c865e15ac01e
%
```

## Swap to 2025 lockfile and re-bundle

Replace the lockfile with 2025-01-01 SHAs and re-bundle.
Existing repos should sync to the new locked SHAs.

```zsh
% command cp -f -- "$T_TESTDATA/.zsh_plugins.2025.lock" "$ZDOTDIR/.zsh_plugins.lock"
% antidote bundle <$ZDOTDIR/.zsh_plugins.txt >$ZDOTDIR/.zsh_plugins.zsh 2>/dev/null
%
```

## Verify 2025 SHAs

Repos that changed between 2024 and 2025 should now be at the new SHAs.

```zsh
% git -C $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions rev-parse HEAD
0e810e5afa27acbd074398eefbe28d13005dbc15
% git -C $ANTIDOTE_HOME/zsh-users/zsh-history-substring-search rev-parse HEAD
87ce96b1862928d84b1afe7c173316614b30e301
% git -C $ANTIDOTE_HOME/sindresorhus/pure rev-parse HEAD
92b8e9057988566b37ff695e70e2e9bbeb7196c8
% git -C $ANTIDOTE_HOME/romkatv/zsh-bench rev-parse HEAD
661fc46c74fd970f00346d285f5ae434130491f0
% git -C $ANTIDOTE_HOME/romkatv/zsh-defer rev-parse HEAD
53a26e287fbbe2dcebb3aa1801546c6de32416fa
% git -C $ANTIDOTE_HOME/ohmyzsh/ohmyzsh rev-parse HEAD
d82669199b5d900b50fd06dd3518c277f0def869
% git -C $ANTIDOTE_HOME/mattmc3/zman rev-parse HEAD
8c41af514ae9ab6bc78078ed97c376edcfab929d
%
```

## Repos unchanged between 2024 and 2025 stay the same

```zsh
% git -C $ANTIDOTE_HOME/dracula/zsh rev-parse HEAD
75ea3f5e1055291caf56b4aea6a5d58d00541c41
% git -C $ANTIDOTE_HOME/rupa/z rev-parse HEAD
d37a763a6a30e1b32766fecc3b8ffd6127f8a0fd
% git -C $ANTIDOTE_HOME/zsh-users/antigen rev-parse HEAD
64de2dcd95d6a8e879cd2244c763d99f0144e78e
% git -C $ANTIDOTE_HOME/peterhurford/up.zsh rev-parse HEAD
c8cc0d0edd6be2d01f467267e3ed385c386a0acb
%
```

## Swap to 2026 lockfile and re-bundle

```zsh
% command cp -f -- "$T_TESTDATA/.zsh_plugins.2026.lock" "$ZDOTDIR/.zsh_plugins.lock"
% antidote bundle <$ZDOTDIR/.zsh_plugins.txt >$ZDOTDIR/.zsh_plugins.zsh 2>/dev/null
%
```

## Verify 2026 SHAs

Repos that changed between 2025 and 2026 should now be at the new SHAs.

```zsh
% git -C $ANTIDOTE_HOME/zsh-users/zsh-autosuggestions rev-parse HEAD
85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5
% git -C $ANTIDOTE_HOME/zsh-users/zsh-history-substring-search rev-parse HEAD
aa09f04747c0e3326914a895b304498b000c6e70
% git -C $ANTIDOTE_HOME/sindresorhus/pure rev-parse HEAD
54bd501c802283dee0940457da6eb3e642bd1453
% git -C $ANTIDOTE_HOME/romkatv/zsh-bench rev-parse HEAD
d7f9f821688bdff9365e630a8aaeba1fd90499b1
% git -C $ANTIDOTE_HOME/ohmyzsh/ohmyzsh rev-parse HEAD
a79b37b95461ea2be32578957473375954ab31ff
% git -C $ANTIDOTE_HOME/zdharma-continuum/fast-syntax-highlighting rev-parse HEAD
3d574ccf48804b10dca52625df13da5edae7f553
%
```

## Repos unchanged between 2025 and 2026 stay the same

```zsh
% git -C $ANTIDOTE_HOME/mattmc3/zman rev-parse HEAD
8c41af514ae9ab6bc78078ed97c376edcfab929d
% git -C $ANTIDOTE_HOME/romkatv/zsh-defer rev-parse HEAD
53a26e287fbbe2dcebb3aa1801546c6de32416fa
% git -C $ANTIDOTE_HOME/dracula/zsh rev-parse HEAD
75ea3f5e1055291caf56b4aea6a5d58d00541c41
% git -C $ANTIDOTE_HOME/rupa/z rev-parse HEAD
d37a763a6a30e1b32766fecc3b8ffd6127f8a0fd
% git -C $ANTIDOTE_HOME/zsh-users/antigen rev-parse HEAD
64de2dcd95d6a8e879cd2244c763d99f0144e78e
% git -C $ANTIDOTE_HOME/peterhurford/up.zsh rev-parse HEAD
c8cc0d0edd6be2d01f467267e3ed385c386a0acb
%
```

## Teardown

```zsh
% t_teardown
%
```

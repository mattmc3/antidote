# antidote handles special Zsh options

## Setup

Tests to handle special Zsh options. [#154](https://github.com/mattmc3/antidote/issues/154).

```zsh
% source ./tests/_setup.zsh
% setopt KSH_ARRAYS SH_GLOB
% source ./antidote.zsh
%
```

# Ensure bundle works

```zsh
% antidote bundle <$ZDOTDIR/.zsh_plugins.txt >$ZDOTDIR/.zsh_plugins.zsh
% cat $ZDOTDIR/.zsh_plugins.zsh | subenv  #=> --file testdata/.zsh_plugins.zsh
%
```

# Ensure options remained

```zsh
% [[ -o KSH_ARRAYS ]] && echo KSH_ARRAYS
KSH_ARRAYS
% [[ -o SH_GLOB ]] && echo SH_GLOB
SH_GLOB
% # unset
% unsetopt KSH_ARRAYS SH_GLOB
% [[ -o KSH_ARRAYS ]] && echo KSH_ARRAYS
% [[ -o SH_GLOB ]] && echo SH_GLOB
%
```

## Teardown

```zsh
% t_teardown
%
```

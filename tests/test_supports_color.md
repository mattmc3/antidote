# antidote supports color tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

## NO_COLOR takes highest priority

```zsh
% TERM=xterm-256color CLICOLOR_FORCE=1 NO_COLOR=1 antidote __private__ supports_color; echo $?
1
%
```

## CLICOLOR_FORCE bypasses TTY check

```zsh
% TERM=xterm-256color CLICOLOR_FORCE=1 antidote __private__ supports_color; echo $?
0
%
```

## Non-TTY disables colors

```zsh
% TERM=xterm-256color antidote __private__ supports_color; echo $?
1
%
```

## Terminal capability detection

```zsh
% CLICOLOR_FORCE=1 COLORTERM=truecolor antidote __private__ supports_color; echo $?
0
% CLICOLOR_FORCE=1 COLORTERM=24bit antidote __private__ supports_color; echo $?
0
% CLICOLOR_FORCE=1 TERM=xterm-256color antidote __private__ supports_color; echo $?
0
% CLICOLOR_FORCE=1 TERM=rxvt antidote __private__ supports_color; echo $?
0
%
```

## Teardown

```zsh
% t_teardown
%
```

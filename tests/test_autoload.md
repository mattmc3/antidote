# antidote lazy load test

## Setup

```zsh
% zstyle ':antidote:test:version' show-sha off
% echo $+functions[antidote]
0
% fpath=($PWD $fpath)
% autoload -Uz antidote
% echo $+functions[antidote]
1
% which antidote | tr '\t' ' '
antidote () {
 # undefined
 builtin autoload -XUz
}
% antidote -h | head -n1
antidote - the cure to slow zsh plugin management
%
```

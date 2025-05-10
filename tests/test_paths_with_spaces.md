# antidote test paths with spaces

## Setup

```zsh
% TESTDATA=$PWD/tests/testdata
% source ./tests/__init__.zsh
% t_setup
% antidote-bundle -h &>/dev/null
% ANTIDOTE_HOME="$HOME/.cache/antidote with spaces"
% mkdir -p -- "$ANTIDOTE_HOME"
%
```

The bundle parser needs to properly handle quoted annotations.

```zsh
% __antidote_parser 'foo/bar' | print_aarr
$assoc_arr  : bundle
_repo       : foo/bar
_repodir    : foo/bar
_type       : repo
_url        : https://github.com/foo/bar
name        : foo/bar
% __antidote_parse_bundles 'foo/bar'
antidote-script foo/bar
% antidote bundle 'foo/bar'
# antidote cloning foo/bar...
fpath+=( "$HOME/.cache/antidote with spaces/foo/bar" )
source "$HOME/.cache/antidote with spaces/foo/bar/bar.plugin.zsh"
%
```

## Teardown

```zsh
% t_teardown
%
```

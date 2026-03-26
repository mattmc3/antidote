# antidote symlinked ANTIDOTE_HOME tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
%
```

Point `ANTIDOTE_HOME` at a symlinked directory:

```zsh
% real_home="$HOME/.cache/antidote-real"
% link_home="$HOME/.cache/antidote-link"
% command rm -rf -- "$real_home" "$link_home"
% mkdir -p -- "$real_home"
% ln -s "$real_home" "$link_home"
% ANTIDOTE_HOME="$link_home"
%
```

`antidote home` reports the symlink path:

```zsh
% antidote home | subenv HOME
$HOME/.cache/antidote-link
%
```

## Clone and List

Before cloning, `antidote list` warns for an empty symlinked home:

```zsh
% antidote list 2>&1 | subenv ANTIDOTE_HOME
antidote: list: no bundles found in '$ANTIDOTE_HOME'
%
```

`antidote bundle` can clone to a symlinked home:

```zsh
% antidote bundle foo/bar &>/dev/null
% antidote bundle pintest/pinme &>/dev/null
% test -d "$real_home/fakegitsite.com/foo/bar/.git"  #=> --exit 0
% test -d "$real_home/fakegitsite.com/pintest/pinme/.git"  #=> --exit 0
%
```

`antidote list` still finds cloned bundles:

```zsh
% antidote list --dirs | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/foo/bar
$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme
% antidote list | wc -l | awk '{print $1}'
2
%
```

Other `list` output modes also work under symlinked home:

```zsh
% antidote list --url | sort
https://fakegitsite.com/foo/bar
https://fakegitsite.com/pintest/pinme
% antidote list --long | grep -A1 'Repo:   foo/bar' | subenv ANTIDOTE_HOME
Repo:   foo/bar
Path:   $ANTIDOTE_HOME/fakegitsite.com/foo/bar
% antidote list --jsonl | grep -c '"path":"'$ANTIDOTE_HOME'/fakegitsite.com/'
2
%
```

`antidote path` resolves bundle locations:

```zsh
% printf '%s\n' foo/bar pintest/pinme | antidote path | sort | subenv ANTIDOTE_HOME
$ANTIDOTE_HOME/fakegitsite.com/foo/bar
$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme
%
```

## Pin and Update

Pinned repos are skipped during update; unpinned repos are updated:

```zsh
% pin_dir="$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme"
% foo_dir="$ANTIDOTE_HOME/fakegitsite.com/foo/bar"
% foo_sha_before=$(git -C "$foo_dir" rev-parse --short HEAD)
% antidote bundle 'pintest/pinme pin:64642c5691051ba0d82f5bda60b745f6fd042325' &>/dev/null
% git -C "$pin_dir" rev-parse --short HEAD
64642c5
% antidote update --bundles 2>&1 | grep -c 'skipping update for pinned bundle: pintest/pinme'
1
% git -C "$foo_dir" rev-parse --short HEAD
400b29a
% antidote bundle 'pintest/pinme' &>/dev/null
% git -C "$pin_dir" config --get antidote.pin  #=> --exit 1
% antidote update --bundles 2>&1 | grep -c 'skipping update for pinned bundle: pintest/pinme'
0
% git -C "$pin_dir" rev-parse --short HEAD
d54e0ca
%
```

## Snapshot

Snapshot save/list are included because snapshot save enumerates bundles via
`find_bundles`, which scans `ANTIDOTE_HOME`:

```zsh
% antidote snapshot save >/dev/null
% test "$(antidote snapshot list | wc -l | awk '{print $1}')" -gt 0  #=> --exit 0
%
```

## Purge

`antidote purge` removes bundles from the symlink target:

```zsh
% antidote purge foo/bar | subenv HOME
Removed 'foo/bar'.
Bundle 'foo/bar' was commented out in '$HOME/.zsh/.zsh_plugins.txt'.
% test -d "$real_home/fakegitsite.com/foo/bar/.git"  #=> --exit 1
% antidote list | wc -l | awk '{print $1}'
1
% antidote purge pintest/pinme | subenv HOME
Removed 'pintest/pinme'.
Bundle 'pintest/pinme' was commented out in '$HOME/.zsh/.zsh_plugins.txt'.
% test -d "$real_home/fakegitsite.com/pintest/pinme/.git"  #=> --exit 1
% antidote list 2>&1 | subenv ANTIDOTE_HOME
antidote: list: no bundles found in '$ANTIDOTE_HOME'
%
```

`purge --all` also works when `ANTIDOTE_HOME` is a symlink:

```zsh
% antidote bundle foo/bar &>/dev/null
% zstyle ':antidote:test:purge' answer 'y'
% antidote purge --all | tail -n 1
Antidote purge complete. Be sure to start a new Zsh session.
% test -e "$link_home"  #=> --exit 1
% test -d "$real_home"  #=> --exit 0
% command find "$real_home" -mindepth 1 | wc -l | awk '{print $1}'
0
% antidote list 2>&1 | subenv ANTIDOTE_HOME
antidote: list: no bundles found in '$ANTIDOTE_HOME'
%
```

## Behavior: External Target Via Home Symlink

This documents current behavior when `ANTIDOTE_HOME` is a symlink under `$HOME`
that points to a target outside `$HOME` (for example `/tmp/...`). Purge still
removes bundle contents via the symlink path:

```zsh
% ANTIDOTE_TMPDIR="$HOME/.tmp"
% mkdir -p -- "$ANTIDOTE_TMPDIR"
% real_home_ext="/tmp/antidote-ext-$$"
% link_home_ext="$HOME/.cache/antidote-link-external"
% command rm -rf -- "$link_home_ext" "$real_home_ext"
% mkdir -p -- "$real_home_ext"
% ln -s "$real_home_ext" "$link_home_ext"
% ANTIDOTE_HOME="$link_home_ext"
% antidote bundle foo/bar &>/dev/null
% antidote purge foo/bar | subenv HOME
Removed 'foo/bar'.
Bundle 'foo/bar' was commented out in '$HOME/.zsh/.zsh_plugins.txt'.
% test -d "$real_home_ext/fakegitsite.com/foo/bar/.git"  #=> --exit 1
% command rm -rf -- "$link_home_ext" "$real_home_ext"
%
```

## Teardown

```zsh
% t_teardown
%
```

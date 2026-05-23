# antidote min-age tests

The `dino/saur` fixture has three commits with dates relative to when
fixtures were generated:
- initial: ~900 days old
- stable: ~400 days old — qualifies for min-age=200
- latest: ~1 day old — always too new for min-age=200

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
% zstyle ':antidote:test:version' show-sha off
% zstyle ':antidote:test:git' autostash off
%
```

## Clone: min-age resets to qualifying commit

Clone with min-age=200. Should reset to stable (~400d old), not latest (~1d old).

```zsh
% zstyle ':antidote:bundle:dino/saur' min-age 200
% antidote bundle 'dino/saur kind:clone' &>/dev/null
% bundledir=$ANTIDOTE_HOME/fakegitsite.com/dino/saur
% stable_sha=$(command git -C $bundledir rev-list --before="200 days ago" -1 origin/main)
% [[ "$(command git -C $bundledir rev-parse HEAD)" == "$stable_sha" ]] && echo "at qualifying commit"
at qualifying commit
% [[ "$(command git -C $bundledir rev-parse HEAD)" != "$(command git -C $bundledir rev-parse origin/main)" ]] && echo "not at latest"
not at latest
%
```

## Update: min-age limits advancement

Full history is available from the clone above. Roll back to initial, then update
with min-age=200. Should advance to stable but not to latest.

```zsh
% command git -C $bundledir reset --quiet --hard HEAD~1
% initial_sha=$(command git -C $bundledir rev-parse HEAD)
% antidote update --bundles &>/dev/null
% stable_sha=$(command git -C $bundledir rev-list --before="200 days ago" -1 origin/main)
% [[ "$(command git -C $bundledir rev-parse HEAD)" == "$stable_sha" ]] && echo "advanced to qualifying commit"
advanced to qualifying commit
% [[ "$(command git -C $bundledir rev-parse HEAD)" != "$(command git -C $bundledir rev-parse origin/main)" ]] && echo "not at latest"
not at latest
%
```

## Dry run: min-age shows qualifying commit without applying

```zsh
% command git -C $bundledir reset --quiet --hard HEAD~1
% sha_before=$(command git -C $bundledir rev-parse HEAD)
% antidote update --bundles --dry-run &>/dev/null
% [[ "$(command git -C $bundledir rev-parse HEAD)" == "$sha_before" ]] && echo "no change"
no change
%
```

## Update: no qualifying commits warns and skips

After the dry run, local is still at initial (~900d old). With min-age=9999, nothing qualifies.

```zsh
% zstyle ':antidote:bundle:dino/saur' min-age 9999
% sha_before=$(command git -C $bundledir rev-parse HEAD)
% antidote update --bundles 2>&1 | grep "saur"
antidote: checking for updates: dino/saur
antidote: dino/saur: no commits older than 9999 days, skipping update
% [[ "$(command git -C $bundledir rev-parse HEAD)" == "$sha_before" ]] && echo "no change"
no change
%
```

## Clone: negative min-age treated as absolute value

min-age=-200 should behave the same as min-age=200.

```zsh
% antidote purge dino/saur &>/dev/null
% zstyle ':antidote:bundle:dino/saur' min-age -200
% antidote bundle 'dino/saur kind:clone' &>/dev/null
% stable_sha=$(command git -C $bundledir rev-list --before="200 days ago" -1 origin/main)
% [[ "$(command git -C $bundledir rev-parse HEAD)" == "$stable_sha" ]] && echo "at qualifying commit"
at qualifying commit
%
```

## Clone: min-age=0 clones normally (no min-age logic)

```zsh
% antidote purge dino/saur &>/dev/null
% zstyle ':antidote:bundle:dino/saur' min-age 0
% antidote bundle 'dino/saur kind:clone' &>/dev/null
% latest_sha=$(command git -C $bundledir rev-parse origin/main)
% [[ "$(command git -C $bundledir rev-parse HEAD)" == "$latest_sha" ]] && echo "at latest"
at latest
%
```

## Teardown

```zsh
% t_teardown
%
```

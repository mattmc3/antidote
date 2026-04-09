# antidote pin annotation tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
%
```

## Pin annotation

The pintest/pinme fixture has three commits:
- v1.0.0 (`64642c5...`) — initial good version
- v1.1.0 (`c87216c...`) — minor update, also good
- v1.2.0 (`d54e0ca...`) — bad supply chain commit (HEAD)

Pinning lets users lock to a known-good commit and avoid the bad HEAD.

### Clone with pin (SHA)

Pin to v1.0.0 to avoid the bad HEAD. Verify detached HEAD state and git config.

```zsh
% antidote bundle 'pintest/pinme pin:64642c5691051ba0d82f5bda60b745f6fd042325' >/dev/null
# antidote cloning pintest/pinme...
% bundledir=$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme
% git -C $bundledir rev-parse HEAD
64642c5691051ba0d82f5bda60b745f6fd042325
% git -C $bundledir rev-parse --abbrev-ref HEAD
HEAD
% git -C $bundledir config --get antidote.pin
64642c5691051ba0d82f5bda60b745f6fd042325
%
```

### Pin produces correct script output

The pinned bundle should still generate the correct source script.

```zsh
% antidote __private__ zsh_script __bundle__ pintest/pinme pin 64642c5691051ba0d82f5bda60b745f6fd042325 | subenv ANTIDOTE_HOME
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme" )
source "$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme/pinme.plugin.zsh"
%
```

### Update skips pinned bundles

```zsh
% zstyle ':antidote:test:version' show-sha off
% zstyle ':antidote:test:git' autostash off
% antidote update --bundles 2>&1 | grep pintest
antidote: skipping update for pinned bundle: pintest/pinme (at 64642c5...)
%
```

### Advance pin to v1.1.0

Change the pin to the v1.1.0 commit — a newer known-good version.

```zsh
% antidote bundle 'pintest/pinme pin:c87216c18d3f0301fa1ed669b6c1ad76056271ca' >/dev/null
% git -C $bundledir config --get antidote.pin
c87216c18d3f0301fa1ed669b6c1ad76056271ca
% git -C $bundledir rev-parse HEAD
c87216c18d3f0301fa1ed669b6c1ad76056271ca
%
```

### Removing pin clears git config and returns to a branch

When a bundle is re-bundled without `pin:`, the git config should be cleared
and the repo should return to a branch so `antidote update` can pull.

Currently pinned to v1.1.0:

```zsh
% git -C $bundledir config --get antidote.pin
c87216c18d3f0301fa1ed669b6c1ad76056271ca
% git -C $bundledir rev-parse HEAD
c87216c18d3f0301fa1ed669b6c1ad76056271ca
%
```

Remove the pin:

```zsh
% antidote bundle 'pintest/pinme' >/dev/null
% git -C $bundledir config --get antidote.pin  #=> --exit 1
% git -C $bundledir rev-parse --abbrev-ref HEAD
main
%
```

Update pulls to the latest (v1.2.0) — the bad commit we were previously avoiding:

```zsh
% zstyle ':antidote:test:version' show-sha off
% zstyle ':antidote:test:git' autostash off
% antidote update --bundles 2>&1 | grep pintest | grep -c "skipping"
0
% git -C $bundledir rev-parse HEAD
d54e0cad999d196822584f2cca72f7c7bd908ea9
%
```

### Re-add pin to v1.0.0

Re-bundling with a pin should checkout the pinned commit and set the git config.

```zsh
% antidote bundle 'pintest/pinme pin:64642c5691051ba0d82f5bda60b745f6fd042325' >/dev/null
% git -C $bundledir config --get antidote.pin
64642c5691051ba0d82f5bda60b745f6fd042325
% git -C $bundledir rev-parse --abbrev-ref HEAD
HEAD
%
```

### Short SHA is rejected

Pin requires a full 40-character commit SHA. Short SHAs are rejected with a
clear error because the git protocol cannot resolve them on remotes.

```zsh
% antidote bundle 'pintest/pinme pin:64642c5' 2>&1 | tail -1
# antidote: error: pin requires a full 40-character commit SHA, got '64642c5'
%
```

### Fresh clone pinned to v1.1.0

Purge and re-clone pinned to the v1.1.0 known-good commit.

```zsh
% zstyle ':antidote:test:purge' answer 'y'
% antidote purge pintest/pinme >/dev/null
% [[ ! -d $bundledir ]] && echo "purged"
purged
% antidote bundle 'pintest/pinme pin:c87216c18d3f0301fa1ed669b6c1ad76056271ca' >/dev/null
# antidote cloning pintest/pinme...
% git -C $bundledir rev-parse HEAD
c87216c18d3f0301fa1ed669b6c1ad76056271ca
% git -C $bundledir config --get antidote.pin
c87216c18d3f0301fa1ed669b6c1ad76056271ca
%
```

### List shows pinned bundles

```zsh
% antidote list --long | grep -A4 'Repo:.*pintest/pinme'
Repo:   pintest/pinme
Path:   $HOME/.cache/antidote/fakegitsite.com/pintest/pinme
URL:    https://fakegitsite.com/pintest/pinme
SHA:    c87216c18d3f0301fa1ed669b6c1ad76056271ca
Pinned: c87216c18d3f0301fa1ed669b6c1ad76056271ca
%
```

JSONL includes pin field for pinned bundles:

```zsh
% antidote list --jsonl | subenv ANTIDOTE_HOME | grep pintest
{"url":"https://fakegitsite.com/pintest/pinme","repo":"pintest/pinme","path":"$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme","sha":"c87216c18d3f0301fa1ed669b6c1ad76056271ca","pin":"c87216c18d3f0301fa1ed669b6c1ad76056271ca"}
%
```

Unpinned bundles don't show Pinned in long output:

```zsh
% antidote list --long | grep -A4 'Repo:.*foo/bar' | grep -c 'Pinned:'
0
%
```

### Sequential pin updates with kind:clone

Walk through all three pintest/pinme SHAs in sequence, verifying the repo
checks out the correct commit each time.

```zsh
% rm -rf $ANTIDOTE_HOME/fakegitsite.com/pintest/pinme
%
```

Pin to v1.0.0 (initial good commit):

```zsh
% antidote bundle 'pintest/pinme kind:clone pin:64642c5691051ba0d82f5bda60b745f6fd042325' 2>&1
# antidote cloning pintest/pinme...
% git -C $bundledir rev-parse HEAD
64642c5691051ba0d82f5bda60b745f6fd042325
%
```

Advance to v1.1.0 (newer good commit):

```zsh
% antidote bundle 'pintest/pinme kind:clone pin:c87216c18d3f0301fa1ed669b6c1ad76056271ca'
% git -C $bundledir rev-parse HEAD
c87216c18d3f0301fa1ed669b6c1ad76056271ca
%
```

Advance to v1.2.0 (the bad commit — for testing, not recommended):

```zsh
% antidote bundle 'pintest/pinme kind:clone pin:d54e0cad999d196822584f2cca72f7c7bd908ea9'
% git -C $bundledir rev-parse HEAD
d54e0cad999d196822584f2cca72f7c7bd908ea9
%
```

Roll back to v1.0.0 to confirm we can move backwards:

```zsh
% antidote bundle 'pintest/pinme kind:clone pin:64642c5691051ba0d82f5bda60b745f6fd042325'
% git -C $bundledir rev-parse HEAD
64642c5691051ba0d82f5bda60b745f6fd042325
%
```

### Branch annotation with a tag

Tags should work with `branch:` the same as branch names.

```zsh
% rm -rf $ANTIDOTE_HOME/fakegitsite.com/pintest/pinme
% antidote bundle 'pintest/pinme branch:v1.0.0' >/dev/null
# antidote cloning pintest/pinme...
% bundledir=$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme
% git -C $bundledir rev-parse HEAD
64642c5691051ba0d82f5bda60b745f6fd042325
%
```

### Pin with invalid SHA fails and cleans up

```zsh
% rm -rf $ANTIDOTE_HOME/fakegitsite.com/pintest/pinme
% antidote __private__ zsh_script __bundle__ pintest/pinme kind clone pin deadbeefdeadbeefdeadbeefdeadbeefdeadbeef 2>&1 | tail -1
antidote: error: pin commit 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef' not found for pintest/pinme
% [[ ! -d $ANTIDOTE_HOME/fakegitsite.com/pintest/pinme ]] && echo "cleaned up"
cleaned up
%
```

### Pin with short or non-SHA value is rejected

```zsh
% antidote __private__ zsh_script __bundle__ pintest/pinme kind clone pin v99.0.0 2>&1 | tail -1
antidote: error: pin requires a full 40-character commit SHA, got 'v99.0.0'
% [[ ! -d $ANTIDOTE_HOME/fakegitsite.com/pintest/pinme ]] && echo "cleaned up"
cleaned up
%
```

### Conflict detection

Test `bundle_check_critical` directly.

Conflicting pins should fail.

```zsh
% printf 'pintest/pinme pin:aaa\npintest/pinme pin:bbb\n' | antidote __private__ bundle_check_critical 2>&1
# antidote: critical error on line 2: conflicting pin for 'pintest/pinme': pin:bbb vs pin:aaa
%
```

Conflicting branches should fail.

```zsh
% printf 'foo/bar branch:main\nfoo/bar branch:dev\n' | antidote __private__ bundle_check_critical 2>&1
# antidote: critical error on line 2: conflicting branch for 'foo/bar': branch:dev vs branch:main
%
```

Mixed pin/no-pin for the same repo should fail.

```zsh
% printf 'pintest/pinme pin:aaa\npintest/pinme path:lib\n' | antidote __private__ bundle_check_critical 2>&1
# antidote: critical error on line 2: inconsistent pin for 'pintest/pinme': some entries have pin:aaa, others do not
%
```

Mixed branch/no-branch for the same repo should fail.

```zsh
% printf 'foo/bar branch:dev\nfoo/bar path:lib\n' | antidote __private__ bundle_check_critical 2>&1
# antidote: critical error on line 2: inconsistent branch for 'foo/bar': some entries have branch:dev, others do not
%
```

Identical pins for the same repo should be fine.

```zsh
% printf 'pintest/pinme pin:aaa\npintest/pinme pin:aaa path:lib\n' | antidote __private__ bundle_check_critical  #=> --exit 0
%
```

Different repos with different pins should be fine.

```zsh
% printf 'foo/bar pin:aaa\npintest/pinme pin:bbb\n' | antidote __private__ bundle_check_critical  #=> --exit 0
%
```

Bundling with conflicting pins should also fail end-to-end.

```zsh
% printf 'pintest/pinme pin:aaa path:lib\npintest/pinme pin:bbb path:other\n' | antidote bundle 2>&1 | tail -1
# antidote: critical error on line 2: conflicting pin for 'pintest/pinme': pin:bbb vs pin:aaa
%
```

## Teardown

```zsh
% t_teardown
%
```

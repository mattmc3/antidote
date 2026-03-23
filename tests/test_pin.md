# antidote pin annotation tests

## Setup

```zsh
% source ./tests/__init__.zsh
% t_setup
% antidote bundle <$ZDOTDIR/.base_test_fixtures.txt &>/dev/null
%
```

## Pin annotation

### Clone with pin (SHA)

Cloning a bundle with `pin:` should clone at the pinned commit SHA.

```zsh
% antidote bundle 'pintest/pinme pin:64642c5691051ba0d82f5bda60b745f6fd042325' >/dev/null
# antidote cloning pintest/pinme...
%
```

Verify the repo is in detached HEAD state at the pinned SHA.

```zsh
% bundledir=$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme
% git -C $bundledir rev-parse HEAD
64642c5691051ba0d82f5bda60b745f6fd042325
% git -C $bundledir rev-parse --abbrev-ref HEAD
HEAD
%
```

Verify git config has the pin stored.

```zsh
% git -C $bundledir config --get antidote.pin
64642c5691051ba0d82f5bda60b745f6fd042325
%
```

### Pin produces correct script output

The pinned bundle should still generate the correct source script.

```zsh
% antidote __private__ zsh_script --pin 64642c5691051ba0d82f5bda60b745f6fd042325 pintest/pinme | subenv ANTIDOTE_HOME
fpath+=( "$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme" )
source "$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme/pinme.plugin.zsh"
%
```

### Update skips pinned bundles

```zsh
% zstyle ':antidote:test:version' show-sha off
% zstyle ':antidote:test:git' autostash off
% antidote update --bundles 2>&1 | grep pintest
antidote: skipping update for pinned bundle: pintest/pinme (at 64642c5691051ba0d82f5bda60b745f6fd042325)
%
```

### Removing pin clears git config

When a bundle is re-bundled without `pin:`, the git config should be cleared
so that `antidote update` will no longer skip it.

```zsh
% antidote bundle 'pintest/pinme' >/dev/null
% git -C $bundledir config --get antidote.pin  #=> --exit 1
%
```

### Adding pin to an already-cloned unpinned bundle

The bundle was unpinned above. Re-bundling with a pin should checkout the pinned
commit and set the git config.

```zsh
% antidote bundle 'pintest/pinme pin:64642c5691051ba0d82f5bda60b745f6fd042325' >/dev/null
% git -C $bundledir config --get antidote.pin
64642c5691051ba0d82f5bda60b745f6fd042325
% git -C $bundledir rev-parse --abbrev-ref HEAD
HEAD
%
```

### List shows pinned bundles

```zsh
% antidote list --short-name --pinned | subenv ANTIDOTE_HOME | grep pintest
$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme	pintest/pinme	64642c5691051ba0d82f5bda60b745f6fd042325
%
```

JSONL includes pin field:

```zsh
% antidote list --jsonl --pinned | subenv ANTIDOTE_HOME | grep pintest
{"url":"https://fakegitsite.com/pintest/pinme","short_name":"pintest/pinme","type":"repo","path":"$ANTIDOTE_HOME/fakegitsite.com/pintest/pinme","sha":"64642c5691051ba0d82f5bda60b745f6fd042325","pin":"64642c5691051ba0d82f5bda60b745f6fd042325"}
%
```

Unpinned bundles show "unpinned":

```zsh
% antidote list --short-name --pinned | subenv ANTIDOTE_HOME | grep foo/bar
$ANTIDOTE_HOME/fakegitsite.com/foo/bar	foo/bar	unpinned
%
```

### Changing pin SHA on existing bundle

Changing the pin to a different SHA should checkout the new commit.

```zsh
% antidote bundle 'pintest/pinme pin:c87216c18d3f0301fa1ed669b6c1ad76056271ca' >/dev/null
% git -C $bundledir config --get antidote.pin
c87216c18d3f0301fa1ed669b6c1ad76056271ca
% git -C $bundledir rev-parse HEAD
c87216c18d3f0301fa1ed669b6c1ad76056271ca
%
```

### Sequential pin updates with kind:clone

Walk through all three pintest/pinme SHAs in sequence, verifying the repo
checks out the correct commit each time.

```zsh
% rm -rf $ANTIDOTE_HOME/fakegitsite.com/pintest/pinme
%
```

Pin to v1.1.0 (oldest commit):

```zsh
% antidote bundle 'pintest/pinme kind:clone pin:c87216c18d3f0301fa1ed669b6c1ad76056271ca' 2>&1
# antidote cloning pintest/pinme...
% git -C $bundledir rev-parse HEAD
c87216c18d3f0301fa1ed669b6c1ad76056271ca
%
```

Change pin to v1.0.0 (middle commit):

```zsh
% antidote bundle 'pintest/pinme kind:clone pin:64642c5691051ba0d82f5bda60b745f6fd042325'
% git -C $bundledir rev-parse HEAD
64642c5691051ba0d82f5bda60b745f6fd042325
%
```

Change pin to v1.2.0 (latest commit):

```zsh
% antidote bundle 'pintest/pinme kind:clone pin:d54e0cad999d196822584f2cca72f7c7bd908ea9'
% git -C $bundledir rev-parse HEAD
d54e0cad999d196822584f2cca72f7c7bd908ea9
%
```

Go back to v1.1.0 to confirm we can move backwards:

```zsh
% antidote bundle 'pintest/pinme kind:clone pin:c87216c18d3f0301fa1ed669b6c1ad76056271ca'
% git -C $bundledir rev-parse HEAD
c87216c18d3f0301fa1ed669b6c1ad76056271ca
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
% antidote __private__ zsh_script --kind clone --pin deadbeefdeadbeefdeadbeefdeadbeefdeadbeef pintest/pinme 2>&1 | tail -1
antidote: error: pin commit 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef' not found for pintest/pinme
% [[ ! -d $ANTIDOTE_HOME/fakegitsite.com/pintest/pinme ]] && echo "cleaned up"
cleaned up
%
```

### Pin with invalid short ref fails and cleans up

```zsh
% antidote __private__ zsh_script --kind clone --pin v99.0.0 pintest/pinme 2>&1 | tail -1
antidote: error: pin commit 'v99.0.0' not found for pintest/pinme
% [[ ! -d $ANTIDOTE_HOME/fakegitsite.com/pintest/pinme ]] && echo "cleaned up"
cleaned up
%
```

### Conflict detection

Test `bundle_check_conflicts` directly.

Conflicting pins should fail.

```zsh
% printf 'pintest/pinme pin:aaa\npintest/pinme pin:bbb\n' | antidote __private__ bundle_check_conflicts 2>&1
antidote: error: conflicting pin for 'pintest/pinme': pin:bbb vs pin:aaa
%
```

Conflicting branches should fail.

```zsh
% printf 'foo/bar branch:main\nfoo/bar branch:dev\n' | antidote __private__ bundle_check_conflicts 2>&1
antidote: error: conflicting branch for 'foo/bar': branch:dev vs branch:main
%
```

Mixed pin/no-pin for the same repo should fail.

```zsh
% printf 'pintest/pinme pin:aaa\npintest/pinme path:lib\n' | antidote __private__ bundle_check_conflicts 2>&1
antidote: error: inconsistent pin for 'pintest/pinme': some entries have pin:aaa, others do not
%
```

Mixed branch/no-branch for the same repo should fail.

```zsh
% printf 'foo/bar branch:dev\nfoo/bar path:lib\n' | antidote __private__ bundle_check_conflicts 2>&1
antidote: error: inconsistent branch for 'foo/bar': some entries have branch:dev, others do not
%
```

Identical pins for the same repo should be fine.

```zsh
% printf 'pintest/pinme pin:aaa\npintest/pinme pin:aaa path:lib\n' | antidote __private__ bundle_check_conflicts  #=> --exit 0
%
```

Different repos with different pins should be fine.

```zsh
% printf 'foo/bar pin:aaa\npintest/pinme pin:bbb\n' | antidote __private__ bundle_check_conflicts  #=> --exit 0
%
```

Bundling with conflicting pins should also fail end-to-end.

```zsh
% printf 'pintest/pinme pin:aaa path:lib\npintest/pinme pin:bbb path:other\n' | antidote bundle 2>&1 | tail -1
antidote: error: conflicting pin for 'pintest/pinme': pin:bbb vs pin:aaa
%
```

## Teardown

```zsh
% t_teardown
%
```

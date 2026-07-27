# `antidote pin` subcommand design

Issue: [#261](https://github.com/mattmc3/antidote/issues/261), "Consider a pin
subcommand".

Status: implemented.

## The one-sentence definition

`antidote pin` **resolves every bundle's pin to a concrete 40-char SHA** and prints the
bundle lines back out. It does not touch git working trees, git config, or the static load
script.

That one rule covers all of it:

| Input line | Output line |
| --- | --- |
| `foo/bar` | `foo/bar pin:<sha of the current checkout>` |
| `foo/bar pin:v1.2.0` | `foo/bar pin:<sha that tag points at>` |
| `foo/bar pin:abc1234` | `foo/bar pin:<full 40-char sha>` |
| `foo/bar` with `--as-of <date>` | `foo/bar pin:<newest sha at or before date>` |
| `foo/bar pin:<40-char sha>` | unchanged, unless `--force` |

Everything below follows from that. If it drifts from that definition, the feature is out
of scope.

## Challenges to the proposal in the issue

### 1. Same input contract as `antidote bundle`

The shape from the issue is a trap, but only because of where the output goes:

```zsh
# THIS DELETES YOUR PLUGINS FILE
antidote pin --as-of=2026-07-01 <$ZDOTDIR/.zsh_plugins.txt >$ZDOTDIR/.zsh_plugins.txt
```

The shell truncates the `>` target while setting up redirections, before antidote ever
reads stdin. `antidote bundle <in >out` is safe only because in and out are different
files.

The input side is right, though, and should be identical to `antidote bundle`: bundle lines
as arguments, or bundle text on stdin. `collect_input` already implements exactly that
contract, so `pin` reuses it and gains no new input code.

```zsh
antidote pin ohmyzsh/ohmyzsh kind:clone   # -> ohmyzsh/ohmyzsh kind:clone pin:<sha>
cat plugins.txt | antidote pin            # -> every bundle in the file, pinned
antidote pin <$bundle_file >pinned.txt
```

One deviation from `antidote bundle`, which fails on empty input: with no arguments and
nothing on stdin, `pin` falls back to `$_ANTIDOTE_BUNDLE_FILE`, the `:antidote:bundle file`
zstyle. That is what makes a bare `antidote pin` and `-i` useful. Full resolution order:

1. Positional bundle arguments.
2. stdin, when it is not a tty.
3. `--file <path>`.
4. `$_ANTIDOTE_BUNDLE_FILE`.

The output side is where the fix goes, following `sed`: **stdout by default, `-i` to
rewrite the source file in place** with a timestamped `.bak`. Not a `--dry-run` flag,
because printing the rewritten file is not a rehearsal of the real thing, it **is** the
thing.

```zsh
antidote pin | diff -u ~/.zsh_plugins.txt -   # review first
antidote pin -i                               # then apply
```

`-i` needs a real file to write back to, so it works only with `--file` or the default
plugins file. It is an error with stdin input or positional bundles.

Two guards, because stdin input keeps `<$f >$f` within reach:

- When the input path and stdout are the same file (Zsh `[[ /dev/fd/1 -ef $bundlefile ]]`),
  die with "refusing to read and write the same file, use -i". The shell already truncated
  it by then, so this converts a silent empty-file disaster into a clear message, which is
  the most that can be done from inside the process.
- That guard cannot see a stream, so a `<in >out` redirect onto the same path is
  undetectable. `-i` is therefore the documented answer, and no example ever redirects `>`
  onto a plugins file.

### 2. Bundle file vs git config: the issue's actual open question

The issue asks what happens with `antidote pin --unpin ohmyzsh/ohmyzsh` when the bundle
file still has a pin, "or vice-versa". That ambiguity only exists if `pin` mutates git
state. It must not.

- The bundle file is the **source of truth**.
- The per-repo `antidote.pin` git config is a **derived cache**, owned by `antidote
  bundle`.
- `unpin` deletes the `pin:` annotation from the line, and nothing else. The next `antidote
  bundle` or `antidote load` sees no pin, and the existing pin-removed path in
  `zsh_script_clone` unsets `antidote.pin` and checks the repo back onto its branch.

So there is no new sync logic, no new conflict class, and no drift that does not already
exist today. `pin` is text transformation, `bundle` is state reconciliation. Keep them
separate.

Corollary: `pin` does **not** regenerate the static `.zsh_plugins.zsh`. It prints a
reminder to re-run the bundle step.

### 3. Do not write a date parser

`--as-of` should pass its argument straight to `git rev-list --before=`. Git's approxidate
already accepts everything asked for and more:

```
now, yesterday, "2 weeks ago", 2026-07-01, "last monday", @1750000000
```

There is precedent in the codebase: `git_min_age_sha` is exactly this call with a
`"N days ago"` string. `--as-of` is its generalization. Zero new date code.

Invalid dates are the catch: git treats an unparseable approxidate as "now" rather than
erroring. So validate first, either with `git rev-parse --verify` style probing or by
comparing `git rev-list -1 --before="$asof"` against `--before=now` and rejecting strings
git silently swallowed. Cheap check, must not be skipped.

### 4. `--as-of` is offline for most bundles, because clones already deepen

`--depth 1` is the starting state, not the resting state. `zsh_script_clone` fires a
disowned `git_unshallow_try` right after the clone, and `antidote update` catches up
anything still shallow with `git_is_shallow` plus `git_unshallow_try`, falling back to a
plain fetch. A normal, unpinned, updated bundle therefore has full history on disk, and
`rev-list --before` answers locally with no network at all.

Only two classes are still shallow when `pin` runs:

1. **Bundles cloned with a pin.** The pin branch of `zsh_script_clone` skips the deepen,
   since a pin already fixes the commit, and `antidote update` skips pinned bundles, so
   nothing ever catches them up. This is exactly the `--force --as-of` case: re-dating a
   file that is already pinned.
2. **Bundles held shallow on purpose**, via `zstyle ':antidote:bundle:<repo>' shallow
   yes`.

Handling mirrors what `antidote_update` already does: `git_is_shallow`, then
`git_unshallow_try`, the best-effort quiet variant, not `git_unshallow`. A `shallow yes`
bundle gets a warn-and-skip rather than a silent override of the user's own config. A
failed deepen is a warn-and-skip too, with the same exit semantics as any other
unresolvable bundle.

That is why `--as-of` needed its own phase: date validation, branch-aware ref selection,
and per-bundle deepen fallbacks. Not because it is inherently a network operation.

### 5. Overlap with features that already exist

| Existing | What it does | Why `pin` is still distinct |
| --- | --- | --- |
| `snapshot save` and `restore` | Writes `repo kind:clone pin:<sha>` to a timestamped side file. Restore is **ephemeral** (`ANTIDOTE_EPHEMERAL_PIN`): no git config, no file edit | Snapshots are backups to roll back to. Pins are durable, in-repo, and reviewable in dotfiles commit history |
| `min-age` zstyle | Rolling "stay N days behind upstream", re-evaluated every run | A pin is a one-time freeze at an exact commit |
| `install --pin <sha>` | Adds one new bundle with a pin | `pin` resolves pins for bundles already in the file, in bulk |

If those boundaries stop being crisp, the feature should not ship. They are crisp today, so
it should.

A bonus falls out for free: a snapshot file is already bundle lines with pins, so `antidote
pin <snapshot.txt` promotes an ephemeral snapshot into durable pins with no new code at
all.

### 6. Rejected alternative: a lockfile

`.zsh_plugins.lock`, npm style, is the obvious other design. Reject it. The `pin:`
annotation already exists, is already honored by `bundle_parser` and `antidote bundle`, and
already round-trips through `install` and `snapshot`. A second file means two sources of
truth, merge conflicts in dotfiles, and a new format to document. Annotations win.

## Flag naming

| Proposed | Recommendation | Why |
| --- | --- | --- |
| `--as-of=<date>` | **keep `--as-of`** | Self-documenting, no collision. `--before` is more git-idiomatic and would be a fine alternative. `--date` is ambiguous (author vs commit vs format) and `--at` reads like a commit-ish |
| `--repin` | **use `-f`, `--force`** | "Repin" is jargon and has no natural inverse. `--force` is the idiom for overwriting what is already there, and stays orthogonal to `--as-of`. See below |
| `--unpin` | **separate `antidote unpin`**, see below | |
| n/a | `-i`, `--in-place` | The `sed` spelling. Replaces the `--dry-run` idea entirely: stdout is the default, mutation is the flag |
| n/a | `--file <path>` | Read a non-default plugins file. Only needed because the positional slot holds bundles |

No `--dry-run`. Running without `-i` already shows exactly what would be written, because
it writes it.

No `-b`/`--bundle` filter. Bundles are the positional arguments, exactly as in `antidote
bundle`.

### Explicit refs use the `pin:` annotation

A ref is named with antidote's own annotation grammar, not a new `@ref` suffix:

```zsh
antidote pin ohmyzsh/ohmyzsh pin:v1.2.0     # tag
antidote pin ohmyzsh/ohmyzsh pin:abc1234    # short SHA
antidote pin ohmyzsh/ohmyzsh pin:some-branch
```

Resolution is `git rev-parse --verify "<ref>^{commit}"` inside the clone, which handles
tags, branches, and short SHAs in one call. When the object is missing from a shallow
clone, fetch it the way `git_checkout_pin` already does before giving up.

This is what makes the whole feature cohere. Today `pin:v1.2.0` is a hard error, since
`zsh_script` demands 40 characters. With a `pin` subcommand, a loose ref becomes valid
*input* that gets resolved into a strict pin, so a human can write `pin:v1.2.0` in their
plugins file and let antidote turn it into something reproducible. No new grammar, no
ssh-url `@` collision, and it round-trips with `install --pin` and snapshot files.

Two consequences worth stating:

- **A loose pin is always resolved, with or without `--force`.** Leaving it alone would
  leave the file in a state `antidote bundle` rejects. `--force` governs overwriting *valid*
  40-char pins only.
- **An explicit `pin:` on a bundle argument beats `--as-of`.** The user named a commit, so
  the date does not apply to that bundle.

### Why `--force` is separate from `--as-of`

`--force` means one thing only: **overwrite pins that are already valid**. It never selects
which SHA to write, so it composes with `--as-of` instead of overlapping it.

| Invocation | Effect |
| --- | --- |
| `pin` | Fill in missing pins, resolve loose ones. Valid pins untouched |
| `pin --force` | Also re-resolve valid pins, from the checked-out SHA |
| `pin --as-of <date>` | Fill in missing pins with the commit as of `<date>`. Valid pins untouched |
| `pin --force --as-of <date>` | Re-date every bundle, pinned or not |

Keeping the two apart matters because the alternative is `--as-of` quietly meaning
"overwrite" whenever a line happens to already be pinned. That is one flag with two
behaviors, decided by state the user cannot see in the command they typed. Destroying an
existing pin should require saying so.

`--force` without a date is not a no-op, which is worth spelling out because it looks like
one. `bundle_sync_pins` does force the checkout to match the `pin:` line, so **after** an
`antidote bundle` run the two agree and re-resolving reproduces the same SHA. The cases
where they disagree are the ones that matter:

- A `pin:` line hand-edited, or written by a teammate, or produced on another machine,
  before any `bundle` run has reconciled it. `--force` rewrites it from what is actually
  cloned.
- After `snapshot restore`, which checks out the snapshot SHA ephemerally and deliberately
  writes no pin. Lines carrying no pin get promoted by plain `pin`. Lines already carrying
  one need `--force`.

Advancing pins forward is `pin --force --as-of now`, which replaces the otherwise awkward
unpin, update, re-pin dance. That is why `--as-of` has to accept `now`.

### `pin --unpin` vs `antidote unpin`

Two shapes, both defensible.

**A. Flag on pin**, `antidote pin --unpin <bundle>...`. One subcommand, one man page, one
completion block. But every other flag becomes conditionally invalid (`--unpin --as-of` is
nonsense, `--unpin --force` is meaningless), so the implementation is a pile of "flag X is
invalid with Y" guards and the help text has to explain two modes.

**B. Sibling commands**, `antidote pin` and `antidote unpin`. Chosen. Each has a coherent
flag set. `unpin` takes only `-i`, `--file`, and bundle positionals, implemented as a thin
wrapper over the same rewriter with `mode=unpin`. Costs one extra man page and one
completion entry. Unpinning is a distinct user intent, deserves a distinct verb, and is
easier to discover.

## CLI

```
antidote pin [-h|--help] [-i|--in-place] [-f|--force]
             [--as-of <date>] [--file <path>] [<bundle>...]

antidote unpin [-h|--help] [-i|--in-place] [--file <path>] [<bundle>...]
```

Output is bundle lines on stdout, or the source file rewritten with `-i`. All summaries,
warnings, and the re-run reminder go to **stderr**, since stdout is destined to become a
plugins file.

Examples:

```zsh
# whole file
antidote pin                                   # print the pinned file, no network
antidote pin | diff -u ~/.zsh_plugins.txt -    # review the change
antidote pin -i                                # apply it, with a .bak
antidote pin -i -f                             # re-resolve pins from what is cloned
antidote pin -i -f --as-of "2 weeks ago"       # roll the whole file back two weeks
antidote pin -i -f --as-of now                 # advance every pin to current upstream
antidote pin -i --file ~/.dotfiles/.zsh_plugins.txt

# single bundles
antidote pin ohmyzsh/ohmyzsh                   # -> ohmyzsh/ohmyzsh pin:<sha>
antidote pin ohmyzsh/ohmyzsh kind:clone        # annotations preserved
antidote pin ohmyzsh/ohmyzsh pin:v1.2.0        # resolve a tag to a sha
antidote pin foo/bar pin:abc1234               # expand a short sha

# streams
cat plugins.txt | antidote pin >pinned.txt
antidote pin <$ZDOTDIR/.zsh_plugins.txt | grep -c pin:

# unpin
antidote unpin -i                              # drop every pin
antidote unpin -i ohmyzsh/ohmyzsh              # drop one pin, back to tracking branch
```

## Implementation

### Reuse the parser, rewrite by line number

`bundle_parser` already records `__lineno__`, `__dir__`, `__type__`, `__short__`, and any
existing `pin` per entry. That is everything the rewriter needs, so no second parser gets
written.

```
antidote_pin()  # antidote.zsh, ##### PINS section
  1. zparseopts flags
     input = collect_input "$@"          # bundle args, else stdin
     input empty -> read --file, else $_ANTIDOTE_BUNDLE_FILE
     -i without a file source            -> die
     source file -ef /dev/fd/1           -> die "refusing to read and write the same file"
  2. keep the raw input lines in an array
  3. bundle_parser on the same text
  4. refuse to rewrite if _parsed_bundles[__has_errors__]  # no round-trip guarantee
  5. for each entry i:
       skip unless __type__ is repo|url|ssh_url
       pin valid 40-char sha and no --force  -> skip
       resolve the sha (see below), memoized per __dir__
       record edit: lineno -> new line text
  6. apply edits to the raw line array (see rewrite rules)
  7. no -i: print the array to stdout
     -i:    write tmpfile, mv source to <name>.<ts>.bak, mv tmpfile into place
  8. summary to stderr: N pinned, M skipped, "re-run antidote bundle to apply"
```

`antidote_unpin` is the same function in unpin mode, with `mode` set from the dispatch
name: it clears `pin:` instead of resolving it, and rejects `-f` and `--as-of`.

### SHA resolution

```
pin_resolve_sha <dir> <bname> <existing-pin> [<asof>]
  dir missing           -> return 1  (never clone; see scope)
  existing pin is loose -> git rev-parse --verify "${pin}^{commit}"
                           miss -> git_fetch --depth 1 origin "$pin", retry
                           still miss -> warn, skip this bundle
  --as-of given         -> if git_is_shallow:
                             zstyle -t ":antidote:bundle:$bname" shallow
                               -> warn "held shallow by config", skip
                             git_unshallow_try || { warn; skip }
                           ref = origin/<branch annotation> or origin/HEAD
                           git rev-list -1 --before="$asof" "$ref"
                           empty -> warn, skip this bundle
  otherwise             -> git_config_get "$dir" antidote.pin, else git_sha "$dir"
```

Precedence per bundle: an explicit loose `pin:` beats `--as-of`, which beats the current
checkout.

Most bundles never reach the shallow branch, since they were deepened at clone time or by
`antidote update`. Pinned ones re-resolved under `--force`, and `shallow yes` ones, are the
exceptions.

Always writes a full 40-char SHA, which is what `zsh_script` already requires of a `pin:`
annotation.

### Rewrite rules, where the bugs will be

1. **Inline comments.** `bundle_parser` stops at the first `#` word, so `foo/bar
   kind:fpath  # my prompt` must become `foo/bar kind:fpath pin:<sha>  # my prompt`. A naive
   append to end of line puts the pin inside the comment.
2. **Existing `pin:` word.** Replace it in place, keeping annotation order and surrounding
   whitespace. Do not reflow the line. This covers both `--force` and loose-ref expansion.
3. **Everything else byte-for-byte.** Comments, blank lines, ordering, indentation, and
   quoting all survive untouched. Only edited lines change.
4. **Line endings.** `bundle_parser` normalizes CRLF for parsing, so the rewriter has to
   read raw and preserve per-line endings, inserting before a trailing `\r`.
5. **`using:` blocks.** Annotations on a `using:` line propagate to every bare-word
   subplugin under it, via `_antidote_using_context` and `expand_using_subplugin`. Pin the
   `using:` line, not the subplugin lines. That is already how inheritance works, so it
   costs nothing and avoids N redundant identical pins.
6. **Repos with multiple entries.** `ohmyzsh/ohmyzsh path:plugins/git` and `path:plugins/z`
   share one `__dir__`. Every line for that dir must get the same SHA, or
   `check_pin_branch_conflicts` rightly rejects the file as critical. Memoizing resolution
   per `__dir__` makes that automatic.
7. **Non-repo bundles**, ie: local paths and files, are not pinnable. Pass them through
   untouched and count them in the summary.

### Exit codes

- `0`: output written, or nothing to do.
- `1`: a named bundle could not be resolved (clone failed, ref not found, no commit before
  `--as-of`, deepen failed), the input has parse errors, `-i` was given without a file
  source, or input and stdout are the same file.
- When operating on a whole file rather than named bundles, unresolvable bundles warn and
  are skipped, and the exit stays `0` unless nothing at all could be resolved.
- On any nonzero exit, **nothing is written**: no partial stdout, no `-i` rewrite. Resolve
  everything first, emit last.

## Scope boundaries

`pin` **clones what is missing**. A pin has to come from a clone, and handing the user a
list of bundles to go clone themselves is a to-do list, not a tool. `pin_clone_missing`
emits `zsh_script` clone-only calls in parallel, the same machinery `bulk_clone` uses,
dropping the `pin:` annotation since it may be a loose ref that `zsh_script` would reject
and pin resolves locally right afterward. A clone that fails is an error.

Explicitly out of v1:

- No network beyond what cloning needs. Loose-ref lookup only fetches when the object is
  missing locally, and `--as-of` only deepens when history is.
- No lockfile.
- No git config or working-tree mutation. `pin` never checks anything out.
- No static file regeneration.
- No interactive `fzf` picker.
- No `pin list`. `antidote list --long` and `--jsonl` already report pins.

## Phases

**Phase 1**, done. `antidote pin` and `antidote unpin` over the `collect_input` contract,
resolving from on-disk state and from explicit `pin:` refs. Flags `-h`, `-i`, `-f`,
`--file`. stdout by default, atomic `-i` rewrite with a `.bak`, summary to stderr.

**Phase 2**, done. `--as-of <date>`: approxidate validation, deepen as needed,
branch-aware ref selection.

One thing phase 2 does not do: fetch. Dates resolve against the history on disk, matching
`git_min_age_sha`, so `--as-of now` means the newest commit antidote already knows about.
Fetching every bundle first would be correct-er and much slower, and `antidote update`
already exists for that.

## Test plan

`tests/bats/pin_command.bats`. The existing [tests/bats/pin.bats](tests/bats/pin.bats)
covers the `pin:` *annotation*, which is a different thing, so they stay separate.

The `pintest/pinme` fixture has three known SHAs, exported as `PIN_V100`, `PIN_V110`, and
`PIN_V120` by [tests/bats/helpers/common.bash](tests/bats/helpers/common.bash), and
[tests/bin/init_fixtures.zsh](tests/bin/init_fixtures.zsh) sets deterministic commit dates,
so `--as-of` is testable offline against the fake git site.

Cases:

1. a bundle argument gains `pin:<40 char sha>` on stdout
2. annotations on a bundle argument are preserved
3. an already-valid pin is left alone without `--force`
4. `--force` rewrites a valid pin in place, preserving annotation order
5. a loose `pin:<short sha>` expands to 40 chars without `--force`
6. a loose `pin:<tag>` resolves to the SHA the tag points at
7. an unresolvable ref exits 1 and writes nothing
8. stdin input pins every bundle in the stream
9. no args and no stdin reads `$_ANTIDOTE_BUNDLE_FILE`
10. `--file` reads that path instead of the default
11. comments, blank lines, and bundle order survive byte-for-byte
12. a trailing inline comment survives and the pin lands before it
13. local path bundles pass through untouched
14. all entries sharing a repo dir get the same SHA, and the result passes
    `bundle_check_critical`
15. a `using:` line gets the pin and the subplugin lines are untouched
16. unpin removes the annotation and leaves the rest of the line intact
17. unpin then `antidote bundle` returns the repo to its branch and clears `antidote.pin`
18. a default run prints to stdout and does not modify the file
19. `-i` modifies the file and prints nothing to stdout
20. `-i` creates a `.bak` holding the original bytes
21. `-i` with stdin input exits 1, and so does `-i` with bundle positionals
22. warnings land on stderr, never in the stdout payload
23. input with parse errors is refused, the file unmodified, exit 1, empty stdout
24. a bundle that is not cloned yet gets cloned and pinned
25. missing bundles in a whole file get cloned
26. a bundle that cannot be cloned exits 1 with a useful message and no output
27. a snapshot file piped through `pin` round-trips unchanged
28. a CRLF plugins file round-trips
29. phase 2: `--as-of` on a dated fixture resolves to the expected SHA
30. phase 2: an explicit `pin:` ref beats `--as-of` for that bundle
31. phase 2: an unparseable date is rejected rather than treated as "now"

## Unrelated bug found while designing this

[man/antidote-bundle.adoc](man/antidote-bundle.adoc) documents `pin:abc1234` in three
places, but `zsh_script` requires a full 40-char SHA and errors on anything shorter. Doc
drift, fix in its own commit. Note that a `pin` subcommand does not make those examples
correct, it makes them a thing `antidote pin` can convert.

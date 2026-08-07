# Changelog

Notable changes to this project will be documented in this file.

## [v2.3.0]

- Add a `preset:` directive setting fallback annotations for every later entry of a bundle, so `pin:` and the like need not repeat on each line. Keyed by clone directory, so the short, https, and ssh spellings share one set. Line-level and `using:` values win.
- Speed up dynamic mode by resolving `antidote init` in the parent shell instead of a subprocess, and dropping four forks from every `antidote` invocation. A warm `source <(antidote init)` startup goes from roughly 50ms to 35ms, and `antidote init` itself from 13.5ms to 1ms.
- Read the config file once per shell instead of once per command. `antidote-setup` sources it into the parent shell so parent-side code sees its zstyles; anything set before antidote loads still wins.
- Make a lone `antidote.zsh` usable when sourced, falling back to a shim that routes commands to the subprocess. `antidote load` and dynamic mode still need the full install.
- Fix a config file's `zstyle ':antidote:home' dir ...` being invisible to parent-shell code. `antidote home` reported the default path and the rebundle checkfile landed there, so `antidote update` never cleared it and the forced rebundle after an update stopped happening.
- Fix a static `.zwc` built by a different Zsh version never being rebuilt, leaving every shell on that version silently parsing the source.
- Fix `kind:autoload` functions never loading under `ksh_arrays`. The generated script indexed `$fpath[1]`, which is not a subscript under that option, so `autoload` got no arguments.
- Fix nested dispatch (`load` calling `bundle`) dropping the user's `KSH_ARRAYS` and `SH_GLOB`.
- Fix `ANTIDOTE_CONFIG` not crossing the process boundary, and an exported `ANTIDOTE_TMPDIR` being clobbered by `TMPDIR`.
- Fix `antidote update` and bundle zcompilation failing when `ANTIDOTE_HOME` contains spaces.
- Fix `antidote install` writing `:value` garbage to the plugins file for unknown long flags. It now errors.
- Fix a `preset:` not carrying across dynamic-mode `antidote bundle` calls.
- Fix bundles that failed to parse still being cloned, and parse errors on a path-style `using:` line being lost with the dropped entry.
- Add [misc/grammar.md](https://github.com/mattmc3/antidote/blob/main/misc/grammar.md) documenting the plugins file format: tokenization, directives, annotations, bundle type resolution, and errors. Document `using:` and `preset:` in the `antidote-bundle` man page and the syntax highlighter.
- Internal: discover parser contexts by name instead of listing each by hand in four places, where a missed edit failed silently.

## [v2.2.2]

- Fix git's own output during a clone leaking into the generated static file, where a line like `warning: redirecting to https://...` becomes a command at shell startup.
- Fix `pre:` and `post:` hooks not running for `kind:clone` bundles. Clone-only bundles still emit no load script unless a hook is present.
- Fix dynamic-mode heredoc bundles leaking `__adote_script=''` to stdout at shell startup.
- Fix concurrent `antidote load` shells racing while rebuilding the same static file. Rebuilds now use per-process temp files, fall back to the last known-good static file on failure, and clean up stale temp files from interrupted builds.
- Improve color detection by asking terminfo for terminal color support, honoring `FORCE_COLOR`, and treating `CLICOLOR=0` as an opt-out.
- Speed up internal helpers by replacing fork-heavy paths with Zsh builtins for bundle discovery, JSON escaping, and command checks.
- Add test fixtures for submodules and non-`main` default branches, covering clone/update paths that were previously untested.
- Update the architecture guide with cloning and update sequence diagrams and refreshed implementation notes.

## [v2.2.1]

- Fix a cold dynamic-mode startup stalling on bundles with a big history.
- Fix `antidote update` intermittently failing with `fatal: Cannot rebase onto multiple branches` right after a fresh clone ([#273](https://github.com/mattmc3/antidote/issues/273)). Git appends to `FETCH_HEAD` without locking it, so the background deepen started by a clone could corrupt what `git pull` read on the same repo. Update now rebases onto the remote-tracking ref instead of `FETCH_HEAD`.
- Fix `antidote update` failing on a bundle whose shallow clone is grafted so git cannot see its commit as an ancestor of upstream. The rebase replayed commits that were already upstream and conflicted; update now takes upstream as-is for that case, keeping local changes that no longer apply in the stash rather than writing conflict markers into a plugin file.
- Fix `antidote update` printing no commit list under the `updated:` line whenever the old commit had no parent in the clone, which is any shallow bundle and any repo updated from its root commit. The list also no longer repeats the commit you were already on.
- Fix antidote commands failing with `function definition file not found` after a package manager upgrade ([#271](https://github.com/mattmc3/antidote/issues/271)). Setup resolved its own install path through symlinks, so a Homebrew shell recorded the versioned keg directory instead of the stable `share/antidote` link. Upgrading deleted that keg out from under every running shell, breaking any function not yet autoloaded.

## [v2.2.0]

- Add `zstyle ':antidote:bundle:*' min-age <days>` to keep bundles a fixed number of days behind upstream, giving a bad push time to be noticed before it reaches your shell. Clones and updates stop at the newest commit that has been upstream long enough. A plugin with no commit that old is still installed at its latest commit. Pinned bundles ignore it. Commit dates are attacker-controlled, so treat this as a cushion, not a supply chain guarantee, and use `pin:` when you need a fixed commit.
- Clone bundles shallow, then deepen them with a background fetch, so the first run stays fast but full history is available afterward. Set `zstyle ':antidote:bundle:*' shallow 'yes'` to hold a bundle at its shallow clone.
- Make dynamic bundling dramatically faster by caching each `antidote bundle` line's generated script under `$ANTIDOTE_HOME/.dynamic`, so `source <(antidote init)` shells reuse the cached script instead of forking a subprocess per line. On local fixtures that takes a warm bundle line from roughly 30ms to under 0.5ms! Set `zstyle ':antidote:dynamic' zcompile 'yes'` to also compile the cached scripts.
- Fix a theme repo sourcing every `.zsh-theme` it ships when none is named for the repo directory. Bundling `romkatv/powerlevel10k` sourced both `powerlevel10k.zsh-theme` and the `powerlevel9k` compatibility shim.
- Fix `antidote update` reporting success when a worker failed, and fix bundles with the same short name overwriting each other's reports.
- Fix `antidote update --dry-run` deepening shallow clones, a permanent side effect from a dry run, and repair the temp dir cleanup trap.
- Fix `antidote update` treating a `shallow.lock` held by a background deepen as an update failure rather than contention.
- Fix `antidote load` discarding the existing static file when regeneration failed.

## [v2.1.1]

- Fix `antidote.zsh` exiting the shell when sourced from compiled `.zwc` bytecode ([#270](https://github.com/mattmc3/antidote/issues/270)). Zsh reports the eval context as `filecode` rather than `file` in that case, so the sourced check fell through to the CLI branch.
- Fix `antidote bundle` exiting 1 for bundle files containing only `kind:clone` entries, and make it exit non-zero when a clone or a parallel script generation job fails. Previously those failures printed to stderr but still exited 0.
- Fix `antidote load` returning 0 when the static file was missing or could not be sourced.
- Fix `antidote update` printing "self-update complete" after a failed self-update. It now reports the error and returns 1.
- Fix `antidote purge` commenting out unrelated bundles in the plugins file when one bundle name was a prefix of another (eg: purging `foo/bar` also matched `foo/barbaz`). Names now match literally, whole word only.
- Fix `antidote install` silently writing `:value` garbage to the plugins file for unknown short flags. It now fails with an error.
- Fix `antidote snapshot restore` reporting success when restores failed, and fix pinned restores always failing under ephemeral pins.
- Fix `antidote list --jsonl` producing invalid JSON when values contained quotes, backslashes, or control characters.
- Fix `antidote-dispatch` and `antidote-help` leaking private usage helper functions into the user's shell.
- Fix the non-Zsh guard misreporting the shell name, and tolerate a `ps` without `-p` (busybox).
- Speed up `antidote update` by only probing for bat when the snapshot picker actually runs.
- Ehance completions: `install` gains arg specs, a `--pin` value, and bundle positionals; `path` completes installed bundles; `help` completes topics; `load` and `snapshot` complete files.
- Remove unused git config isolation from `update` that would have broken credential helpers and `insteadOf` rewrites had it ever taken effect.
- Add an [ARCHITECTURE.md](https://github.com/mattmc3/antidote/blob/main/ARCHITECTURE.md) guide covering file layout, the parent/subprocess boundary, and the bundle pipeline.
- Internal: rename globals so `ANTIDOTE_*` means externally managed only, decompose oversized functions, and make `antidote.zsh` clean under `warn_nested_var`. No behavior changes.
- Internal: migrate the test suite from clitest markdown files to bats (`tests/bats`), with network tests split out under `just test-real`.

## [v2.1.0]

- Add `using:` directive for loading subplugins from monorepos and local paths (eg: oh-my-zsh, prezto).
- Improve error detection: invalid bundles and conflicting pin/branch annotations are now caught during parsing and reported with line numbers. Non-fatal errors skip the offending bundle but allow the rest to load. Fatal conflicts bail immediately.
- Ensure all non-script output from `antidote bundle` now begins with `#`, making redirected output safer to source. Exit code check is preferred for verifying bundle success.
- Add `zstyle ':antidote:home' dir ...` as an alternative to `$ANTIDOTE_HOME` to configure the antidote home directory for those who prefer to only use zstyles. If both are used, `$ANTIDOTE_HOME` wins.
- Refactor bundle parser to use an associative matrix, improving performance and enabling richer per-bundle metadata.

## [v2.0.12]

- Add syntax definition for antidote bundle files (`.zsh_plugins.txt`). See [misc/zsh_plugins.sublime-syntax](https://raw.githubusercontent.com/mattmc3/antidote/main/misc/zsh_plugins.sublime-syntax).
- Use bat for fzf snapshot preview when available, using our new syntax highlighter, with fallback to basic coloring if bat is unavailable or syntax is not installed
- Add `zstyle ':antidote:bat' opts ...` to allow user to configure their preferred bat options
- Fix `antidote update` to fail faster on git errors
- Add tests to ensure git autostashing is working

## [v2.0.11]

- Feature [#258](https://github.com/mattmc3/antidote/issues/258): fzf improvements

## [v2.0.10]

- Add `antidote snapshot home` subcommand to print the snapshot directory path
- Fix `antidote --version` printing a git error when installed outside a git repo (eg: Homebrew) ([#259](https://github.com/mattmc3/antidote/issues/259))

## [v2.0.9]

- Remove stray `setopt warn_create_global warn_nested_var` from testing

## [v2.0.8]

- Refactor for better performance

## [v2.0.7]

- Fix for [#255](https://github.com/mattmc3/antidote/issues/255): `antidote update` displayed the old version instead of the new version after self-update

## [v2.0.6]

- Fix `antidote snapshot` fzf picker regression in [#253](https://github.com/mattmc3/antidote/issues/253)
- Add `zstyle ':antidote:fzf' cmd ...` to configure which picker command is used for snapshot selection. Supports custom commands and paths to alternative `fzf` locations
- Allow disabling picker-based snapshot selection by setting `zstyle ':antidote:fzf' cmd ''`

## [v2.0.5]

- Fix `antidote list` empty-state detection to reliably warn when no bundles are found
- More fixes for [#247](https://github.com/mattmc3/antidote/issues/247)
- Fix bundle discovery to follow a symlinked `ANTIDOTE_HOME` path (`find -H`)
- Fix `antidote purge --all` for symlinked `ANTIDOTE_HOME` by clearing symlink contents before deleting the symlink path
- Add regression coverage for symlinked `ANTIDOTE_HOME` across `list`, `path`, `update`, `snapshot`, and `purge`
- Fix `antidote snapshot` commands launching fzf in non-interactive shells
- Fix test fixtures for git 2.17 compatibility
- Bump `actions/checkout` to v4

## [v2.0.4]

- Add `--diagnostics` flag to show antidote and system info for troubleshooting
- Add GitHub issue templates for bug reports and feature requests
- Fix `antidote list` silently exiting with error when no bundles are cloned ([#247](https://github.com/mattmc3/antidote/issues/247))
- Fix `antidote update` comparing short SHAs which could produce incorrect output (updates worked, but the output was potentially confusing for large repos)
- Refactor `antidote-dispatch` into separate autoloaded functions (`antidote-help`, `antidote-load`, `antidote-update`) to be more maintainable
- Clean up and alphabetize internal git helper functions

## [v2.0.3]

- Reuse existing clones when `path-style` changes, avoiding duplicate clones ([#245](https://github.com/mattmc3/antidote/issues/245))
- Remove legacy duplicate clones during bundling when multiple path-style directories exist
- Fix `find_bundles` failing when cloned bundles don't match the current `path-style`
- Fix `antidote bundle` emitting output before ensuring a successful clone operation
- `antidote list` now shows path and URL by default, and now has a `-u/--url` flag

## [v2.0.2]

- Minor fix for bump2version covering more files in the test suite

## [v2.0.1]

- Fix for gist cloning [#243](https://github.com/mattmc3/antidote/issues/243)

## [v2.0.0]

### Added

- New `antidote snapshot` command lets you save, restore, and list point-in-time snapshots of your plugin state
  - `antidote snapshot save` writes a snapshot file capturing the exact commit SHA of every cloned bundle
  - `antidote snapshot restore` restores your bundles to a previous state (uses an interactive picker if no file is given)
  - `antidote snapshot remove` removes snapshot files (interactive multi-select with `fzf` if available)
  - `antidote snapshot list` shows all available snapshots
- Snapshots are saved automatically after a successful `antidote update` (static mode only)
- To disable automatic snapshotting during updates, set this zstyle in your config (eg: ~/.config/antidote/config.zsh):
  ```zsh
  zstyle ':antidote:snapshot:automatic' enabled no
  ```
- If `fzf` is installed, `antidote snapshot restore` gives you an interactive picker with a preview of each snapshot
- Snapshot storage location and rolling history limit are configurable via `zstyle`
- New `pin:` annotation lets you lock a bundle to a specific commit SHA (full 40-character SHA required)
  - Example: `zsh-users/zsh-autosuggestions pin:85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5`
- Pinned bundles are skipped during `antidote update`
- `antidote update --dry-run` / `-n`: check for available updates without touching anything
- `antidote list` now shows URLs by default
- `antidote list --long` / `-l`: show verbose key-value info per bundle (repo, path, URL, SHA, pin status)
- `antidote list --dirs` / `-d`: show bundle directory paths
- `antidote list --jsonl` / `-j`: machine-readable JSONL output (includes pin status when pinned)
- antidote can now read an optional config `~/.config/antidote/config.zsh` on startup (respects `$XDG_CONFIG_HOME`)
- A template config file is included showing all available zstyles (see `templates/config.zsh`)
- New `path-style` zstyle controls how bundle directories are named on disk:
  - `full` (default): `$ANTIDOTE_HOME/github.com/owner/repo`
  - `short`: `$ANTIDOTE_HOME/owner/repo`
  - `escaped`: `$ANTIDOTE_HOME/https-COLON--SLASH--SLASH-github.com-SLASH-owner-SLASH-repo` (legacy antibody style)
  ```zsh
  zstyle ':antidote:bundle' path-style short
  ```
- New git zstyles let you clone from non-GitHub hosts or default to SSH for clones:
  ```zsh
  zstyle ':antidote:git' site gitlab.com
  zstyle ':antidote:git' protocol ssh
  ```
- Interactive selection uses `fzf` when available
- Color output now respects `NO_COLOR`, `CLICOLOR_FORCE`, and terminal capabilities
- Dockerfiles included for reproducible test environments
- Tons of new unit tests to verify correctness and provide stability

### Changed

- The codebase has been consolidated from many small functions into a single self-contained `antidote.zsh`
- Internal dispatching has been rewritten and streamlined
- `antidote list` flags have been redesigned and many removed and replaced by `--long`, `--dirs`, and `--jsonl`

### Removed

- Antibody compatibility mode has been removed
- `antidote list` old flags (`--short`, `--short-name`, `--url`, `--sha`, `--short-sha`, `--pinned`) have been removed in favor of `--long`

### Notes

- Pin any repos you want to keep on a certain release. They will be skipped when running `antidote update`. Use `antidote list --long` to see current SHAs, then add `pin:<SHA>` annotations to your .zsh_plugins.txt.

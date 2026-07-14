# Vendored bats libraries

Assertion helpers for the bats test suite, loaded by
`tests/bats/helpers/common.bash`. Vendored copies (`load.bash`,
`LICENSE`, `src/` only) rather than submodules: both libs are tiny,
stable, and rarely release.

| Library      | Source                                    | Version |
| ------------ | ----------------------------------------- | ------- |
| bats-support | https://github.com/bats-core/bats-support | v0.3.0  |
| bats-assert  | https://github.com/bats-core/bats-assert  | v2.1.0  |

To update: clone the tag upstream, copy `load.bash`, `LICENSE`, and
`src/` over the matching directory here, and bump the version above.

# antidote plugins file grammar

Reference for the `.zsh_plugins.txt` format, as implemented by `bundle_parser` and
`bundle_type` in `antidote.zsh`. The syntax highlighter in
[zsh_plugins.sublime-syntax](zsh_plugins.sublime-syntax) tracks this file.

## Tokenization is delegated to Zsh

This is not a self-contained grammar. antidote splits each line with `${(z)}`, Zsh's
own lexer, then removes one level of quoting with `${(Q)}`. Consequences that no EBNF
below can express:

- Quoting rules are Zsh's. `path:"a b"` is one word; `path:a b` is two.
- Zsh reserved tokens split even mid-line, so a bare leading `{` is read as a
  brace-group token rather than as text.

Input is read from stdin, or from command arguments. Arguments are joined with spaces
and _then_ split on newlines, so several arguments make one line, not one line each -
a multi-line bundle passed as an argument needs embedded newlines. `\r\n` and `\r` are
normalized to `\n` first.

## Grammar

```ebnf
file        = { line } ;
line        = [ entry ] [ comment ] NEWLINE ;
comment     = "#" { any-char } ;                  (* a word starting with # ends the line *)

entry       = ( directive | bundle ) { annotation } ;

directive   = using-directive ;
using-directive   = "using:" target ;

bundle      = word ;                              (* classified by bundle_type, below *)
annotation  = key ":" [ value ] ;
key         = ALPHA { ALPHA | DIGIT | "_" | "-" } ;
value       = word ;
```

A word with no `:` in the annotation position is an error. Annotation keys are matched
literally.

## Directives

A directive occupies the first word of a line and is not a bundle itself.

| Directive        | Effect                                                                                                                                                                              |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `using:<target>` | Sets a context. Bare words on later lines become subplugins of `<target>`, inheriting its annotations. A repo target also emits a `kind:clone` entry; a path target emits no entry. |

One directive per line.

## Annotations

Annotations are `key:value` and are **not validated against the entry type**. The parser
accepts any key on any line, and an annotation that means nothing for that entry is
silently ignored - `foo/bar wibble:wobble` parses and loads normally. So the table below
describes which annotations _have meaning_ where, not which ones are accepted.

### Which annotations apply to which entry

| Annotation       |         `using:`         |     git bundle     |    local bundle    |
| ---------------- | :----------------------: | :----------------: | :----------------: |
| `kind:`          |    default for words     | :white_check_mark: | :white_check_mark: |
| `path:`          | subpath prefix for words | :white_check_mark: | :white_check_mark: |
| `branch:`        |        inherited         | :white_check_mark: |         -          |
| `pin:`           |        inherited         | :white_check_mark: |         -          |
| `conditional:`   |        inherited         | :white_check_mark: | :white_check_mark: |
| `pre:` / `post:` |        inherited         | :white_check_mark: | :white_check_mark: |
| `autoload:`      |        inherited         | :white_check_mark: | :white_check_mark: |
| `fpath-rule:`    |        inherited         | :white_check_mark: | :white_check_mark: |

- **git bundle** is type `repo`, `url`, or `ssh_url`. **local bundle** is `path`, `dir`,
  or `file`.
- `branch:` and `pin:` only reach git, so they do nothing on a local bundle.
- On `using:`, annotations serve two roles: `path:` and `kind:` configure how bare words
  are expanded, and everything else is inherited by those words. A word's own annotation
  overrides the inherited one. The `using:` entry itself is forced to `kind:clone` and
  has its own `path:` dropped.
- A subplugin word takes the annotation set of its `using:` target's type.

### Values

| Annotation       | Value                                                                                     |
| ---------------- | ----------------------------------------------------------------------------------------- |
| `kind:`          | `zsh` \| `fpath` \| `path` \| `clone` \| `defer` \| `autoload`; anything else is an error |
| `path:`          | subdirectory or file inside the bundle                                                    |
| `branch:`        | git branch name                                                                           |
| `pin:`           | full 40-character lowercase hex commit SHA; a short SHA is an error                       |
| `conditional:`   | name of a zero-argument function                                                          |
| `pre:` / `post:` | name of a zero-argument function                                                          |
| `autoload:`      | functions directory inside the bundle                                                     |
| `fpath-rule:`    | `append` \| `prepend`; anything else is an error                                          |

Per-bundle behavior configurable by zstyle rather than annotation, so out of this
grammar: `:antidote:bundle:<bundle>` `min-age`, `zcompile`, `shallow`, `defer-options`.

## Bundle type resolution

`bundle_type` applies these in order and stops at the first match. `~/` and `$`-prefixed
words are expanded first, so classification reads the parse-time environment.

| Test                                  | Type                                                |
| ------------------------------------- | --------------------------------------------------- |
| exists on disk, is a file             | `file`                                              |
| exists on disk                        | `dir`                                               |
| empty or all spaces                   | `empty`                                             |
| starts with `/`, `~`, `$`, or `.`     | `path`                                              |
| contains `://`                        | `url`                                               |
| matches `*@*:*/*`                     | `ssh_url`                                           |
| contains `:` or `@`                   | invalid                                             |
| contains a space or tab               | invalid                                             |
| has three or more `/`-separated parts | invalid                                             |
| ends with `/`                         | invalid                                             |
| contains `/`                          | `repo`                                              |
| anything else                         | subplugin word, valid only under an active `using:` |

Order matters: `a:b/c` is invalid rather than a repo, because the `:`/`@` test precedes
the `/` test.

## Errors

Fatal to the line (the entry is dropped, the run exits non-zero):

- `invalid using: target` - unresolvable target.
- `invalid bundle` - unresolvable type, or a bare word with no active `using:`.
- `Expecting 'key:value' form for annotation` - an annotation word with no `:`.
- `pin requires a full 40-character commit SHA` - a short SHA.
- `unexpected fpath rule` - a `fpath-rule:` other than `append`/`prepend`.
- `unexpected kind value` - a `kind:` outside the listed values.

Fatal to the whole run, before any cloning:

- conflicting `pin:`/`branch:` for one bundle directory
- inconsistent `pin:`/`branch:` across entries sharing a bundle directory

An entry with an error is never cloned and emits no load script. When one line trips
several errors, the last one is the one reported.

#!/usr/bin/env python3
"""
Antidote plugin DSL validator.

Usage:
  python tools/antidote-validator.py .zsh_plugins.txt
  python tools/antidote-validator.py --debug .zsh_plugins.txt

Exit codes:
  0 = valid
  1 = invalid (syntax errors reported)
  2 = internal error (unexpected)
"""
from __future__ import annotations
import sys
from pathlib import Path
from dataclasses import dataclass
from typing import List

from lark import Lark, UnexpectedInput, UnexpectedToken, UnexpectedCharacters

GRAMMAR = r"""
// -------- Top Level --------
file: (_line)* statement?        -> file

_line: statement NEWLINE
     | NEWLINE

statement: comment
         | entry

comment: /[ \t]*#[^\n]*/

// -------- Entries --------
entry: WS? primary (WS attribute)* (WS extra_token)* (WS inline_comment)?  -> entry

inline_comment: /#[^\n]*/

// -------- Primary Token --------
primary: URL    -> url
       | SLUG   -> slug
       | PATH   -> path
       | VALUEWORD -> loneword

// -------- Attributes --------
attribute: key ":" value        -> attribute

# Support bare, double-quoted, and single-quoted keys.
key: BAREKEY
   | STRING
   | SSTRING

# Support double or single quoted values, or VALUEWORD.
value: STRING
     | SSTRING
     | VALUEWORD

extra_token: STRING
           | SSTRING
           | VALUEWORD

// -------- Terminals --------
//
// STRING / SSTRING support escapes for the respective quote and backslash.
//
STRING: /"([^"\\]|\\.)*"/
SSTRING: /'([^'\\]|\\.)*'/

URL: /(https?:\/\/[^\s#"]+)/
SLUG: /[A-Za-z0-9._-]+\/[A-Za-z0-9._-]+/
PATH: /\$[A-Za-z0-9_\/.$-]+/
BAREKEY: /[A-Za-z_][A-Za-z0-9_.-]*/

// Exclude both double and single quotes so quoted tokens are distinct.
// Allow ':' within VALUEWORD so values like is:this work.
VALUEWORD: /[^ \t\n"'#]+/

WS: /[ \t]+/
NEWLINE: /\r?\n/

%ignore /[ \t]+(?=#)/
%ignore /[ \t]+(?=\r?\n)/
"""

@dataclass
class ValidationError:
    line: int
    column: int
    message: str
    text: str

class AntidoteValidator:
    def __init__(self, debug: bool = False):
        self.debug = debug
        self.parser = Lark(
            GRAMMAR,
            start="file",
            parser="lalr",   # LALR with this grammar (BNF-ish)
            maybe_placeholders=False,
        )

    def validate_text(self, text: str) -> List[ValidationError]:
        """
        Validate entire file; if a global parse error occurs,
        attempt line-by-line fallback for more granular reporting.
        """
        try:
            self.parser.parse(text)
            return []
        except (UnexpectedInput, UnexpectedToken, UnexpectedCharacters) as e:
            # Fallback to per-line parse to isolate multiple errors.
            return self._line_by_line_errors(text)

    def _line_by_line_errors(self, text: str) -> List[ValidationError]:
        line_parser = Lark(
            GRAMMAR,
            start="statement",
            parser="lalr",
            maybe_placeholders=False,
        )
        errors: List[ValidationError] = []
        for idx, raw_line in enumerate(text.splitlines()):
            line_num = idx + 1
            line = raw_line.rstrip("\n")
            # Skip early if empty or comment; grammar should accept but fast-path:
            stripped = line.strip()
            if stripped == "" or stripped.startswith("#"):
                continue
            try:
                line_parser.parse(line)
            except (UnexpectedInput, UnexpectedToken, UnexpectedCharacters) as e:
                column = getattr(e, 'column', 1)
                msg = self._format_error_message(e)
                errors.append(ValidationError(
                    line=line_num,
                    column=column,
                    message=msg,
                    text=line
                ))
        return errors

    def _format_error_message(self, e: UnexpectedInput) -> str:
        if isinstance(e, UnexpectedToken):
            expected = ", ".join(sorted(sym for sym in e.expected))
            return f"Unexpected token '{e.token}' (expected: {expected})"
        if isinstance(e, UnexpectedCharacters):
            return f"Unexpected character at column {e.column}"
        return "Syntax error"

def main(argv: List[str]) -> int:
    if not argv or any(a in ("-h", "--help") for a in argv):
        print(__doc__.strip())
        return 0

    debug = False
    paths = []
    for a in argv:
        if a == "--debug":
            debug = True
        else:
            paths.append(a)

    if not paths:
        print("Error: provide a file to validate.", file=sys.stderr)
        return 2

    validator = AntidoteValidator(debug=debug)
    overall_errors: List[ValidationError] = []

    for p in paths:
        file_path = Path(p)
        if not file_path.exists():
            print(f"{file_path}: does not exist", file=sys.stderr)
            return 2
        text = file_path.read_text(encoding="utf-8")
        errors = validator.validate_text(text)
        if errors:
            print(f"{file_path}: INVALID ({len(errors)} error(s))")
            for err in errors:
                print(f"  Line {err.line}, Col {err.column}: {err.message}")
                print(f"    {err.text}")
            overall_errors.extend(errors)
        else:
            print(f"{file_path}: OK")

    return 1 if overall_errors else 0

if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except KeyboardInterrupt:
        print("Interrupted.", file=sys.stderr)
        sys.exit(130)
    except Exception as exc:
        print(f"Internal error: {exc}", file=sys.stderr)
        sys.exit(2)

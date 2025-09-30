#!/usr/bin/env python3
"""
antidote plugin DSL checker.

Usage:
  python tools/antidote-check.py .zsh_plugins.txt
  python tools/antidote-check.py --debug .zsh_plugins.txt

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

try:
    from lark import Lark, UnexpectedInput, UnexpectedToken, UnexpectedCharacters
except ImportError:
    print("Missing dependency: lark. Install with: pip install lark")
    raise

# Load grammar from external .lark file (same directory as this script)
GRAMMAR_PATH = Path(__file__).with_name("antidote.lark")
try:
    GRAMMAR_TEXT = GRAMMAR_PATH.read_text(encoding="utf-8")
except FileNotFoundError:
    raise RuntimeError(f"Grammar file not found: {GRAMMAR_PATH}")

@dataclass
class ValidationError:
    line: int
    column: int
    message: str
    text: str

class AntidoteChecker:
    def __init__(self, debug: bool = False):
        self.debug = debug
        if self.debug:
            print(f"[debug] Loading grammar from {GRAMMAR_PATH}")
        self.parser = Lark(
            GRAMMAR_TEXT,
            start="file",
            parser="lalr",
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
        except (UnexpectedInput, UnexpectedToken, UnexpectedCharacters):
            return self._line_by_line_errors(text)

    def _line_by_line_errors(self, text: str) -> List[ValidationError]:
        line_parser = Lark(
            GRAMMAR_TEXT,
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

    validator = AntidoteChecker(debug=debug)
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

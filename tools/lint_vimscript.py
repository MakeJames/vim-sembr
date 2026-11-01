#!/usr/bin/env python3
"""Project-specific Vimscript style checks."""

from __future__ import annotations

from pathlib import Path
import re
import sys

MAX_LINE_LENGTH = 80
INDENT_SIZE = 2
FUNCTION_PATTERN = re.compile(r'^\s*function!?\s+([^(]+)\(')
INDENTATION_PATTERN = re.compile(r'^[ \t]*')
SCRIPT_LOCAL_FUNCTION_PATTERN = re.compile(r'^s:[a-z][a-z0-9_]*$')
PUBLIC_FUNCTION_PATTERN = re.compile(r'^sembr#[A-Z][a-zA-Z0-9]*$')


def lint_file(path: Path) -> list[str]:
    violations = []

    for line_number, line in enumerate(path.read_text().splitlines(), start=1):
        indentation = INDENTATION_PATTERN.match(line).group()
        if '\t' in indentation or len(indentation) % INDENT_SIZE:
            violations.append(
                f'{path}:{line_number}: indentation must use '
                f'{INDENT_SIZE}-space increments'
            )

        if len(line) > MAX_LINE_LENGTH:
            violations.append(
                f'{path}:{line_number}: line exceeds {MAX_LINE_LENGTH} characters'
            )

        match = FUNCTION_PATTERN.match(line)
        if not match:
            continue

        function_name = match.group(1)
        if function_name.startswith('s:'):
            valid_name = SCRIPT_LOCAL_FUNCTION_PATTERN.fullmatch(function_name)
        else:
            valid_name = PUBLIC_FUNCTION_PATTERN.fullmatch(function_name)

        if not valid_name:
            violations.append(
                f'{path}:{line_number}: invalid function name {function_name!r}; '
                "use s:snake_case or sembr#PascalCase"
            )

    return violations


def vimscript_files(paths: list[str]) -> list[Path]:
    files = []
    for raw_path in paths:
        path = Path(raw_path)
        if path.is_dir():
            files.extend(path.rglob('*.vim'))
        elif path.suffix == '.vim':
            files.append(path)
    return sorted(files)


def main(argv: list[str]) -> int:
    violations = []
    for path in vimscript_files(argv):
        violations.extend(lint_file(path))

    print('\n'.join(violations))
    return int(bool(violations))


if __name__ == '__main__':
    raise SystemExit(main(sys.argv[1:]))

import importlib.util
from pathlib import Path

import pytest


SPEC = importlib.util.spec_from_file_location(
    'lint_vimscript', Path(__file__).parents[1] / 'tools' / 'lint_vimscript.py'
)
lint_vimscript = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(lint_vimscript)


def lint(source, tmp_path):
    path = tmp_path / 'source.vim'
    path.write_text(source)
    return lint_vimscript.lint_file(path)


def test_accepts_project_function_conventions(tmp_path):
    assert lint(
        'function! s:split_sentences(lines) abort\n'
        'endfunction\n'
        'function! sembr#ApplyRange(first_line, last_line) abort\n'
        'endfunction\n',
        tmp_path,
    ) == []


@pytest.mark.parametrize(
    ('source', 'message'),
    [
        pytest.param(
            'function! SplitSentences(lines) abort\nendfunction\n',
            'invalid function name',
            id='function-name',
        ),
        pytest.param(
            f'" {"x" * 79}\n',
            'line exceeds 80 characters',
            id='line-length',
        ),
    ],
)
def test_rejects_style_violations(source, message, tmp_path):
    assert message in lint(source, tmp_path)[0]


@pytest.mark.parametrize(
    ('source', 'message'),
    [
        pytest.param(
            'function! s:example() abort\n'
            '  if condition\n'
            '    return value\n'
            '  endif\n'
            'endfunction\n',
            None,
            id='two-space-increments',
        ),
        pytest.param(
            'function! s:example() abort\n'
            ' return value\n'
            'endfunction\n',
            'indentation must use 2-space increments',
            id='one-space-indent',
        ),
        pytest.param(
            'function! s:example() abort\n'
            '\treturn value\n'
            'endfunction\n',
            'indentation must use 2-space increments',
            id='tab-indent',
        ),
    ],
)
def test_enforces_two_space_indentation(source, message, tmp_path):
    violations = lint(source, tmp_path)

    if message is None:
        assert violations == []
    else:
        assert message in violations[0]

function! SemBrDocumentTestResetBuffer(lines) abort
  silent %delete _
  call setline(1, a:lines)
endfunction

describe 'SemBr markdown document snapshots'
  before
    enew!
    setlocal filetype=markdown
  end

  after
    bwipeout!
  end

  it 'snapshots a complete mixed-content document'
    let lines = [
          \ '# Sample Markdown Document',
          \ '',
          \ 'This is a test buffer.',
          \ '',
          \ 'It contains multiple sentences.',
          \ 'Some sentences are short. Others are longer and more complex!',
          \ 'We want to ensure that the formatting function works correctly.',
          \ '',
          \ 'Here is a list:',
          \ '- Item one',
          \ '- Item two',
          \ '- Item three',
          \ '',
          \ 'And here is a code block:',
          \ '```python',
          \ 'def example_function():',
          \ '    return "Hello, World!"',
          \ '```',
          \ ]
    call SemBrDocumentTestResetBuffer(lines)

    Expect sembr#document#Snapshot(bufnr('%'), 1, len(lines)) ==# {
          \ 'buffer': bufnr('%'),
          \ 'filetype': 'markdown',
          \ 'lines': lines,
          \ 'selection': {'start': [0, 0], 'end': [len(lines) - 1, 0]},
          \ }
  end

  it 'snapshot captures the whole document given a single-line range'
    let lines = [
            \ 'First line.',
            \ 'Second line.',
            \ 'Third line.',
            \ ]

    call SemBrDocumentTestResetBuffer(lines)

    let snapshot = sembr#document#Snapshot(bufnr('%'), 2, 2)

    Expect snapshot.lines ==# lines
    Expect snapshot.selection ==# {'start': [1, 0], 'end': [1, 0]}
  end

  it 'preserves selected blank lines'
    let lines = [
          \ 'Before.',
          \ '',
          \ 'After.',
          \ ]

    call SemBrDocumentTestResetBuffer(lines)
    call SemBrDocumentTestResetBuffer(['Before.', '', 'After.'])

    let snapshot = sembr#document#Snapshot(bufnr('%'), 2, 2)

    Expect snapshot.lines ==# lines
    Expect snapshot.selection ==# {'start': [1, 0], 'end': [1, 0]}
  end

  it 'does not change after buffer edits'
    call SemBrDocumentTestResetBuffer(['Original line.'])

    let snapshot = sembr#document#Snapshot(bufnr('%'), 1, 1)
    call setline(1, 'Modified line.')

    Expect snapshot.lines ==# ['Original line.']
  end

  it 'rejects a first line before the buffer'
    Expect expr { sembr#document#Snapshot(bufnr('%'), 0, 1) }
          \ to_throw 'sembr: invalid line range'
  end

  it 'rejects a last line before the buffer'
    Expect expr { sembr#document#Snapshot(bufnr('%'), 1, 0) }
          \ to_throw 'sembr: invalid line range'
  end

  it 'rejects reversed ranges'
    Expect expr { sembr#document#Snapshot(bufnr('%'), 2, 1) }
          \ to_throw 'sembr: invalid line range'
  end

  it 'rejects a last line after the buffer'
    Expect expr { sembr#document#Snapshot(bufnr('%'), 1, 2) }
          \ to_throw 'sembr: invalid line range'
  end

  it 'rejects unloaded source buffers'
    let buffer = bufadd(tempname())
    try
      Expect expr { sembr#document#Snapshot(buffer, 1, 1) }
            \ to_throw 'sembr: the source buffer is not loaded'
    finally
      execute 'bwipeout!' buffer
    endtry
  end
end

describe 'SemBr python document snapshots'
  before
    enew!
    setlocal filetype=python
  end

  after
    bwipeout!
  end

  it 'snapshots a complete mixed-content document'
    let lines = [
          \ '# Sample Python Document',
          \ '',
          \ 'def example_function():',
          \ '    """This is a docstring."""',
          \ '    return "Hello, World!"',
          \ '',
          \ 'if __name__ == "__main__":',
          \ '    print(example_function())',
          \ ]
    call SemBrDocumentTestResetBuffer(lines)

    Expect sembr#document#Snapshot(bufnr('%'), 1, len(lines)) ==# {
          \ 'buffer': bufnr('%'),
          \ 'filetype': 'python',
          \ 'lines': lines,
          \ 'selection': {'start': [0, 0], 'end': [len(lines) - 1, 0]},
          \ }
  end
end

describe 'SemBr yaml document snapshots'
  before
    enew!
    setlocal filetype=yaml
  end

  after
    bwipeout!
  end

  it 'snapshots a complete mixed-content document'
    let lines = [
          \ '# Sample YAML Document',
          \ '',
          \ 'key1: value1',
          \ 'key2: value2',
          \ 'nested:',
          \ '  - item1',
          \ '  - item2',
          \ ]
    call SemBrDocumentTestResetBuffer(lines)

    Expect sembr#document#Snapshot(bufnr('%'), 1, len(lines)) ==# {
          \ 'buffer': bufnr('%'),
          \ 'filetype': 'yaml',
          \ 'lines': lines,
          \ 'selection': {'start': [0, 0], 'end': [len(lines) - 1, 0]},
          \ }
  end
end

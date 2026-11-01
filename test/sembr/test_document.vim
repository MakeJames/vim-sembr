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

    Expect sembr#document#Document(bufnr('%'), 1, len(lines)) ==# {
          \ 'buffer': bufnr('%'),
          \ 'changedtick': getbufvar(bufnr('%'), 'changedtick'),
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

    let snapshot = sembr#document#Document(bufnr('%'), 2, 2)

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

    let snapshot = sembr#document#Document(bufnr('%'), 2, 2)

    Expect snapshot.lines ==# lines
    Expect snapshot.selection ==# {'start': [1, 0], 'end': [1, 0]}
  end

  it 'does not change after buffer edits'
    call SemBrDocumentTestResetBuffer(['Original line.'])

    let snapshot = sembr#document#Document(bufnr('%'), 1, 1)
    call setline(1, 'Modified line.')

    Expect snapshot.lines ==# ['Original line.']
    Expect snapshot.changedtick != getbufvar(bufnr('%'), 'changedtick')
  end

  it 'rejects a first line before the buffer'
    Expect expr { sembr#document#Document(bufnr('%'), 0, 1) }
          \ to_throw 'sembr: invalid line range'
  end

  it 'rejects a last line before the buffer'
    Expect expr { sembr#document#Document(bufnr('%'), 1, 0) }
          \ to_throw 'sembr: invalid line range'
  end

  it 'rejects reversed ranges'
    Expect expr { sembr#document#Document(bufnr('%'), 2, 1) }
          \ to_throw 'sembr: invalid line range'
  end

  it 'rejects a last line after the buffer'
    Expect expr { sembr#document#Document(bufnr('%'), 1, 2) }
          \ to_throw 'sembr: invalid line range'
  end

  it 'rejects unloaded source buffers'
    let buffer = bufadd(tempname())
    try
      Expect expr { sembr#document#Document(buffer, 1, 1) }
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

    Expect sembr#document#Document(bufnr('%'), 1, len(lines)) ==# {
          \ 'buffer': bufnr('%'),
          \ 'changedtick': getbufvar(bufnr('%'), 'changedtick'),
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

    Expect sembr#document#Document(bufnr('%'), 1, len(lines)) ==# {
          \ 'buffer': bufnr('%'),
          \ 'changedtick': getbufvar(bufnr('%'), 'changedtick'),
          \ 'filetype': 'yaml',
          \ 'lines': lines,
          \ 'selection': {'start': [0, 0], 'end': [len(lines) - 1, 0]},
          \ }
  end
end

function! SemBrDocumentTestSnapshot(lines) abort
  call SemBrDocumentTestResetBuffer(a:lines)
  return sembr#document#Document(bufnr('%'), 1, max([len(a:lines), 1]))
endfunction

describe 'sembr#document#Apply'
  before
    enew!
  end

  after
    bwipeout!
  end

  it 'replaces a single line range in place'
    let document = SemBrDocumentTestSnapshot(['one', 'two', 'three'])
    call sembr#document#Apply(document, [
          \ {'start': [1, 0], 'end': [1, 0], 'lines': ['TWO']},
          \ ])

    Expect getline(1, '$') ==# ['one', 'TWO', 'three']
  end

  it 'expands a range when an edit has more lines than it replaces'
    let document = SemBrDocumentTestSnapshot(['one', 'two', 'three'])
    call sembr#document#Apply(document, [
          \ {'start': [1, 0], 'end': [1, 0], 'lines': ['two', 'and a half']},
          \ ])

    Expect getline(1, '$') ==# ['one', 'two', 'and a half', 'three']
  end

  it 'shrinks a range when an edit has fewer lines than it replaces'
    let document = SemBrDocumentTestSnapshot(['one', 'two', 'and a half', 'three'])
    call sembr#document#Apply(document, [
          \ {'start': [1, 0], 'end': [2, 0], 'lines': ['two']},
          \ ])

    Expect getline(1, '$') ==# ['one', 'two', 'three']
  end

  it 'applies multiple edits without earlier edits invalidating later ones'
    let document = SemBrDocumentTestSnapshot(
          \ ['first. second!', 'untouched', 'third. fourth!'])
    call sembr#document#Apply(document, [
          \ {'start': [0, 0], 'end': [0, 0], 'lines': ['1st.', '2nd!']},
          \ {'start': [2, 0], 'end': [2, 0], 'lines': ['3rd.', '4th!']},
          \ ])

    Expect getline(1, '$') ==# [
          \ '1st.', '2nd!', 'untouched', '3rd.', '4th!',
          \ ]
  end

  it 'applies edits on adjacent lines without overwriting each other'
    let document = SemBrDocumentTestSnapshot(['one. two!', 'three. four!'])
    call sembr#document#Apply(document, [
          \ {'start': [0, 0], 'end': [0, 0], 'lines': ['one.', 'two!']},
          \ {'start': [1, 0], 'end': [1, 0], 'lines': ['three.', 'four!']},
          \ ])

    Expect getline(1, '$') ==# ['one.', 'two!', 'three.', 'four!']
  end

  it 'removes a range entirely when an edit has no replacement lines'
    let document = SemBrDocumentTestSnapshot(['one', 'two', 'three'])
    call sembr#document#Apply(document, [
          \ {'start': [1, 0], 'end': [1, 0], 'lines': []},
          \ ])

    Expect getline(1, '$') ==# ['one', 'three']
  end

  it 'leaves a single empty line when an edit removes the whole buffer'
    let document = SemBrDocumentTestSnapshot(['one', 'two', 'three'])
    call sembr#document#Apply(document, [
          \ {'start': [0, 0], 'end': [2, 0], 'lines': []},
          \ ])

    Expect getline(1, '$') ==# ['']
  end

  it 'does nothing for an empty plan'
    let document = SemBrDocumentTestSnapshot(['one', 'two'])
    call sembr#document#Apply(document, [])

    Expect getline(1, '$') ==# ['one', 'two']
  end

  it 'rejects a plan if the buffer changed since the snapshot'
    let document = SemBrDocumentTestSnapshot(['one', 'two', 'three'])
    call setline(2, 'edited elsewhere')

    Expect expr { sembr#document#Apply(document, [
          \ {'start': [1, 0], 'end': [1, 0], 'lines': ['TWO']},
          \ ]) }
          \ to_throw 'sembr: the buffer has changed since the document was snapshotted'
    Expect getline(1, '$') ==# ['one', 'edited elsewhere', 'three']
  end
end

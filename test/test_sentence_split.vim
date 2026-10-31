runtime plugin/vim-sembr.vim

function! SemBrTestFormat(lines) abort
  enew!
  call setline(1, a:lines)
  SemBr
  return getline(1, '$')
endfunction

function! SemBrTestFormatAs(lines, filetype) abort
  enew!
  let &l:filetype = a:filetype
  call setline(1, a:lines)
  SemBr
  return getline(1, '$')
endfunction

function! SemBrTestFormatRange(lines, first_line, last_line) abort
  enew!
  call setline(1, a:lines)
  call sembr#ApplyRange(a:first_line, a:last_line)
  return getline(1, '$')
endfunction

describe 'SemBr'
  it 'splits multiple sentences on one line'
    Expect SemBrTestFormat(['One sentence. A second sentence! Is this the third?'])
          \ ==# ['One sentence.', 'A second sentence!', 'Is this the third?']
  end

  it 're-maps split sentences'
    Expect SemBrTestFormat(['A sentence can span', 'multiple source lines.', 'The next one cannot.'])
          \ ==# ['A sentence can span multiple source lines.', 'The next one cannot.']
  end

  it 'normalizes whitespace between sentences'
    Expect SemBrTestFormat(['Sentence one.   Sentence two!'])
          \ ==# ['Sentence one.', 'Sentence two!']
  end

  it 'preserves a line without terminal punctuation'
    Expect SemBrTestFormat(['A line without terminal punctuation'])
          \ ==# ['A line without terminal punctuation']
  end

  it 'preserves sentence formatting across filetypes'
    let lines = ['One sentence. A second sentence!']
    let expected = ['One sentence.', 'A second sentence!']
    Expect SemBrTestFormatAs(lines, 'markdown') ==# expected
    Expect SemBrTestFormatAs(lines, 'text') ==# expected
    Expect SemBrTestFormatAs(lines, 'vim') ==# expected
  end

  it 'supports ellipses'
    let actual = SemBrTestFormat(['A line with ... is supported.'])
    Expect actual ==# ['A line with ...', 'is supported.']
  end

  it 'preserves paragraph, list, and code structure'
    Expect SemBrTestFormat([
          \ 'The first paragraph spans',
          \ 'multiple lines.',
          \ '',
          \ '- first unpunctuated item',
          \ '- second unpunctuated item',
          \ '    let value = 1',
          \ '    let next_value = value + 1',
          \ '',
          \ 'The second paragraph. Another sentence!'
          \ ]) ==# [
          \ 'The first paragraph spans multiple lines.',
          \ '',
          \ '- first unpunctuated item',
          \ '- second unpunctuated item',
          \ '    let value = 1',
          \ '    let next_value = value + 1',
          \ '',
          \ 'The second paragraph.',
          \ 'Another sentence!'
          \ ]
  end

  it 'preserves headings and fenced code blocks'
    Expect SemBrTestFormat([
          \ '# Heading',
          \ 'Prose sentence. Another sentence!',
          \ '',
          \ '```vim',
          \ 'let value = 1',
          \ 'let next_value = value + 1',
          \ '```'
          \ ]) ==# [
          \ '# Heading',
          \ 'Prose sentence.',
          \ 'Another sentence!',
          \ '',
          \ '```vim',
          \ 'let value = 1',
          \ 'let next_value = value + 1',
          \ '```'
          \ ]
  end

  it 'does not open a fence indented by four spaces'
    Expect SemBrTestFormat([
          \ 'Introductory prose.',
          \ '    ```',
          \ 'Prose sentence. Another sentence!'
          \ ]) ==# [
          \ 'Introductory prose.',
          \ '    ```',
          \ 'Prose sentence.',
          \ 'Another sentence!'
          \ ]
  end

  it 'preserves indented fence markers inside fenced code blocks'
    Expect SemBrTestFormat([
          \ '```vim',
          \ '    ```',
          \ 'gamma. delta!',
          \ '```',
          \ 'Closing prose. Final sentence?'
          \ ]) ==# [
          \ '```vim',
          \ '    ```',
          \ 'gamma. delta!',
          \ '```',
          \ 'Closing prose.',
          \ 'Final sentence?'
          \ ]
  end

  it 'preserves a fenced block when the range starts inside it'
    Expect SemBrTestFormatRange([
          \ '```vim',
          \ 'let value = 1',
          \ 'let next_value = value + 1',
          \ '```',
          \ 'Prose sentence. Another sentence!'
          \ ], 2, 5) ==# [
          \ '```vim',
          \ 'let value = 1',
          \ 'let next_value = value + 1',
          \ '```',
          \ 'Prose sentence.',
          \ 'Another sentence!'
          \ ]
  end

  it 'preserves tilde fences and detects range context'
    Expect SemBrTestFormatRange([
          \ '~~~vim',
          \ 'let value = 1',
          \ 'let next_value = value + 1',
          \ '~~~',
          \ 'Prose sentence. Another sentence!'
          \ ], 2, 5) ==# [
          \ '~~~vim',
          \ 'let value = 1',
          \ 'let next_value = value + 1',
          \ '~~~',
          \ 'Prose sentence.',
          \ 'Another sentence!'
          \ ]
  end

  it 'formats only the selected prose lines'
    Expect SemBrTestFormatRange([
          \ 'Before the range remains unchanged.',
          \ 'Selected prose. A second selected sentence!',
          \ 'After the range remains unchanged.'
          \ ], 2, 2) ==# [
          \ 'Before the range remains unchanged.',
          \ 'Selected prose.',
          \ 'A second selected sentence!',
          \ 'After the range remains unchanged.'
          \ ]
  end

  it 'removes only surplus lines from the selected range'
    Expect SemBrTestFormatRange([
          \ 'Before the range remains unchanged.',
          \ 'Selected prose spans',
          \ 'two source lines.',
          \ 'After the range remains unchanged.'
          \ ], 2, 3) ==# [
          \ 'Before the range remains unchanged.',
          \ 'Selected prose spans two source lines.',
          \ 'After the range remains unchanged.'
          \ ]
  end

  it 'preserves ordered lists as structural sections'
    Expect SemBrTestFormat([
          \ '# Steps',
          \ 'Introductory prose. Another sentence!',
          \ '1. First item. Keep this line unchanged.',
          \ '2. Second item.',
          \ '    let value = 1',
          \ '```vim',
          \ 'let next_value = value + 1',
          \ '```',
          \ 'Closing prose. Final sentence?'
          \ ]) ==# [
          \ '# Steps',
          \ 'Introductory prose.',
          \ 'Another sentence!',
          \ '1. First item. Keep this line unchanged.',
          \ '2. Second item.',
          \ '    let value = 1',
          \ '```vim',
          \ 'let next_value = value + 1',
          \ '```',
          \ 'Closing prose.',
          \ 'Final sentence?'
          \ ]
  end
end

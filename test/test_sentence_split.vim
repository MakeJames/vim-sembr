" test the methods for splitting sentences into lines

call SemBrTestCase(
      \ 'splits multiple sentences on one line',
      \ ['One sentence. A second sentence! Is this the third?'],
      \ ['One sentence.', 'A second sentence!', 'Is this the third?'])

call SemBrTestCase(
      \ 'Re-map split sentences',
      \ ['A sentence can span', 'multiple source lines.', 'The next one cannot.'],
      \ ['A sentence can span multiple source lines.', 'The next one cannot.'])

call SemBrTestCase(
      \ 'normalizes whitespace between sentences',
      \ ['Sentence one.   Sentence two!'],
      \ ['Sentence one.', 'Sentence two!'])

call SemBrTestCase(
      \ 'preserves a line without terminal punctuation',
      \ ['A line without terminal punctuation'],
      \ ['A line without terminal punctuation'])

call SemBrTestCase(
      \ 'supports ellipses',
      \ ['A line with ... is supported.'],
      \ ['A line with ...', 'is supported.'])

call SemBrTestCase(
      \ 'preserves paragraph, list, and code structure',
      \ [
      \    'The first paragraph spans',
      \    'multiple lines.',
      \    '',
      \    '- first unpunctuated item',
      \    '- second unpunctuated item',
      \    '    let value = 1',
      \    '    let next_value = value + 1',
      \    '',
      \    'The second paragraph. Another sentence!'
      \ ],
      \ [
      \    'The first paragraph spans multiple lines.',
      \    '',
      \    '- first unpunctuated item',
      \    '- second unpunctuated item',
      \    '    let value = 1',
      \    '    let next_value = value + 1',
      \    '',
      \    'The second paragraph.',
      \    'Another sentence!'
      \ ])

call SemBrTestCase(
      \ 'preserves headings and fenced code blocks',
      \ [
      \    '# Heading',
      \    'Prose sentence. Another sentence!',
      \    '',
      \    '```vim',
      \    'let value = 1',
      \    'let next_value = value + 1',
      \    '```'
      \ ],
      \ [
      \    '# Heading',
      \    'Prose sentence.',
      \    'Another sentence!',
      \    '',
      \    '```vim',
      \    'let value = 1',
      \    'let next_value = value + 1',
      \    '```'
      \ ])

call SemBrRangeTestCase(
      \ 'preserves a fenced block when the range starts inside it',
      \ [
      \    '```vim',
      \    'let value = 1',
      \    'let next_value = value + 1',
      \    '```',
      \    'Prose sentence. Another sentence!'
      \ ],
      \ 2,
      \ 5,
      \ [
      \    '```vim',
      \    'let value = 1',
      \    'let next_value = value + 1',
      \    '```',
      \    'Prose sentence.',
      \    'Another sentence!'
      \ ])

if len(v:errors)
  for error in v:errors
    echom error
  endfor
  cquit 1
endif

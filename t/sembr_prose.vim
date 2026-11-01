function! s:formats_long_clauses() abort
  let text = 'The formatter records each relevant decision for later review, and the next clause gives enough context to exceed the recommended line length.'
  call testify#assert#equals(
        \ sembr#prose#format(text, []),
        \ [
        \   'The formatter records each relevant decision for later review,',
        \   'and the next clause gives enough context to exceed the recommended line length.'
        \ ])
endfunction
call testify#it('formats a long clause at punctuation', function('s:formats_long_clauses'))

function! s:protects_markdown_inline_syntax() abort
  let text = 'Use `first, second, and third` code, while the subsequent explanation deliberately exceeds the recommended line length.'
  let ranges = sembr#markdown#protected_ranges(text)
  call testify#assert#equals(
        \ sembr#prose#format(text, ranges),
        \ [
        \   'Use `first, second, and third` code,',
        \   'while the subsequent explanation deliberately exceeds the recommended line length.'
        \ ])
endfunction
call testify#it(
      \ 'protects punctuation inside Markdown inline syntax',
      \ function('s:protects_markdown_inline_syntax'))

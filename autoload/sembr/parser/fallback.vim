" Fallback parser for filetypes without a dedicated parser.
" Treats the whole document as a single preserved node, so SemBr is a
" no-op rather than erroring or mangling syntax it doesn't understand.

function! sembr#parser#fallback#Parse(document) abort
  return {
        \ 'kind': 'document',
        \ 'start': [0, 0],
        \ 'end': [max([len(a:document.lines) - 1, 0]), 0],
        \ 'lines': a:document.lines,
        \ }
endfunction

function! sembr#parser#fallback#Rules() abort
  return {'document': {'action': 'preserve'}}
endfunction

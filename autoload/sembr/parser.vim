" Parsers share Parse(document) and Rules() entry points.
function! sembr#parser#Resolve(filetype) abort
  let l:parsers = {
        \ 'markdown': {
        \   'Parse': function('sembr#parser#markdown#Parse'),
        \   'Rules': function('sembr#parser#markdown#Rules'),
        \ },
        \ }
  return get(l:parsers, a:filetype, {})
endfunction

function! sembr#parser#Preserve(document) abort
  return {
        \ 'kind': 'document',
        \ 'range': {
        \   'start': [1, 0],
        \   'end': [len(a:document.lines) + 1, 0],
        \ },
        \ 'handling': 'preserve',
        \ 'policy': {},
        \ 'layout': {},
        \ 'children': [],
        \ }
endfunction

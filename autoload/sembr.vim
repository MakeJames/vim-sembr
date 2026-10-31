function! s:split_sentences(lines) abort
  let l:text = substitute(join(a:lines, ' '), '\s\+', ' ', 'g')
  return split(l:text, '\([.!?]\)\@<=\s\+')
endfunction

function! sembr#ApplyRange(first_line, last_line) abort
  let l:sentences = s:split_sentences(getline(a:first_line, a:last_line))
  if empty(l:sentences)
    return
  endif

  call append(a:first_line - 1, l:sentences)
  execute (a:first_line + len(l:sentences)) . ','
        \ . (a:last_line + len(l:sentences)) . 'delete _'
endfunction

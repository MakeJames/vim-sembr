function! s:split_sentences(lines) abort
  let l:text = join(a:lines, ' ')
  return split(l:text, '\([.!?]\)\@<=\s\+')
endfunction

function! s:is_prose_line(line) abort
  return a:line !~# '^\s*$'
        \ && a:line !~# '^\s\+'
        \ && a:line !~# '^\s*\%([-*+]\|\d\+[.)]\)\s\+'
endfunction

function! s:format_lines(lines) abort
  let l:formatted = []
  let l:paragraph = []

  for l:line in a:lines
    if s:is_prose_line(l:line)
      call add(l:paragraph, l:line)
    else
      call extend(l:formatted, s:split_sentences(l:paragraph))
      let l:paragraph = []
      call add(l:formatted, l:line)
    endif
  endfor

  call extend(l:formatted, s:split_sentences(l:paragraph))
  return l:formatted
endfunction

function! sembr#ApplyRange(first_line, last_line) abort
  let l:formatted = s:format_lines(getline(a:first_line, a:last_line))
  if empty(l:formatted)
    return
  endif

  call append(a:first_line - 1, l:formatted)
  execute (a:first_line + len(l:formatted)) . ','
        \ . (a:last_line + len(l:formatted)) . 'delete _'
endfunction

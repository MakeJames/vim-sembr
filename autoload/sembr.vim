function! s:split_sentences(lines) abort
  let l:text = join(a:lines, ' ')
  return split(l:text, '\([.!?]\)\@<=\s\+')
endfunction

function! s:is_prose_line(line) abort
  return a:line !~# '^\s*$'
        \ && a:line !~# '^\s\+'
        \ && a:line !~# '^\s*\%([-*+]\|\d\+[.)]\)\s\+'
        \ && a:line !~# '^#\+\%(\s\|$\)'
endfunction

function! s:fence_marker(line) abort
  return matchstr(a:line, '^\s*\zs\(```\+\|[~]\{3,}\)')
endfunction

function! s:is_fence_close(line, fence) abort
  let l:marker = s:fence_marker(a:line)
  return !empty(l:marker)
        \ && l:marker[0] ==# a:fence[0]
        \ && strlen(l:marker) >= strlen(a:fence)
        \ && a:line =~# '^\s*' . l:marker . '\s*$'
endfunction

function! s:fence_state_before(line_number) abort
  let l:fence = ''

  for l:line in getline(1, a:line_number - 1)
    if empty(l:fence)
      let l:fence = s:fence_marker(l:line)
    elseif s:is_fence_close(l:line, l:fence)
      let l:fence = ''
    endif
  endfor

  return l:fence
endfunction

function! s:format_lines(lines, fence) abort
  let l:formatted = []
  let l:paragraph = []
  let l:fence = a:fence

  for l:line in a:lines
    if !empty(l:fence)
      call add(l:formatted, l:line)
      if s:is_fence_close(l:line, l:fence)
        let l:fence = ''
      endif
    elseif !empty(s:fence_marker(l:line))
      call extend(l:formatted, s:split_sentences(l:paragraph))
      let l:paragraph = []
      call add(l:formatted, l:line)
      let l:fence = s:fence_marker(l:line)
    elseif s:is_prose_line(l:line)
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
  let l:formatted = s:format_lines(
        \ getline(a:first_line, a:last_line),
        \ s:fence_state_before(a:first_line))
  if empty(l:formatted)
    return
  endif

  call append(a:first_line - 1, l:formatted)
  execute (a:first_line + len(l:formatted)) . ','
        \ . (a:last_line + len(l:formatted)) . 'delete _'
endfunction

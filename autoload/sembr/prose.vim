scriptencoding utf-8

function! s:is_protected(position, ranges) abort
  for l:range in a:ranges
    if a:position >= l:range[0] && a:position < l:range[1]
      return 1
    endif
  endfor

  return 0
endfunction

function! sembr#prose#format(text, protected_ranges) abort
  let l:formatted = []
  let l:line_start = 0
  let l:last_clause_end = -1
  let l:last_clause_next = -1
  let l:offset = 0

  while l:offset < strlen(a:text)
    let l:punctuation_start = match(
          \ a:text, '\([.!?,;:]\|\%u2014\)\ze\s\+', l:offset)
    if l:punctuation_start < 0
      break
    endif

    let l:punctuation = matchstr(
          \ a:text, '\([.!?,;:]\|\%u2014\)\ze\s\+', l:punctuation_start)
    let l:punctuation_end = l:punctuation_start + strlen(l:punctuation)
    let l:next = matchend(a:text, '\s\+', l:punctuation_end)

    if s:is_protected(l:punctuation_start, a:protected_ranges)
      let l:offset = l:next
      continue
    endif

    let l:line = strpart(
          \ a:text, l:line_start, l:punctuation_end - l:line_start)
    if l:punctuation =~# '[.!?]'
      if strdisplaywidth(l:line) > 80 && l:last_clause_end >= l:line_start
        call add(l:formatted, strpart(
              \ a:text, l:line_start, l:last_clause_end - l:line_start))
        let l:line_start = l:last_clause_next
      endif
      call add(l:formatted, strpart(
            \ a:text, l:line_start, l:punctuation_end - l:line_start))
      let l:line_start = l:next
      let l:last_clause_end = -1
      let l:last_clause_next = -1
    elseif strdisplaywidth(l:line) > 80 && l:last_clause_end >= l:line_start
      call add(l:formatted, strpart(
            \ a:text, l:line_start, l:last_clause_end - l:line_start))
      let l:line_start = l:last_clause_next
      let l:last_clause_end = l:punctuation_end
      let l:last_clause_next = l:next
    else
      let l:last_clause_end = l:punctuation_end
      let l:last_clause_next = l:next
    endif

    let l:offset = l:next
  endwhile

  let l:line = strpart(a:text, l:line_start)
  if strdisplaywidth(l:line) > 80 && l:last_clause_end >= l:line_start
    call add(l:formatted, strpart(
          \ a:text, l:line_start, l:last_clause_end - l:line_start))
    let l:line_start = l:last_clause_next
  endif
  call add(l:formatted, strpart(a:text, l:line_start))
  return l:formatted
endfunction

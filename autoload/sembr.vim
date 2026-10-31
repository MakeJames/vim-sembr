scriptencoding utf-8

function! s:fence_marker(line) abort
  return matchstr(a:line, '^ \{0,3}\zs\(```\+\|[~]\{3,}\)')
endfunction

function! s:is_fence_close(line, fence) abort
  let l:marker = s:fence_marker(a:line)
  let l:indent = matchstr(a:line, '^\s*')
  return !empty(l:marker)
        \ && l:marker[0] ==# a:fence[0]
        \ && strlen(l:marker) >= strlen(a:fence)
        \ && strpart(a:line, strlen(l:indent) + strlen(l:marker)) =~# '^\s*$'
endfunction

function! s:line_kind(line) abort
  if a:line =~# '^\s*$'
    return 'structural'
  elseif !empty(s:fence_marker(a:line)) || a:line =~# '^\s\+'
    return 'code'
  elseif a:line =~# '^\s*\%([-*+]\|\d\+[.)]\)\s\+'
    return 'list'
  elseif a:line =~# '^#\+\%(\s\|$\)'
    return 'structural'
  endif

  return 'prose'
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

function! s:segment(lines, fence) abort
  let l:sections = []
  let l:current = {'type': '', 'lines': []}
  let l:fence = a:fence

  for l:line in a:lines
    let l:type = empty(l:fence) ? s:line_kind(l:line) : 'code'
    if !empty(l:current.lines) && l:current.type !=# l:type
      call add(l:sections, l:current)
      let l:current = {'type': '', 'lines': []}
    endif
    let l:current.type = l:type
    call add(l:current.lines, l:line)

    if empty(l:fence)
      let l:fence = s:fence_marker(l:line)
    elseif s:is_fence_close(l:line, l:fence)
      let l:fence = ''
    endif
  endfor

  if !empty(l:current.lines)
    call add(l:sections, l:current)
  endif

  return l:sections
endfunction

function! s:split_sentences(lines) abort
  let l:text = join(a:lines, ' ')
  return split(l:text, '\([.!?]\)\@<=\s\+')
endfunction

function! s:markdown_protected_ranges(text) abort
  let l:pattern = '\%(!\?\[[^]]*\](\([^()]*(\([^()]*\)[^()]*)*\|[^()]*\))\|<[^>]*>\|`\+[^`]*`\+\|\*\{1,3}[^*]\+\*\{1,3}\|_\{1,3}[^_]\+_\{1,3}\)'
  let l:ranges = []
  let l:offset = 0

  while l:offset < strlen(a:text)
    let l:start = match(a:text, l:pattern, l:offset)
    if l:start < 0
      break
    endif

    let l:end = matchend(a:text, l:pattern, l:start)
    call add(l:ranges, [l:start, l:end])
    let l:offset = l:end
  endwhile

  return l:ranges
endfunction

function! s:is_protected(position, ranges) abort
  for l:range in a:ranges
    if a:position >= l:range[0] && a:position < l:range[1]
      return 1
    endif
  endfor

  return 0
endfunction

function! s:split_semantic_text(text, ranges) abort
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

    if s:is_protected(l:punctuation_start, a:ranges)
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

function! s:split_semantic_prose(lines, filetype) abort
  let l:text = join(a:lines, ' ')

  if a:filetype ==# 'markdown'
    return s:split_semantic_text(
          \ l:text, s:markdown_protected_ranges(l:text))
  endif

  return s:split_semantic_text(l:text, [])
endfunction

function! s:format_prose(lines, filetype) abort
  if a:filetype ==# 'markdown' || a:filetype ==# 'text'
    return s:split_semantic_prose(a:lines, a:filetype)
  endif

  return s:split_sentences(a:lines)
endfunction

function! s:format_sections(sections, filetype) abort
  let l:formatted = []

  for l:section in a:sections
    if l:section.type ==# 'prose'
      call extend(l:formatted, s:format_prose(l:section.lines, a:filetype))
    else
      call extend(l:formatted, l:section.lines)
    endif
  endfor

  return l:formatted
endfunction

function! sembr#ApplyRange(first_line, last_line) abort
  let l:formatted = s:format_sections(
    \ s:segment(
      \ getline(a:first_line, a:last_line),
      \ s:fence_state_before(a:first_line)
      \ ),
      \ &filetype
  \ )
  if empty(l:formatted)
    return
  endif

  let l:original_count = a:last_line - a:first_line + 1
  let l:overlap_count = min([l:original_count, len(l:formatted)])
  call setline(a:first_line, l:formatted[0 : l:overlap_count - 1])

  if len(l:formatted) > l:original_count
    call append(a:last_line, l:formatted[l:original_count :])
  elseif len(l:formatted) < l:original_count
    execute (a:first_line + len(l:formatted)) . ',' . a:last_line . 'delete _'
  endif
endfunction

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

function! s:split_semantic_prose(lines, filetype) abort
  let l:text = join(a:lines, ' ')

  if a:filetype ==# 'markdown'
    return sembr#prose#format(
          \ l:text, sembr#markdown#protected_ranges(l:text))
  endif

  return sembr#prose#format(l:text, [])
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

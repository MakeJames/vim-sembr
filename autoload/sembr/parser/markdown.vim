" Markdown reference adapter for SemBr

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
    return 'blank'
  elseif !empty(s:fence_marker(a:line)) || a:line =~# '^\s\+'
    return 'code_block'
  elseif a:line =~# '^\s*\%([-*+]\|\d\+[.)]\)\s\+'
    return 'list'
  elseif a:line =~# '^#\+\%(\s\|$\)'
    return 'heading'
  endif

  " All other lines treated as paragraphs.
  " This is a major simplification of the Markdown spec,
  " but it is sufficient for mapping out the internal structure of SemBr.
  return 'paragraph'
endfunction

function! s:list_node(start_line, lines) abort
  " A list node's children are its individual, unformatted item lines.
  let l:children = []
  for l:offset in range(len(a:lines))
    let l:line = a:start_line + l:offset
    call add(l:children, {
          \ 'kind': 'list_item',
          \ 'start': [l:line, 0],
          \ 'end': [l:line, 0],
          \ 'lines': [a:lines[l:offset]],
          \ })
  endfor

  return {
        \ 'kind': 'list',
        \ 'start': [a:start_line, 0],
        \ 'end': [a:start_line + len(a:lines) - 1, 0],
        \ 'children': l:children,
        \ }
endfunction

function! s:leaf_node(kind, start_line, lines) abort
  return {
        \ 'kind': a:kind,
        \ 'start': [a:start_line, 0],
        \ 'end': [a:start_line + len(a:lines) - 1, 0],
        \ 'lines': a:lines,
        \ }
endfunction

function! sembr#parser#markdown#Parse(document) abort
  " Build a nested tree from a document snapshot (see sembr#document#Document).
  " Consecutive lines of the same kind are grouped into a single node,
  " 'code_block' spans both fenced and indented runs,
  " and 'list' nesting one 'list_item' child per line.
  "
  " Parameters:
  "   document: a snapshot from sembr#document#Document
  "
  " Returns:
  "   a tree of nodes, each {
  "     kind: the kind of node (see sembr#parser#markdown#Rules)
  "     start: the start position of the node [line, column] (0-indexed)
  "     end: the end position of the node [line, column] (0-indexed)
  "     lines: the lines of the node (only for leaf nodes)
  "     children: the child nodes of the node (only for non-leaf nodes)
  "     }
  let l:children = []
  let l:kind = ''
  let l:start_line = 0
  let l:buffer = []
  let l:fence = ''

  for l:index in range(len(a:document.lines))
    let l:line = a:document.lines[l:index]
    let l:line_kind = empty(l:fence) ? s:line_kind(l:line) : 'code_block'

    if !empty(l:buffer) && l:line_kind !=# l:kind
      call add(l:children,
            \ l:kind ==# 'list' ? s:list_node(l:start_line, l:buffer)
            \                   : s:leaf_node(l:kind, l:start_line, l:buffer))
      let l:buffer = []
    endif

    if empty(l:buffer)
      let l:start_line = l:index
    endif
    let l:kind = l:line_kind
    call add(l:buffer, l:line)

    if empty(l:fence)
      let l:fence = s:fence_marker(l:line)
    elseif s:is_fence_close(l:line, l:fence)
      let l:fence = ''
    endif
  endfor

  if !empty(l:buffer)
    call add(l:children,
          \ l:kind ==# 'list' ? s:list_node(l:start_line, l:buffer)
          \                   : s:leaf_node(l:kind, l:start_line, l:buffer))
  endif

  return {
        \ 'kind': 'document',
        \ 'start': [0, 0],
        \ 'end': [max([len(a:document.lines) - 1, 0]), 0],
        \ 'children': l:children,
        \ }
endfunction

function! sembr#parser#markdown#Rules() abort
  return {
        \ 'document': {'action': 'descend'},
        \ 'list': {'action': 'descend'},
        \ 'list_item': {'action': 'preserve'},
        \ 'code_block': {'action': 'preserve'},
        \ 'heading': {'action': 'preserve'},
        \ 'blank': {'action': 'preserve'},
        \ 'paragraph': {'action': 'format'},
        \ }
endfunction

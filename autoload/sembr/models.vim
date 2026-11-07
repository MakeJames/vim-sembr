" Higher level data structures for SemBr


function! s:assert_flag(value) abort
  let l:is_int = type(a:value) == type(0)
  let l:is_flag = (a:value == 0 || a:value == 1)
  if !l:is_int || !l:is_flag
    throw 'sembr: invalid flag value: ' . string(a:value) . ', must be 0 or 1.'
  endif
endfunction


function! s:assert_list(value, list_type) abort
  if type(a:value) != type([])
    throw 'sembr: invalid list value: ' . string(a:value) . ', must be a list.'
  endif

  echo a:value

  for l:item in a:value
    if type(l:item) != type(a:list_type)
      throw 'sembr: invalid list value: '
        \ . string(l:item) . ', must be a ' . string(a:list_type) . '.'
    endif
  endfor

endfunction


function! s:assert_string(value) abort
  if type(a:value) != type('')
    throw 'sembr: invalid string value: '
        \ . string(a:value) . ', must be a string.'
  endif
endfunction


function! sembr#models#Node(opt) abort
  " A node is a generic element of the document.
  "
  " Parameters:
  "   opt: dictionary of options to set on the node
  "
  " Returns:
  "   A dictionary representing the node with the following keys:
  "     kind: string representing the type of node (default: '')
  "     start: list of ints - [line, column] (default: [0, 0])
  "     end: list of ints - [line, column] (default: [0, 0])
  "     children: list of child nodes (default: [sembr#models#Node])
  "     lines: list of strings in the node (default: [])
  "     safe: int - 0 or 1 indicating if the node is safe (default: 0)


  let l:defaults = {
        \ 'kind': '',
        \ 'start': [0, 0],
        \ 'end': [0, 0],
        \ 'children': [],
        \ 'lines': [],
        \ 'safe': 0,
        \ }

  let l:node = {
        \ 'kind': get(a:opt, 'kind', l:defaults.kind),
        \ 'start': get(a:opt, 'start', l:defaults.start),
        \ 'end': get(a:opt, 'end', l:defaults.end),
        \ 'children': get(a:opt, 'children', l:defaults.children),
        \ 'lines': get(a:opt, 'lines', l:defaults.lines),
        \ 'safe': get(a:opt, 'safe', l:defaults.safe),
        \ }

  " Validate the 'kind' field
  call s:assert_string(l:node.kind)

  " Validate lines field
  call s:assert_list(l:node.lines, 'string')

  " Validate the 'safe' flag
  call s:assert_flag(l:node.safe)

  " TODO: add further validation for other fields:
  "  - start and end should be
  "     - lists of two integers
  "     - start <= end
  "     - not be negative
  "  - children should be a list of nodes or empty.
  "  - lines should be a list of strings or empty.

  return l:node

endfunction

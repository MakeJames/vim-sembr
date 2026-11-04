" Higher level data structures for SemBr


function! s:is_flag(value) abort
  " Check if a value is a valid flag (0 or 1).
  "
  " Parameters:
  "   value: the value to check
  " Returns:
  "   1 if the value is a valid flag, 0 otherwise

  return type(a:value) == type(0)
    \ && (a:value == 0 || a:value == 1)
endfunction

function! s:assert_flag(value) abort
  " Assert that a value is a valid flag (0 or 1).
  "
  " Parameters:
  "   value: the value to check
  " Raises:
  "   An error if the value is not a valid flag

  if !s:is_flag(a:value)
    throw 'sembr: invalid flag value: ' . string(a:value) . ', must be 0 or 1.'
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

  " Validate the 'safe' flag
  call s:assert_flag(l:node.safe)

  " TODO: add further validation for other fields:
  "  - kind should be a string
  "  - start and end should be
  "     - lists of two integers
  "     - start <= end
  "     - not be negative
  "  - children should be a list of nodes or empty.
  "  - lines should be a list of strings or empty.

  return l:node

endfunction

" Document functions for Sembr

function! sembr#document#Snapshot(buffer, first_line, last_line) abort
  " Create a snapshot of the current buffer.
  "
  " Snapshot copies the entire document into memory,
  " This preserves the state of the document
  " and ensures that changes have full document context.
  "
  " Parameters:
  "   buffer: the buffer number of the document to snapshot
  "   first_line: the first line of the document to snapshot (1-indexed)
  "   last_line: the last line of the document to snapshot (1-indexed)
  "
  " Returns:
  "   buffer: vim.Buffer
  "   filetype: string
  "   lines: a list of strings for all lines in the document
  "   selection: {
  "     start: the start position of the selection [line, column] (0-indexed)
  "     end: the end position of the selection [line, column] (0-indexed)
  "
  " Throws:
  "   'sembr: the source buffer is not loaded' if the buffer is not loaded
  "   'sembr: invalid line range' if the line range is invalid
  if !bufloaded(a:buffer)
    throw 'sembr: the source buffer is not loaded'
  endif

  let l:lines = getbufline(a:buffer, 1, '$')

  if a:first_line < 1 || a:last_line < 1
        \ || a:first_line > a:last_line || a:last_line > len(l:lines)
    throw 'sembr: invalid line range'
  endif

  return {
        \ 'buffer': a:buffer,
        \ 'filetype': getbufvar(a:buffer, '&filetype'),
        \ 'lines': l:lines,
        \ 'selection': {
        \   'start': [a:first_line - 1, 0],
        \   'end': [a:last_line - 1, 0],
        \ },
        \ }
endfunction

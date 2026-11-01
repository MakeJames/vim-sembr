" Document functions for Sembr


function! sembr#document#Document(buffer, first_line, last_line) abort
  " Create a snapshot of the current buffer.
  "
  " Preserve the current state of the entire document.
  " This ensures that changes have full document context.
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
        \ 'changedtick': getbufvar(a:buffer, 'changedtick'),
        \ 'filetype': getbufvar(a:buffer, '&filetype'),
        \ 'lines': l:lines,
        \ 'selection': {
        \   'start': [a:first_line - 1, 0],
        \   'end': [a:last_line - 1, 0],
        \ },
        \ }
endfunction

function! sembr#document#Plan(document) abort
  " Plan the edits SemBr would make to a document snapshot.
  "
  " Selects the parser for the document's filetype (see sembr#parser#For),
  " parses the document into a tree, and hands the tree and the parser's
  " rules to sembr#engine#Plan to compute the edits.
  "
  " Parameters:
  "   document: a snapshot from sembr#document#Document
  "
  " Returns:
  "   a list of edits (see sembr#engine#Plan)
  let l:parser = sembr#parser#For(a:document.filetype)
  return sembr#engine#Plan(
        \ l:parser.Parse(a:document), l:parser.Rules(), a:document.selection)
endfunction

function! sembr#document#Apply(document, plan) abort
  " Apply a plan of edits to the buffer.
  "
  " Parameters:
  "   document: a snapshot from sembr#document#Document
  "   plan: a list of edits, each {
  "     start: the start position of the edit [line, column] (0-indexed)
  "     end: the end position of the edit [line, column] (0-indexed)
  "     lines: the replacement lines for the start/end range
  "   }
  "
  " Throws:
  "   'sembr: the buffer has changed since the document was snapshotted'
  if getbufvar(a:document.buffer, 'changedtick') !=# a:document.changedtick
    " This check will need to be updated
    " if this function is ever called in an async context.
    throw 'sembr: the buffer has changed since the document was snapshotted'
  endif

  for l:edit in reverse(copy(a:plan))
    let l:first_line = l:edit.start[0] + 1
    let l:last_line = l:edit.end[0] + 1
    let l:original_count = l:last_line - l:first_line + 1
    let l:overlap_count = min([l:original_count, len(l:edit.lines)])

    call setbufline(
          \ a:document.buffer, l:first_line,
          \ l:edit.lines[0 : l:overlap_count - 1])

    if len(l:edit.lines) > l:original_count
      call appendbufline(
            \ a:document.buffer, l:last_line, l:edit.lines[l:original_count :])
    elseif len(l:edit.lines) < l:original_count
      call deletebufline(
            \ a:document.buffer, l:first_line + len(l:edit.lines), l:last_line)
    endif
  endfor
endfunction

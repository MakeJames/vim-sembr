" Entry point for the :SemBr command.

function! sembr#Format(first_line, last_line) abort
  " Format a line range of the current buffer according to the SemBr
  " standard, dispatching to the appropriate parser for its filetype.
  "
  " Parameters:
  "   first_line: the first line of the range to format (1-indexed)
  "   last_line: the last line of the range to format (1-indexed)
  let l:document = sembr#document#Document(
        \ bufnr('%'), a:first_line, a:last_line)
  let l:plan = sembr#document#Plan(l:document)
  call sembr#document#Apply(l:document, l:plan)
endfunction

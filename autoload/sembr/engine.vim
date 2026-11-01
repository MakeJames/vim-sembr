function! sembr#engine#Plan(document, regions, options) abort
  " TODO: tokenise permitted prose into original content spans and whitespace
  " boundaries. Classify allowed/required boundaries and split costs, choose
  " breaks using display width (including layout prefixes), and serialise
  " each region into an Edit. Honour every region's whitespace policy.
  let l:diagnostics = []
  if !empty(a:regions)
    call add(l:diagnostics, {
          \ 'code': 'engine_pending',
          \ 'message': 'The shared engine does not produce edits yet.',
          \ })
  endif
  return {'edits': [], 'diagnostics': l:diagnostics}
endfunction

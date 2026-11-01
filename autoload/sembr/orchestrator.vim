" Experimental planning API. Snapshot data is read-only by convention.
function! sembr#orchestrator#Snapshot(buffer, first_line, last_line) abort
  if !bufloaded(a:buffer)
    throw 'sembr: the source buffer must be loaded'
  endif
  let l:lines = getbufline(a:buffer, 1, '$')
  if a:first_line < 1 || a:last_line < a:first_line
        \ || a:last_line > len(l:lines)
    throw 'sembr: invalid source range'
  endif
  return {
        \ 'bufnr': a:buffer,
        \ 'changedtick': getbufvar(a:buffer, 'changedtick'),
        \ 'filetype': getbufvar(a:buffer, '&filetype'),
        \ 'lines': l:lines,
        \ 'selection': {
        \   'start': [a:first_line, 0],
        \   'end': [a:last_line + 1, 0],
        \ },
        \ }
endfunction

function! sembr#orchestrator#Plan(document, options) abort
  let l:document = deepcopy(a:document)
  let l:parser = sembr#parser#Resolve(l:document.filetype)
  let l:plan = {
        \ 'snapshot': l:document,
        \ 'root': sembr#parser#Preserve(l:document),
        \ 'regions': [],
        \ 'edits': [],
        \ 'diagnostics': [],
        \ }
  if empty(l:parser)
    call add(l:plan.diagnostics, {
          \ 'code': 'unsupported_filetype',
          \ 'message': 'No parser registered for: ' . l:document.filetype,
          \ })
    return l:plan
  endif

  let l:parsed = call(l:parser.Parse, [l:document])
  let l:rules = call(l:parser.Rules, [])
  let l:selection = sembr#tree#Select(
        \ l:parsed.root, l:rules, l:document.selection)
  let l:formatted = sembr#engine#Plan(
        \ l:document, l:selection.regions, deepcopy(a:options))
  let l:plan.root = l:parsed.root
  let l:plan.regions = l:selection.regions
  let l:plan.edits = l:formatted.edits
  call extend(l:plan.diagnostics, l:parsed.diagnostics)
  call extend(l:plan.diagnostics, l:selection.diagnostics)
  call extend(l:plan.diagnostics, l:formatted.diagnostics)
  return l:plan
endfunction

function! sembr#orchestrator#Apply(plan) abort
  " TODO: validate changedtick, edit ranges, source coverage, and overlap;
  " apply from the end of the buffer in one undo operation.
  throw 'sembr: applying planned edits is not implemented'
endfunction

function! SemBrTestRegion(kind, first_line, last_line, handling) abort
  return {
        \ 'kind': a:kind,
        \ 'range': {'start': [a:first_line, 0], 'end': [a:last_line + 1, 0]},
        \ 'handling': a:handling,
        \ 'children': [],
        \ 'layout': {'first_prefix': '', 'continuation_prefix': ''},
        \ 'policy': {'join_soft_breaks': v:true, 'insert_soft_breaks': v:true},
        \ }
endfunction

function! SemBrTestSelect(root, first_line, last_line) abort
  return sembr#tree#Select(a:root, sembr#parser#markdown#Rules(), {
        \ 'start': [a:first_line, 0], 'end': [a:last_line + 1, 0],
        \ })
endfunction

describe 'Experimental document planning'
  it 'captures full source context with a separate selection'
    enew!
    setlocal filetype=markdown
    call setline(1, ['```', 'Selected code. Keep it.', '```'])
    let document = sembr#orchestrator#Snapshot(bufnr('%'), 2, 2)
    Expect document.lines ==# ['```', 'Selected code. Keep it.', '```']
    Expect document.selection ==# {'start': [2, 0], 'end': [3, 0]}
    Expect document.changedtick == b:changedtick
  end

  it 'returns a conservative Markdown tree without editing source'
    enew!
    setlocal filetype=markdown
    call setline(1, ['A sentence. Another sentence.'])
    let document = sembr#orchestrator#Snapshot(bufnr('%'), 1, 1)
    let plan = sembr#orchestrator#Plan(document, {'width': 80})
    Expect plan.root.children[0].kind ==# 'unknown'
    Expect plan.root.children[0].handling ==# 'preserve'
    Expect plan.edits ==# []
    Expect plan.diagnostics[0].code ==# 'parser_pending'
    let plan.snapshot.lines[0] = 'Changed plan copy'
    Expect document.lines ==# ['A sentence. Another sentence.']
    Expect getline(1, '$') ==# document.lines
  end

  it 'preserves unsupported filetypes rather than guessing prose'
    enew!
    setlocal filetype=python
    call setline(1, ['value = "A. B."'])
    let plan = sembr#orchestrator#Plan(
          \ sembr#orchestrator#Snapshot(bufnr('%'), 1, 1), {})
    Expect plan.root.handling ==# 'preserve'
    Expect plan.regions ==# []
    Expect plan.edits ==# []
    Expect plan.diagnostics[0].code ==# 'unsupported_filetype'
  end

  it 'visits nested prose in source order using the Markdown rule map'
    let first = SemBrTestRegion('paragraph', 1, 1, 'reflow')
    let second = SemBrTestRegion('paragraph', 3, 3, 'reflow')
    let item = SemBrTestRegion('list_item', 3, 3, 'container')
    let item.children = [second]
    let root = SemBrTestRegion('document', 1, 3, 'container')
    let root.children = [first, item]
    let selected = SemBrTestSelect(root, 1, 3)
    Expect selected.regions ==# [first, second]
    Expect root.children[1].children[0] ==# second
  end

  it 'does not descend through a protected or unrecognised region'
    let paragraph = SemBrTestRegion('paragraph', 1, 1, 'reflow')
    let code = SemBrTestRegion('fenced_code', 1, 1, 'preserve')
    let code.children = [paragraph]
    Expect SemBrTestSelect(code, 1, 1).regions ==# []
    let unknown = SemBrTestRegion('unregistered_kind', 1, 1, 'container')
    let unknown.children = [paragraph]
    Expect SemBrTestSelect(unknown, 1, 1).regions ==# []
  end

  it 'requires parser permission even when the map says format'
    let paragraph = SemBrTestRegion('paragraph', 1, 1, 'reflow')
    let paragraph.policy = {}
    Expect SemBrTestSelect(paragraph, 1, 1).regions ==# []
    let paragraph.handling = 'preserve'
    let paragraph.policy = {'insert_soft_breaks': v:true}
    Expect SemBrTestSelect(paragraph, 1, 1).regions ==# []
  end

  it 'skips prose cut by a selection boundary'
    let paragraph = SemBrTestRegion('paragraph', 1, 3, 'reflow')
    let selected = SemBrTestSelect(paragraph, 2, 3)
    Expect selected.regions ==# []
    Expect selected.diagnostics[0].code ==# 'partial_region'
  end

  it 'leaves edit planning explicit until the engine is implemented'
    let paragraph = SemBrTestRegion('paragraph', 1, 1, 'reflow')
    let result = sembr#engine#Plan({}, [paragraph], {'width': 80})
    Expect result.edits ==# []
    Expect result.diagnostics[0].code ==# 'engine_pending'
  end

  it 'refuses to apply an experimental plan'
    enew!
    call setline(1, ['Original source'])
    let rejected = v:false
    try
      call sembr#orchestrator#Apply({'edits': []})
    catch /^sembr: applying planned edits is not implemented$/
      let rejected = v:true
    endtry
    Expect rejected == v:true
    Expect getline(1, '$') ==# ['Original source']
  end
end

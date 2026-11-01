" The engine plans the SemBr rule set against the document tree.

function! s:split_sentences(lines) abort
  " Split a list of lines into sentences.
  let l:text = join(a:lines, ' ')

  return split(l:text, '\([.!?]\)\@<=\s\+')

endfunction

function! s:visit_impl(node, in_selection) dict abort
  let l:rule = get(l:self.rules, a:node.kind, {'action': 'preserve'})

  if l:rule.action ==# 'descend'
    let l:edits = []

    for l:child in a:node.children
      call extend(l:edits, sembr#tree#Visit(l:child, l:self.selection, l:self))
    endfor

    return l:edits

  elseif l:rule.action ==# 'format' && a:in_selection

    return [{
          \ 'start': a:node.start,
          \ 'end': a:node.end,
          \ 'lines': s:split_sentences(a:node.lines),
          \ }]
  endif

  return []

endfunction

function! sembr#engine#Plan(tree, rules, selection) abort
  " Walk a parser's tree, applying each node's rule action:
  "   - 'descend': recurse into the node's children
  "   - 'format': re-split the node's lines into sentences, but only when the
  "               node overlaps the selection
  "   - anything else (eg: 'preserve', or an action missing): no edit
  "
  " Returns:
  "   list of edits ({start, end, lines}) for changed nodes, sorted ascending
  "
  " Throws:
  "   - 'sembr: overlapping edits' if the edits are not sorted and overlapping
  let l:visitor = {'rules': a:rules, 'selection': a:selection}
  let l:visitor.Visit = function('s:visit_impl', l:visitor)
  let l:edits = sembr#tree#Visit(a:tree, a:selection, l:visitor)
  call s:assert_non_overlapping(l:edits)
  return l:edits
endfunction

function! s:assert_non_overlapping(edits) abort
  " Guardrail against overlapping edits.
  "
  " This is protects against misconfigured rule sets
  " or parsing defects.
  for l:index in range(1, max([len(a:edits) - 1, 0]))
    if a:edits[l:index].start[0] <= a:edits[l:index - 1].end[0]
      throw 'sembr: overlapping edits'
    endif
  endfor
endfunction

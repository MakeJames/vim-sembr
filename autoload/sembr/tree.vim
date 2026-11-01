" Traverse the document tree.
"
" Each node is a dict with:
"   kind: string, the node kind (eg: 'paragraph', 'list', 'code_block')
"   start: [line, col], 0-indexed inclusive start position
"   end: [line, col], 0-indexed inclusive end position
"   lines: list of strings (leaf nodes), or
"   children: list of nodes (container nodes)
"
" A selection is a dict with:
"   start: [line, col]
"   end: [line, col]
" matching the shape returned by sembr#document#Document().selection

function! sembr#tree#Visit(node, selection, visitor) abort
  " Visit a single node, identify if it overlaps the selection.
  let l:in_selection = sembr#tree#Overlaps(a:node, a:selection)
  return a:visitor.Visit(a:node, l:in_selection)
endfunction

function! sembr#tree#Overlaps(node, selection) abort
  " Line-based overlap test between a node's range and a selection's range.
  return a:node.start[0] <= a:selection.end[0]
        \ && a:node.end[0] >= a:selection.start[0]
endfunction

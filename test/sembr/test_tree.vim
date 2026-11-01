function! SemBrTreeTestVisitor(log) abort
  " A stub visitor that records each visited node's kind and in_selection
  " flag, and recurses into children when the node has any.
  return {
        \ 'log': a:log,
        \ 'Visit': function('SemBrTreeTestVisitorVisit', [a:log]),
        \ }
endfunction

function! SemBrTreeTestVisitorVisit(log, node, in_selection) abort
  call add(a:log, [a:node.kind, a:in_selection])
  if has_key(a:node, 'children')
    for l:child in a:node.children
      call sembr#tree#Visit(l:child, g:sembr_tree_test_selection, SemBrTreeTestVisitor(a:log))
    endfor
  endif
  return 'visited:' . a:node.kind
endfunction

describe 'sembr#tree#Overlaps'
  it 'overlaps when the node range intersects the selection range'
    let node = {'kind': 'paragraph', 'start': [2, 0], 'end': [4, 0]}
    Expect sembr#tree#Overlaps(node, {'start': [0, 0], 'end': [2, 0]}) ==# 1
    Expect sembr#tree#Overlaps(node, {'start': [4, 0], 'end': [9, 0]}) ==# 1
    Expect sembr#tree#Overlaps(node, {'start': [2, 0], 'end': [4, 0]}) ==# 1
  end

  it 'does not overlap when the node range is outside the selection range'
    let node = {'kind': 'paragraph', 'start': [2, 0], 'end': [4, 0]}
    Expect sembr#tree#Overlaps(node, {'start': [0, 0], 'end': [1, 0]}) ==# 0
    Expect sembr#tree#Overlaps(node, {'start': [5, 0], 'end': [9, 0]}) ==# 0
  end
end

describe 'sembr#tree#Visit'
  it 'reports in_selection when the node overlaps the selection'
    let node = {'kind': 'paragraph', 'start': [1, 0], 'end': [1, 0], 'lines': ['x']}
    let selection = {'start': [0, 0], 'end': [2, 0]}
    let log = []
    let result = sembr#tree#Visit(node, selection, SemBrTreeTestVisitor(log))
    Expect log ==# [['paragraph', 1]]
    Expect result ==# 'visited:paragraph'
  end

  it 'reports not in_selection when the node is outside the selection'
    let node = {'kind': 'paragraph', 'start': [5, 0], 'end': [5, 0], 'lines': ['x']}
    let selection = {'start': [0, 0], 'end': [2, 0]}
    let log = []
    call sembr#tree#Visit(node, selection, SemBrTreeTestVisitor(log))
    Expect log ==# [['paragraph', 0]]
  end

  it 'leaves recursion into children up to the visitor'
    let g:sembr_tree_test_selection = {'start': [0, 0], 'end': [1, 0]}
    let tree = {
          \ 'kind': 'document',
          \ 'start': [0, 0],
          \ 'end': [2, 0],
          \ 'children': [
          \   {'kind': 'paragraph', 'start': [0, 0], 'end': [1, 0], 'lines': ['a']},
          \   {'kind': 'code_block', 'start': [2, 0], 'end': [2, 0], 'lines': ['b']},
          \ ],
          \ }
    let log = []
    call sembr#tree#Visit(tree, g:sembr_tree_test_selection, SemBrTreeTestVisitor(log))
    Expect log ==# [
          \ ['document', 1],
          \ ['paragraph', 1],
          \ ['code_block', 0],
          \ ]
    unlet g:sembr_tree_test_selection
  end
end

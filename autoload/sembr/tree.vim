function! s:before_or_equal(left, right) abort
  return a:left[0] < a:right[0]
        \ || (a:left[0] == a:right[0] && a:left[1] <= a:right[1])
endfunction

function! s:visit(node, rules, selection, result) abort
  let l:rule = get(a:rules, a:node.kind, {'action': 'preserve'})
  if l:rule.action ==# 'preserve' || a:node.handling ==# 'preserve'
    return
  elseif l:rule.action ==# 'descend'
    if a:node.handling ==# 'container'
      for l:child in a:node.children
        call s:visit(l:child, a:rules, a:selection, a:result)
      endfor
    endif
  elseif l:rule.action ==# 'format'
    " A rule cannot grant permission the parser has withheld. Containers
    " cannot be selected as well as their descendants.
    let l:policy = get(a:node, 'policy', {})
    if a:node.handling !=# 'reflow' || !empty(a:node.children)
          \ || !(get(l:policy, 'join_soft_breaks', v:false)
          \      || get(l:policy, 'insert_soft_breaks', v:false))
      return
    endif
    if !s:before_or_equal(a:selection.start, a:node.range.start)
          \ || !s:before_or_equal(a:node.range.end, a:selection.end)
      call add(a:result.diagnostics, {
            \ 'code': 'partial_region',
            \ 'message': 'A prose region is not wholly inside the selection.',
            \ 'range': deepcopy(a:node.range),
            \ })
      return
    endif
    call add(a:result.regions, deepcopy(a:node))
  else
    throw 'sembr: unknown tree rule action: ' . l:rule.action
  endif
endfunction

function! sembr#tree#Select(root, rules, selection) abort
  let l:result = {'regions': [], 'diagnostics': []}
  call s:visit(a:root, a:rules, a:selection, l:result)
  return l:result
endfunction

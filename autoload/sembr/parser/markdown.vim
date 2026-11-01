" Reference adapter: block and inline recognition are deliberately pending.
function! sembr#parser#markdown#Parse(document) abort
  let l:root = sembr#parser#Preserve(a:document)
  let l:unknown = deepcopy(l:root)
  let l:unknown.kind = 'unknown'
  let l:root.handling = 'container'
  let l:root.children = [l:unknown]
  " TODO: replace unknown with a complete partition of block regions, using
  " full-document context for fences and nested containers. Recognise inline
  " spans and derive layout before granting a paragraph any reflow policy.
  return {
        \ 'root': l:root,
        \ 'diagnostics': [{
        \   'code': 'parser_pending',
        \   'message': 'Markdown recognition is pending; all source is preserved.',
        \ }],
        \ }
endfunction

function! sembr#parser#markdown#Rules() abort
  " This map is keyed by node kind, not evaluated in Dictionary key order.
  " The tree visitor follows each container's ordered children instead.
  return {
        \ 'document': {'action': 'descend'},
        \ 'list': {'action': 'descend'},
        \ 'list_item': {'action': 'descend'},
        \ 'blockquote': {'action': 'descend'},
        \ 'paragraph': {'action': 'format'},
        \ 'fenced_code': {'action': 'preserve'},
        \ 'indented_code': {'action': 'preserve'},
        \ 'heading': {'action': 'preserve'},
        \ 'table': {'action': 'preserve'},
        \ 'html': {'action': 'preserve'},
        \ 'front_matter': {'action': 'preserve'},
        \ 'blank': {'action': 'preserve'},
        \ 'unknown': {'action': 'preserve'},
        \ }
endfunction

" Markdown reference adapter for SemBr.
"
" Supports CommonMark blocks and preserves selected Markdown extensions:
" front matter, display math, pipe tables, definition lists, footnotes,
" and MkDocs or GitHub alert admonitions.
"
" Some conservative assumptions are made here about the structure
" and formatting of the document and each line.
" These assumptions can be relaxed in future versions,
" once more sophisticated engine features are implemented.

function! s:fence_marker(line) abort
  return matchstr(a:line, '^ \{0,3}\zs\(```\+\|[~]\{3,}\)')

endfunction

function! s:is_fence_close(line, fence) abort
  let l:marker = s:fence_marker(a:line)
  let l:indent = matchstr(a:line, '^\s*')
  return !empty(l:marker)
        \ && l:marker[0] ==# a:fence[0]
        \ && strlen(l:marker) >= strlen(a:fence)
        \ && strpart(a:line, strlen(l:indent) + strlen(l:marker)) =~# '^\s*$'

endfunction

function! s:unmatched_object() abort
  return {
        \ 'matched': 0,
        \ 'kind': '',
        \ 'lines': [],
        \ 'complete': 0,
        \ 'safe': 0,
        \ }

endfunction

function! s:matched_object(kind, lines, complete, ...) abort
  return {
        \ 'matched': 1,
        \ 'kind': a:kind,
        \ 'lines': a:lines,
        \ 'complete': a:complete,
        \ 'safe': a:0 ? a:1 : 0,
        \ }

endfunction

function! s:unrecognised_block(lines, start_index) abort
  return s:matched_object('preserved', a:lines[a:start_index :], 1, 0)

endfunction

function! s:lookahead(lines, start, Stop, include, required) abort
  let l:result = [a:lines[a:start]]
  let l:index = a:start + 1

  while l:index < len(a:lines)
    let l:line = a:lines[l:index]
    if s:matches_stop(l:line, a:Stop)
      if a:include
        call add(l:result, l:line)
      endif
      return l:result
    endif

    call add(l:result, l:line)
    let l:index += 1
  endwhile

  return a:required ? [] : l:result

endfunction

function! s:matches_stop(line, Stop) abort
  if type(a:Stop) == type(function('tr'))
    return call(a:Stop, [a:line])
  endif

  return a:line =~# a:Stop

endfunction

function! s:parse_blank(line, _, _a, _b) abort
  if a:line =~# '^\s*$'
    return s:matched_object('blank', [a:line], 1)
  endif

  return s:unmatched_object()

endfunction

function! s:parse_heading(line, lines, start_index, _) abort
  " Parse a heading line
  "
  " Handles Markdown, ATX and Setext headings, e.g.:
  "   # Heading 1
  "
  "   ## Heading 2 ##
  "
  "   Heading 1
  "   ========
  "
  "   Heading 2
  "   --------
  if a:line =~# '^#\+\%(\s\|$\)'
    return s:matched_object('heading', [a:line], 1)
  endif

  " allow for ATX headings with closing hashes, e.g. "## Heading ##"
  if a:line =~# '^#\+\s\+\S.*\S\s*#\+$'
    return s:matched_object('heading', [a:line], 1)
  endif

  " allow for Setext headings, e.g. "Heading\n======" or "Heading\n------"
  if a:start_index + 1 < len(a:lines)
    let l:next_line = a:lines[a:start_index + 1]
    if l:next_line =~# '^\s*\(=\+\|-\+\)\s*$'
      return s:matched_object('heading', [a:line, l:next_line], 1)
    endif
  endif

  return s:unmatched_object()

endfunction

function! s:parse_code_block(line, lines, start_index, _) abort
  " Parse a code block starting at the current line.
  "
  " If the current line is a fence marker,
  " this parser will consume all lines until the next matching fence marker.
  let l:fence = s:fence_marker(a:line)

  if !empty(l:fence)
    let l:code_lines = [a:line]
    let l:index = a:start_index + 1

    if l:index >= len(a:lines)
      return s:unmatched_object()
    endif

    while l:index < len(a:lines)
      let l:next_line = a:lines[l:index]

      call add(l:code_lines, l:next_line)

      if s:is_fence_close(l:next_line, l:fence)
        return s:matched_object('code_block', l:code_lines, 1)
      endif

      let l:index += 1

    endwhile

    return s:unrecognised_block(a:lines, a:start_index)
  endif

  return s:unmatched_object()

endfunction

function! s:parse_indented_code_block(line, _, _a, _b) abort
  if a:line =~# '^\s\+'
    return s:matched_object('code_block', a:line, 0)
  endif

  return s:unmatched_object()

endfunction

function! s:is_front_matter_close(line) abort
  return a:line =~# '^---\s*$\|^\.\.\.\s*$'

endfunction

function! s:is_toml_front_matter_close(line) abort
  return a:line =~# '^+++\s*$'

endfunction

function! s:parse_front_matter(line, lines, start_index, _) abort
  if a:start_index == 0 && a:line =~# '^---\s*$\|^+++\s*$'
    let l:Stop = a:line =~# '^+++' ? function('s:is_toml_front_matter_close')
          \ : function('s:is_front_matter_close')
    let l:front_matter = s:lookahead(
          \ a:lines, a:start_index, l:Stop, 1, 1)
    if !empty(l:front_matter)
      return s:matched_object('front_matter', l:front_matter, 1)
    endif

    return s:unrecognised_block(a:lines, a:start_index)
  endif

  return s:unmatched_object()

endfunction

function! s:is_math_block_close(line) abort
  return a:line =~# '^\s*\$\$\s*$'

endfunction

function! s:parse_math_block(line, lines, start_index, _) abort
  if s:is_math_block_close(a:line)
    let l:math_block = s:lookahead(
          \ a:lines, a:start_index, function('s:is_math_block_close'), 1, 1)
    if !empty(l:math_block)
      return s:matched_object('math_block', l:math_block, 1)
    endif

    return s:unrecognised_block(a:lines, a:start_index)
  endif

  return s:unmatched_object()

endfunction

function! s:is_not_table_row(line) abort
  return a:line !~# '|'

endfunction

function! s:parse_table(line, lines, start_index, _) abort
  if a:line =~# '|' && a:start_index + 1 < len(a:lines)
    let l:separator = a:lines[a:start_index + 1]
    if l:separator =~# '^\s*|\?\s*:\?---\+:\?\s*\(|\s*:\?---\+:\?\s*\)*|\?\s*$'
      let l:table_lines = [a:line]
            \ + s:lookahead(
            \ a:lines, a:start_index + 1, function('s:is_not_table_row'), 0, 0)
      return s:matched_object('table', l:table_lines, 1)
    endif
  endif

  return s:unmatched_object()

endfunction

function! s:is_not_definition_line(line) abort
  return a:line !~# '^\s*:\s\+\S\|^\s\+'

endfunction

function! s:parse_definition_list(line, lines, start_index, _) abort
  if a:start_index + 1 < len(a:lines)
    let l:definition = a:lines[a:start_index + 1]
    if a:line =~# '^\S' && l:definition =~# '^\s*:\s\+\S'
      let l:lines = [a:line] + s:lookahead(
            \ a:lines, a:start_index + 1,
            \ function('s:is_not_definition_line'), 0, 0)
      return s:matched_object('definition_list', l:lines, 1)
    endif
  endif

  return s:unmatched_object()

endfunction

function! s:is_not_indented(line) abort
  return a:line !~# '^\s\+'

endfunction

function! s:parse_footnote(line, lines, start_index, _) abort
  if a:line =~# '^\[\^[^]]\+\]:\s\+\S'
    let l:lines = s:lookahead(
          \ a:lines, a:start_index, function('s:is_not_indented'), 0, 0)
    return s:matched_object('footnote', l:lines, 1)
  endif

  return s:unmatched_object()

endfunction

function! s:is_not_blockquote(line) abort
  return a:line !~# '^\s*>'

endfunction

function! s:parse_admonition(line, lines, start_index, _) abort
  if a:line =~# '^\s*!!!\s\+\S'
    let l:lines = s:lookahead(
          \ a:lines, a:start_index, function('s:is_not_indented'), 0, 0)
    return s:matched_object('admonition', l:lines, 1)
  endif

  if a:line =~# '^\s*>\s*\[!\%(NOTE\|TIP\|IMPORTANT\|WARNING\|CAUTION\)\]'
    let l:lines = s:lookahead(
          \ a:lines, a:start_index, function('s:is_not_blockquote'), 0, 0)
    return s:matched_object('admonition', l:lines, 1)
  endif

  return s:unmatched_object()

endfunction

function! s:is_blank(line) abort
  return a:line =~# '^\s*$'

endfunction

function! s:html_block_close_pattern(line) abort
  if a:line =~# '^\s*<!--'
    return '-->'
  endif
  if a:line =~# '^\s*<?'
    return '?>'
  endif
  if a:line =~# '^\s*<!\[CDATA\['
    return '\]\]>'
  endif
  if a:line =~# '^\s*<![A-Z]'
    return '>'
  endif
  if a:line =~? '^\s*</\?\%(script\|pre\|style\|textarea\)\%(\s\|>\)'
    return '</\s*\%(script\|pre\|style\|textarea\)\s*>'
  endif

  return ''

endfunction

function! s:is_html_block_tag(line) abort
  let l:tags = '\%(address\|article\|aside\|base\|basefont\|blockquote\|body'
        \ . '\|caption\|center\|col\|colgroup\|dd\|details\|dialog\|dir\|div'
        \ . '\|dl\|dt\|fieldset\|figcaption\|figure\|footer\|form\|h[1-6]'
        \ . '\|head\|header\|hr\|html\|iframe\|legend\|li\|link\|main\|menu'
        \ . '\|menuitem\|nav\|ol\|p\|picture\|plaintext\|section\|summary'
        \ . '\|table\|tbody\|td\|tfoot\|th\|thead\|title\|tr\|track\|ul\|wbr\)'
  return a:line =~? '^\s*</\?' . l:tags . '\%(\s\|/\?>\|$\)'

endfunction

function! s:parse_html_block(line, lines, start_index, _) abort
  let l:close = s:html_block_close_pattern(a:line)
  if !empty(l:close)
    if a:line =~? l:close
      return s:matched_object('html_block', [a:line], 1)
    endif

    let l:lines = s:lookahead(a:lines, a:start_index, l:close, 1, 1)
    if !empty(l:lines)
      return s:matched_object('html_block', l:lines, 1)
    endif

    return s:unrecognised_block(a:lines, a:start_index)
  endif

  if s:is_html_block_tag(a:line)
    let l:lines = s:lookahead(
          \ a:lines, a:start_index, function('s:is_blank'), 0, 0)
    return s:matched_object('html_block', l:lines, 1)
  endif

  return s:unmatched_object()

endfunction

function! s:parse_paragraph(line, _, _a, previous_line_kind) abort
  " Parse a paragraph starting at the current line.
  "
  " The first character needs to be a non-whitespace A-Z or a-z character.
  if a:line =~# '^\s*[A-Za-z]'
    return s:matched_object('paragraph', a:line, 0, 1)
  endif

  " Allow for paragraphs that are continued from the previous line.
  " Lists should have a blank line between them and the paragraph.
  " images and lines, may be continued without a blank line.
  if a:previous_line_kind ==# 'paragraph' && a:line =~# '^\s*\S'
    return s:matched_object('paragraph', a:line, 0, 1)
  endif

  return s:unmatched_object()

endfunction

function! s:parse_list(line, _, _a, previous_line_kind) abort
  " Parse a list starting at the current line.
  if a:line =~# '^\s*\%([-*+]\|\d\+[.)]\)\%(\s\|$\)'
    return s:matched_object('list', a:line, 0)
  endif

  " Allow for lists that are continued from the previous line.
  if a:previous_line_kind ==# 'list' && a:line =~# '^\s*\S'
    return s:matched_object('list', a:line, 0)
  endif

  return s:unmatched_object()

endfunction

function! s:parse_blockquote(line, _, _a, _b) abort
  " Parse a blockquote starting at the current line.
  if a:line =~# '^\s*>'
    return s:matched_object('blockquote', a:line, 0)
  endif

  return s:unmatched_object()

endfunction

function! s:parse_thematic_break(line, _, _a, _b) abort
  if a:line =~# '^\s\{0,3}\%(-\s*\)\{3,}$'
        \ || a:line =~# '^\s\{0,3}\%(\*\s*\)\{3,}$'
        \ || a:line =~# '^\s\{0,3}\%(_\s*\)\{3,}$'
    return s:matched_object('thematic_break', [a:line], 1)
  endif

  return s:unmatched_object()

endfunction

function! s:preserved_block(line) abort
    " Return a match object for a line that should be preserved.
    return {
          \ 'matched': 0,
          \ 'kind': 'preserved',
          \ 'lines': a:line,
          \ 'complete': 0,
          \ 'safe': 0,
          \ }

endfunction

function! s:match_block(line, lines, start_index, previous_line_kind) abort
  for l:Parser in [
          \ function('s:parse_blank'),
          \ function('s:parse_front_matter'),
          \ function('s:parse_code_block'),
          \ function('s:parse_math_block'),
          \ function('s:parse_indented_code_block'),
          \ function('s:parse_table'),
          \ function('s:parse_definition_list'),
          \ function('s:parse_footnote'),
          \ function('s:parse_admonition'),
          \ function('s:parse_list'),
          \ function('s:parse_heading'),
          \ function('s:parse_html_block'),
          \ function('s:parse_blockquote'),
          \ function('s:parse_thematic_break'),
          \ ]
    let l:result = call(
            \ l:Parser,
            \ [
            \   a:line,
            \   a:lines,
            \   a:start_index,
            \   a:previous_line_kind,
            \ ])

    if l:result.matched
      return l:result
    endif
  endfor

  return s:unmatched_object()

endfunction

function! s:formatted_lines(lines) abort
  return split(join(a:lines, ' '), '\([.!?]\)\@<=\s\+')

endfunction

function! s:paragraph_is_safe(lines) abort
  if len(a:lines) > 1
    for l:line in a:lines[0 : -2]
      if l:line =~# ' \{2,}$\|\\$'
        return 0
      endif
    endfor
  endif

  let l:lines = s:formatted_lines(a:lines)
  for l:index in range(len(l:lines))
    if l:lines[l:index] =~# '^\s*+++\s*$'
          \ || s:match_block(l:lines[l:index], l:lines, l:index, '').matched
      return 0
    endif
  endfor

  return 1

endfunction

function! s:parse_next_line(line, lines, start_index, previous_line_kind) abort
  " Parse the next block of lines, returning a match object.
  let l:match = s:match_block(
        \ a:line, a:lines, a:start_index, a:previous_line_kind)
  if l:match.matched
    return l:match
  endif

  let l:match = s:parse_paragraph(
        \ a:line, a:lines, a:start_index, a:previous_line_kind)
  if l:match.matched
    return l:match
  endif

  return s:preserved_block(a:line)

endfunction

function! s:list_node(start_line, lines) abort
  " A list node's children are its individual, unformatted item lines.
  let l:children = []
  for l:offset in range(len(a:lines))
    let l:line = a:start_line + l:offset
    call add(l:children, sembr#models#Node({
          \ 'kind': 'list_item',
          \ 'start': [l:line, 0],
          \ 'end': [l:line, 0],
          \ 'lines': [a:lines[l:offset]],
          \ 'safe': 0,
          \ }))
  endfor

  return sembr#models#Node({
        \ 'kind': 'list',
        \ 'start': [a:start_line, 0],
        \ 'end': [a:start_line + len(a:lines) - 1, 0],
        \ 'children': l:children,
        \ 'safe': 0,
        \ })

endfunction

function! s:leaf_node(kind, start_line, lines, safe) abort
  return sembr#models#Node({
        \ 'kind': a:kind,
        \ 'start': [a:start_line, 0],
        \ 'end': [a:start_line + len(a:lines) - 1, 0],
        \ 'lines': a:lines,
        \ 'safe': a:safe,
        \ })

endfunction

function! sembr#parser#markdown#Parse(document) abort
  " Build a nested tree from a document snapshot (see sembr#document#Document).
  " Consecutive lines of the same kind are grouped into a single node,
  " 'code_block' spans both fenced and indented runs,
  " and 'list' nesting one 'list_item' child per line.
  "
  " Parameters:
  "   document: a snapshot from sembr#document#Document
  "
  " Returns:
  "   a tree of nodes, each {
  "     kind: the kind of node (see sembr#parser#markdown#Rules)
  "     start: the start position of the node [line, column] (0-indexed)
  "     end: the end position of the node [line, column] (0-indexed)
  "     safe: whether formatting the node preserves Markdown structure
  "     lines: the lines of the node (only for leaf nodes)
  "     children: the child nodes of the node (only for non-leaf nodes)
  "     }
  let l:children = []
  let l:kind = ''
  let l:start_line = 0
  let l:buffer = []
  let l:safe = 1

  let l:index = 0
  while l:index < len(a:document.lines)
    let l:line = a:document.lines[l:index]

    let l:match = s:parse_next_line(l:line, a:document.lines, l:index, l:kind)

    if l:match.matched && l:match.complete
      " check to see if the buffer is empty, if not, add it to the children
      if !empty(l:buffer)
        call add(l:children,
              \ l:kind ==# 'list' ? s:list_node(l:start_line, l:buffer)
              \                   : s:leaf_node(
              \                       l:kind,
              \                       l:start_line,
              \                       l:buffer,
              \                       l:safe && (l:kind !=# 'paragraph'
              \                         || s:paragraph_is_safe(l:buffer))))
        let l:buffer = []
        let l:safe = 1
      endif

      " If the match is complete, add it to the children and reset the buffer.
      call add(l:children, s:leaf_node(
            \ l:match.kind, l:index, l:match.lines, l:match.safe))
      let l:index += len(l:match.lines)
      let l:start_line = l:index
      let l:kind = ''
      continue
    endif

    if l:kind !=# l:match.kind && !empty(l:buffer)
      call add(l:children,
            \ l:kind ==# 'list' ? s:list_node(l:start_line, l:buffer)
            \                   : s:leaf_node(
            \                       l:kind,
            \                       l:start_line,
            \                       l:buffer,
            \                       l:safe && (l:kind !=# 'paragraph'
            \                         || s:paragraph_is_safe(l:buffer))))
      let l:buffer = []
      let l:safe = 1
    endif

    if empty(l:buffer)
      let l:start_line = l:index
    endif

    let l:kind = l:match.kind
    call add(l:buffer, l:match.lines)
    let l:safe = l:safe && l:match.safe

    let l:index += 1
  endwhile

  if !empty(l:buffer)
    call add(l:children,
          \ l:kind ==# 'list' ? s:list_node(l:start_line, l:buffer)
          \                   : s:leaf_node(
          \                       l:kind,
          \                       l:start_line,
          \                       l:buffer,
          \                       l:safe && (l:kind !=# 'paragraph'
          \                         || s:paragraph_is_safe(l:buffer))))
  endif

  return sembr#models#Node({
        \ 'kind': 'document',
        \ 'start': [0, 0],
        \ 'end': [max([len(a:document.lines) - 1, 0]), 0],
        \ 'children': l:children,
        \ 'safe': 0,
        \ })

endfunction

function! sembr#parser#markdown#Rules() abort
  " Preserve blocks from Markdown extensions as well as CommonMark blocks.
  return {
        \ 'document': {'action': 'descend'},
        \ 'list': {'action': 'descend'},
        \ 'list_item': {'action': 'preserve'},
        \ 'code_block': {'action': 'preserve'},
        \ 'front_matter': {'action': 'preserve'},
        \ 'math_block': {'action': 'preserve'},
        \ 'table': {'action': 'preserve'},
        \ 'definition_list': {'action': 'preserve'},
        \ 'footnote': {'action': 'preserve'},
        \ 'admonition': {'action': 'preserve'},
        \ 'html_block': {'action': 'preserve'},
        \ 'blockquote': {'action': 'preserve'},
        \ 'thematic_break': {'action': 'preserve'},
        \ 'heading': {'action': 'preserve'},
        \ 'blank': {'action': 'preserve'},
        \ 'paragraph': {'action': 'format'},
        \ 'preserved': {'action': 'preserve'},
        \ }

endfunction

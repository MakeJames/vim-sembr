" Parsers share a common interface so that they can be used interchangeably.
" Each parser must implement the following functions:
"   - Parse: which translates bare lists of lines into the structured tree
"   - Rules: which returns the rules and key names of the parser
"
" The Rules govern how SemBr should apply the SemBr standard to the text.
" eg:
"   {
"     'document': {'pattern': s:function, 'action': 'descend'},
"     'paragraph': {'pattern': s:function, 'action': 'format'},
"     'codeblock': {'pattern': s:function, 'action': 'preserve'}
"   }
"
" The rules' action can be one of the following:
"  - 'descend': descend into the node and apply the rules to its children
"  - 'format': format the node's text according to the SemBr standard
"  - 'preserve': preserve the node's text as-is, without any formatting

function! sembr#parser#For(filetype) abort
  " Select the parser for a document's filetype. Returns a dict with
  " 'Parse' and 'Rules' funcrefs (see the interface described above).
  "
  " Filetypes without a dedicated parser fall back to a parser that treats
  " the whole document as a single preserved node, so SemBr is a no-op on
  " unsupported filetypes rather than erroring or mangling unknown syntax.
  if a:filetype ==# 'markdown'
    return {
          \ 'Parse': function('sembr#parser#markdown#Parse'),
          \ 'Rules': function('sembr#parser#markdown#Rules'),
          \ }
  endif

  return {
        \ 'Parse': function('sembr#parser#fallback#Parse'),
        \ 'Rules': function('sembr#parser#fallback#Rules'),
        \ }
endfunction

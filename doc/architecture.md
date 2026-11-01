# Parser and orchestration reference

This is an executable design sketch alongside the existing `:SemBr` path.
The new API builds an inspectable plan. Markdown recognition, semantic edit
generation, and applying a plan are stubs. `:SemBr` still uses the original
implementation; the conservative guarantees below belong to the new API.

## Try a plan

With this plugin on `runtimepath`, open a Markdown buffer and run:

```vim
let document = sembr#orchestrator#Snapshot(bufnr('%'), 1, line('$'))
let plan = sembr#orchestrator#Plan(document, {'width': 80})
echo plan.root
echo plan.diagnostics
```

`Snapshot()` always captures the whole buffer for parsing context. Its inclusive
line arguments specify the permitted selection independently. `Plan()` returns
no edits while recognition and formatting are pending. Unsupported filetypes
produce an `unsupported_filetype` diagnostic and a preserved document.
`Apply()` explicitly throws until the mutation safeguards are implemented.

## Objects and ownership

Positions are `[one_based_line, zero_based_byte_offset]`; range ends are
exclusive. `[len(lines) + 1, 0]` is the end-of-document sentinel. Source offsets
are independent of display columns, which the formatter will use for width.

| Object | Fields | Ownership |
| --- | --- | --- |
| Document snapshot | `bufnr`, `changedtick`, `filetype`, `lines`, `selection` | Read-only source for every pass |
| Region | `kind`, `range`, `handling`, `policy`, `layout`, `children` | Parser output; source remains in the snapshot |
| Tree selection | `regions`, `diagnostics` | Copies of eligible prose leaves |
| Edit | `range`, `replacement` | Future engine output against original coordinates |
| Plan | `snapshot`, `root`, `regions`, `edits`, `diagnostics` | Inspectable result before mutation |

`handling` is `container`, `reflow`, or `preserve`. A `preserve` node protects its
entire subtree. `children` are an ordered List in source order. A parser must
account for all source, including blank and uncertain regions, keep siblings
non-overlapping, and contain every child inside its parent. These structural
invariants still need validation before the experimental path can apply edits.

Regions use `policy.join_soft_breaks` and `policy.insert_soft_breaks` to grant
specific whitespace changes; absent permissions are false. A paragraph's
`layout.first_prefix` and `layout.continuation_prefix` will record its output
prefixes. The parser must derive those from enclosing list/quote context before
granting permission. Protected inline content and hard breaks will require a
finer span/boundary model before real formatting is enabled.

Functions read their inputs and return new output objects. Vimscript does not
enforce this convention. The orchestration boundary uses `deepcopy()` to isolate
the caller's snapshot; the visitor copies selected regions. No function here
writes to the source buffer. Avoid accidentally mutating shared Dictionaries
or Lists when adding rules.

## Filetype adapter contract

`sembr#parser#Resolve(filetype)` returns a Dictionary containing two Funcrefs:

```vim
{
      \ 'Parse': function('sembr#parser#markdown#Parse'),
      \ 'Rules': function('sembr#parser#markdown#Rules'),
      \ }
```

`Parse(document)` returns `{'root': region, 'diagnostics': [...]}`. It recognises
syntax with full source context. The Markdown stub currently returns a document
containing one preserved `unknown` region spanning the entire source. It does
not claim any Markdown construct has been recognised.

`Rules()` returns a map keyed by node kind. The complete reference is in
[`autoload/sembr/parser/markdown.vim`](../autoload/sembr/parser/markdown.vim):

```vim
{
      \ 'document': {'action': 'descend'},
      \ 'list_item': {'action': 'descend'},
      \ 'paragraph': {'action': 'format'},
      \ 'fenced_code': {'action': 'preserve'},
      \ }
```

`sembr#tree#Select(root, rules, selection)` executes the map across the tree:

- `descend` visits a container's children in their source order.
- `format` selects a prose leaf only when the parser grants reflow permission.
- `preserve` stops traversal at that node.
- Unmapped kinds default to `preserve`; an unknown action is an error.

The map cannot override a parser's protection. Selection never expands beyond
the requested range: a prose region crossing either edge is skipped with a
`partial_region` diagnostic. Dictionary key order does not define precedence.

## Markdown thought experiment

Consider a document containing a prose paragraph, a fenced code block, then a
list item with a prose paragraph. A future parser would produce these paths:

| Path through the tree | Map execution |
| --- | --- |
| document / paragraph | Descend, then select permitted prose |
| document / fenced_code | Descend, then preserve the entire fence |
| document / list / list_item / paragraph | Descend through containers, then select prose with inherited layout |

The same rules apply at every depth. List markers and indentation belong to
parser-derived layout; the shared engine works with the permitted prose.

Recognition and tree evaluation are distinct passes. This map describes what
to do with recognised nodes; it cannot recognise Markdown from raw text.
Markdown recognition needs state for fence delimiters, nested containers, and
inline constructs. An ordered recognition-rule List could be introduced inside
the Markdown parser when that pass is built. It should preserve ambiguous input
and identify the chosen dialect and extensions explicitly.

The shared engine will represent safe whitespace gaps as boundaries with
`allowed`, `required`, and `split_cost` fields. It will select breaks while
honouring protected spans, hard breaks, layout, and width. Filetype-specific
serialisation must preserve markup semantics before an Edit is proposed.

## Completing the mutation path

Before wiring this API into `:SemBr`, implement Markdown recognition and inline
protection, source/tree validation, semantic edit generation and serialisation,
and edit validation. Applying must reject a changed `changedtick`, invalid or
overlapping ranges, and edits outside the selection. Apply valid edits from the
end of the buffer and join them into one undo operation. Test undo and failure
behaviour before enabling it; the current `Apply()` deliberately raises an error.

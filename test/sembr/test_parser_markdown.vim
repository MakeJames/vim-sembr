function! SemBrParserMarkdownTestDocument(lines) abort
  return {'lines': a:lines}
endfunction

describe 'sembr#parser#markdown#Rules'
  it 'maps each node kind to its action'
    Expect sembr#parser#markdown#Rules() ==# {
          \ 'document': {'action': 'descend'},
          \ 'list': {'action': 'descend'},
          \ 'list_item': {'action': 'preserve'},
          \ 'code_block': {'action': 'preserve'},
          \ 'blockquote': {'action': 'preserve'},
          \ 'heading': {'action': 'preserve'},
          \ 'blank': {'action': 'preserve'},
          \ 'paragraph': {'action': 'format'},
          \ 'preserved': {'action': 'preserve'},
          \ }
  end
end

describe 'sembr#parser#markdown#Parse'
  it 'builds a single paragraph node for an unbroken prose run'
    let document = SemBrParserMarkdownTestDocument([
          \ 'One sentence. A second sentence! Is this the third?'
          \ ])
    let tree = sembr#parser#markdown#Parse(document)

    Expect tree ==# {
          \ 'kind': 'document',
          \ 'start': [0, 0],
          \ 'end': [0, 0],
          \ 'children': [
          \   {
          \     'kind': 'paragraph',
          \     'start': [0, 0],
          \     'end': [0, 0],
          \     'lines': ['One sentence. A second sentence! Is this the third?'],
          \   },
          \ ],
          \ }
  end

  it 'nests list items under a single list node'
    let document = SemBrParserMarkdownTestDocument([
          \ '- first unpunctuated item',
          \ '- second unpunctuated item',
          \ ])
    let tree = sembr#parser#markdown#Parse(document)

    Expect tree.children ==# [{
          \ 'kind': 'list',
          \ 'start': [0, 0],
          \ 'end': [1, 0],
          \ 'children': [
          \   {
          \     'kind': 'list_item',
          \     'start': [0, 0],
          \     'end': [0, 0],
          \     'lines': ['- first unpunctuated item'],
          \   },
          \   {
          \     'kind': 'list_item',
          \     'start': [1, 0],
          \     'end': [1, 0],
          \     'lines': ['- second unpunctuated item'],
          \   },
          \ ],
          \ }]
  end

  it 'groups paragraph, list, and code runs into separate nodes'
    let document = SemBrParserMarkdownTestDocument([
          \ 'The first paragraph spans',
          \ 'multiple lines.',
          \ '',
          \ '- first unpunctuated item',
          \ '- second unpunctuated item',
          \ '    let value = 1',
          \ '    let next_value = value + 1',
          \ '',
          \ 'The second paragraph. Another sentence!',
          \ ])
    let tree = sembr#parser#markdown#Parse(document)

    Expect map(copy(tree.children), 'v:val.kind')
          \ ==# ['paragraph', 'blank', 'list', 'code_block', 'blank', 'paragraph']
    Expect tree.children[0].lines
          \ ==# ['The first paragraph spans', 'multiple lines.']
    Expect tree.children[3].lines
          \ ==# ['    let value = 1', '    let next_value = value + 1']
  end

  it 'groups a heading and fenced code block as preserved leaves'
    let document = SemBrParserMarkdownTestDocument([
          \ '# Heading',
          \ 'Prose sentence. Another sentence!',
          \ '',
          \ '```vim',
          \ 'let value = 1',
          \ 'let next_value = value + 1',
          \ '```',
          \ ])
    let tree = sembr#parser#markdown#Parse(document)

    Expect map(copy(tree.children), 'v:val.kind')
          \ ==# ['heading', 'paragraph', 'blank', 'code_block']
    Expect tree.children[3].lines ==# [
          \ '```vim',
          \ 'let value = 1',
          \ 'let next_value = value + 1',
          \ '```',
          \ ]
  end

  it 'does not open a fence indented by four spaces'
    let document = SemBrParserMarkdownTestDocument([
          \ 'Introductory prose.',
          \ '    ```',
          \ 'Prose sentence. Another sentence!',
          \ ])
    let tree = sembr#parser#markdown#Parse(document)

    Expect map(copy(tree.children), 'v:val.kind')
          \ ==# ['paragraph', 'code_block', 'paragraph']
  end

  it 'preserves indented fence markers inside fenced code blocks'
    let document = SemBrParserMarkdownTestDocument([
          \ '```vim',
          \ '    ```',
          \ 'gamma. delta!',
          \ '```',
          \ 'Closing prose. Final sentence?',
          \ ])
    let tree = sembr#parser#markdown#Parse(document)

    Expect map(copy(tree.children), 'v:val.kind')
          \ ==# ['code_block', 'paragraph']
    Expect tree.children[0].lines ==# [
          \ '```vim',
          \ '    ```',
          \ 'gamma. delta!',
          \ '```',
          \ ]
  end

  it 'preserves tilde fences'
    let document = SemBrParserMarkdownTestDocument([
          \ '~~~vim',
          \ 'let value = 1',
          \ '~~~',
          \ 'Prose sentence.',
          \ ])
    let tree = sembr#parser#markdown#Parse(document)

    Expect map(copy(tree.children), 'v:val.kind')
          \ ==# ['code_block', 'paragraph']
    Expect tree.children[0].lines ==# ['~~~vim', 'let value = 1', '~~~']
  end

  it 'returns an empty document for no lines'
    let tree = sembr#parser#markdown#Parse(SemBrParserMarkdownTestDocument([]))

    Expect tree ==# {'kind': 'document', 'start': [0, 0], 'end': [0, 0], 'children': []}
  end
end

describe 'sembr#engine#Plan'
  it 'plans an edit for a paragraph node inside the selection'
    let tree = {
          \ 'type': 'document',
          \ 'start': [0, 0],
          \ 'end': [0, 0],
          \ 'children': [{
          \   'type': 'paragraph',
          \   'start': [0, 0],
          \   'end': [0, 0],
          \   'lines': ['One sentence. A second sentence!'],
          \ }],
          \ }
    let rules = sembr#parser#markdown#Rules()
    let selection = {'start': [0, 0], 'end': [0, 0]}

    Expect sembr#engine#Plan(tree, rules, selection) ==# [{
          \ 'start': [0, 0],
          \ 'end': [0, 0],
          \ 'lines': ['One sentence.', 'A second sentence!'],
          \ }]
  end

  it 'plans no edit for a paragraph node outside the selection'
    let tree = {
          \ 'type': 'document',
          \ 'start': [0, 0],
          \ 'end': [1, 0],
          \ 'children': [
          \   {
          \     'type': 'paragraph',
          \     'start': [0, 0],
          \     'end': [0, 0],
          \     'lines': ['Outside. Sentence two!'],
          \   },
          \   {
          \     'type': 'paragraph',
          \     'start': [1, 0],
          \     'end': [1, 0],
          \     'lines': ['Inside. Sentence two!'],
          \   },
          \ ],
          \ }
    let rules = sembr#parser#markdown#Rules()
    let selection = {'start': [1, 0], 'end': [1, 0]}

    Expect sembr#engine#Plan(tree, rules, selection) ==# [{
          \ 'start': [1, 0],
          \ 'end': [1, 0],
          \ 'lines': ['Inside.', 'Sentence two!'],
          \ }]
  end

  it 'plans no edits for code_block, heading, blank, and list_item nodes'
    let tree = sembr#parser#markdown#Parse({'lines': [
          \ '# Heading',
          \ '',
          \ '- item one',
          \ '```vim',
          \ 'let value = 1',
          \ '```',
          \ ]})
    let rules = sembr#parser#markdown#Rules()
    let selection = {'start': [0, 0], 'end': [5, 0]}

    Expect sembr#engine#Plan(tree, rules, selection) ==# []
  end

  it 'plans no edit for a type missing from the rules'
    let tree = {
          \ 'type': 'document',
          \ 'start': [0, 0],
          \ 'end': [0, 0],
          \ 'children': [{
          \   'type': 'mystery',
          \   'start': [0, 0],
          \   'end': [0, 0],
          \   'lines': ['untouched line'],
          \ }],
          \ }

    Expect sembr#engine#Plan(tree, {'document': {'action': 'descend'}}, {'start': [0, 0], 'end': [0, 0]})
          \ ==# []
  end

  it 'plans edits for the full sample document end to end'
    let tree = sembr#parser#markdown#Parse({'lines': [
          \ '# Steps',
          \ 'Introductory prose. Another sentence!',
          \ '1. First item. Keep this line unchanged.',
          \ '2. Second item.',
          \ '    let value = 1',
          \ '```vim',
          \ 'let next_value = value + 1',
          \ '```',
          \ 'Closing prose. Final sentence?',
          \ ]})
    let rules = sembr#parser#markdown#Rules()
    let selection = {'start': [0, 0], 'end': [8, 0]}

    Expect sembr#engine#Plan(tree, rules, selection) ==# [
          \ {'start': [1, 0], 'end': [1, 0], 'lines': ['Introductory prose.', 'Another sentence!']},
          \ {'start': [8, 0], 'end': [8, 0], 'lines': ['Closing prose.', 'Final sentence?']},
          \ ]
  end

  it 'rejects overlapping edits from a buggy parser with overlapping siblings'
    let tree = {
          \ 'type': 'document',
          \ 'start': [0, 0],
          \ 'end': [0, 0],
          \ 'children': [
          \   {'type': 'paragraph', 'start': [0, 0], 'end': [0, 0], 'lines': ['One. Two!']},
          \   {'type': 'paragraph', 'start': [0, 0], 'end': [0, 0], 'lines': ['One. Two!']},
          \ ],
          \ }
    let rules = sembr#parser#markdown#Rules()
    let selection = {'start': [0, 0], 'end': [0, 0]}

    Expect expr { sembr#engine#Plan(tree, rules, selection) }
          \ to_throw 'sembr: overlapping edits'
  end

  it 'rejects edits that only touch at a shared boundary line'
    " A two-line paragraph node ending on line 1, immediately followed by a
    " sibling node that (incorrectly) starts on that same line 1.
    let tree = {
          \ 'type': 'document',
          \ 'start': [0, 0],
          \ 'end': [1, 0],
          \ 'children': [
          \   {'type': 'paragraph', 'start': [0, 0], 'end': [1, 0], 'lines': ['One.', 'Two!']},
          \   {'type': 'paragraph', 'start': [1, 0], 'end': [1, 0], 'lines': ['Two!']},
          \ ],
          \ }
    let rules = sembr#parser#markdown#Rules()
    let selection = {'start': [0, 0], 'end': [1, 0]}

    Expect expr { sembr#engine#Plan(tree, rules, selection) }
          \ to_throw 'sembr: overlapping edits'
  end

  it 'does not throw for edits on immediately adjacent, non-overlapping lines'
    let tree = {
          \ 'type': 'document',
          \ 'start': [0, 0],
          \ 'end': [1, 0],
          \ 'children': [
          \   {'type': 'paragraph', 'start': [0, 0], 'end': [0, 0], 'lines': ['One. Two!']},
          \   {'type': 'paragraph', 'start': [1, 0], 'end': [1, 0], 'lines': ['Three. Four!']},
          \ ],
          \ }
    let rules = sembr#parser#markdown#Rules()
    let selection = {'start': [0, 0], 'end': [1, 0]}

    Expect sembr#engine#Plan(tree, rules, selection) ==# [
          \ {'start': [0, 0], 'end': [0, 0], 'lines': ['One.', 'Two!']},
          \ {'start': [1, 0], 'end': [1, 0], 'lines': ['Three.', 'Four!']},
          \ ]
  end
end

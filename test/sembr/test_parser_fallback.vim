" Fallback parser tests

describe 'sembr#parser#fallback#Rules'
  it 'preserves the whole document'
    Expect sembr#parser#fallback#Rules() ==# {
          \   'document': {
          \     'action': 'preserve'
          \   }
          \ }
  end
end

describe 'sembr#parser#fallback#Parse'
  it 'wraps every line in a single preserved document node'
    let document = {'lines': ['one', 'two', 'three']}

    let expected = sembr#models#Node({
          \ 'kind': 'document',
          \ 'start': [0, 0],
          \ 'end': [2, 0],
          \ 'children': [],
          \ 'lines': ['one', 'two', 'three'],
          \ 'safe': 0,
          \ })

    Expect sembr#parser#fallback#Parse(document) ==# expected
  end

  it 'handles a document with no lines'
    let expected = sembr#models#Node({
          \ 'kind': 'document',
          \ 'start': [0, 0],
          \ 'end': [0, 0],
          \ 'children': [],
          \ 'lines': [],
          \ 'safe': 0,
          \ })

    Expect sembr#parser#fallback#Parse({'lines': []}) ==# expected
  end
end

describe 'sembr#parser#fallback#Rules'
  it 'preserves the whole document'
    Expect sembr#parser#fallback#Rules() ==# {'document': {'action': 'preserve'}}
  end
end

describe 'sembr#parser#fallback#Parse'
  it 'wraps every line in a single preserved document node'
    let document = {'lines': ['one', 'two', 'three']}

    Expect sembr#parser#fallback#Parse(document) ==# {
          \ 'kind': 'document',
          \ 'start': [0, 0],
          \ 'end': [2, 0],
          \ 'lines': ['one', 'two', 'three'],
          \ }
  end

  it 'handles a document with no lines'
    Expect sembr#parser#fallback#Parse({'lines': []}) ==# {
          \ 'kind': 'document',
          \ 'start': [0, 0],
          \ 'end': [0, 0],
          \ 'lines': [],
          \ }
  end
end

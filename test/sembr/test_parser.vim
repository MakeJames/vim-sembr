describe 'sembr#parser#For'
  it 'selects the markdown parser for markdown documents'
    let parser = sembr#parser#For('markdown')

    Expect parser.Parse ==# function('sembr#parser#markdown#Parse')
    Expect parser.Rules ==# function('sembr#parser#markdown#Rules')
  end

  it 'falls back to the no-op parser for an unsupported filetype'
    let parser = sembr#parser#For('python')

    Expect parser.Parse ==# function('sembr#parser#fallback#Parse')
    Expect parser.Rules ==# function('sembr#parser#fallback#Rules')
  end

  it 'falls back to the no-op parser for an empty filetype'
    let parser = sembr#parser#For('')

    Expect parser.Parse ==# function('sembr#parser#fallback#Parse')
    Expect parser.Rules ==# function('sembr#parser#fallback#Rules')
  end
end

" Test the validation of models in Vim

describe 'Node Model Validation'
  it 'should successfully allow an empty model'
    let case = {}
    let expected = {
        \ 'kind': '',
        \ 'start': [0, 0],
        \ 'end': [0, 0],
        \ 'children': [],
        \ 'lines': [],
        \ 'safe': 0,
        \ }

    Expect sembr#models#Node(case) ==# expected

  end
end

describe 'Node Model Validation: kind'

  it 'should accept an empty string for kind'
    let case = {'kind': ''}

    Expect sembr#models#Node(case) ==# {
        \ 'kind': '',
        \ 'start': [0, 0],
        \ 'end': [0, 0],
        \ 'children': [],
        \ 'lines': [],
        \ 'safe': 0,
        \ }
  end

  it 'should accept a string for kind'
    let case = {'kind': 'string'}

    Expect sembr#models#Node(case) ==# {
        \ 'kind': 'string',
        \ 'start': [0, 0],
        \ 'end': [0, 0],
        \ 'children': [],
        \ 'lines': [],
        \ 'safe': 0,
        \ }
  end

  it 'should thow an error when kind is a number'
    let case = {'kind': 1}

    Expect expr { sembr#models#Node(case) }
        \ to_throw 'sembr: invalid string value: 1, must be a string.'
  end

  it 'should thow an error when kind is a list'
    let case = {'kind': []}

    Expect expr { sembr#models#Node(case) }
        \ to_throw 'sembr: invalid string value: [], must be a string.'
  end

  it 'should thow an error when kind is a dict'
    let case = {'kind': {}}

    Expect expr { sembr#models#Node(case) }
        \ to_throw 'sembr: invalid string value: {}, must be a string.'
  end

end

describe 'Node Model Validation: safe flag'

  it 'should thow an error when safe is 2'
    let case = {'safe': 2}

    Expect expr { sembr#models#Node(case) }
        \ to_throw 'sembr: invalid flag value: 2, must be 0 or 1.'
  end

  it 'should thow an error when safe is -1'
    let case = {'safe': -1}

    Expect expr { sembr#models#Node(case) }
        \ to_throw 'sembr: invalid flag value: -1, must be 0 or 1.'
  end

  it 'should thow an error when safe is a string'
    let case = {'safe': 'string'}

    Expect expr { sembr#models#Node(case) }
        \ to_throw 'sembr: invalid flag value: ''string'', must be 0 or 1.'
  end

  it 'should thow an error when safe is a float'
    let case = {'safe': 1.5}

    Expect expr { sembr#models#Node(case) }
        \ to_throw 'sembr: invalid flag value: 1.5, must be 0 or 1.'
  end

  it 'should pass when safe is 0'
    let case = {'safe': 0}
    let expected = {
        \ 'kind': '',
        \ 'start': [0, 0],
        \ 'end': [0, 0],
        \ 'children': [],
        \ 'lines': [],
        \ 'safe': 0,
        \ }

    Expect sembr#models#Node(case) ==# expected
  end

  it 'should pass when safe is 1'
    let case = {'safe': 1}
    let expected = {
        \ 'kind': '',
        \ 'start': [0, 0],
        \ 'end': [0, 0],
        \ 'children': [],
        \ 'lines': [],
        \ 'safe': 1,
        \ }

    Expect sembr#models#Node(case) ==# expected
  end

end

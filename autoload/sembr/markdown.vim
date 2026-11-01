function! sembr#markdown#protected_ranges(text) abort
  let l:pattern = '\%(!\?\[[^]]*\](\([^()]*(\([^()]*\)[^()]*)*\|[^()]*\))\|<[^>]*>\|`\+[^`]*`\+\|\*\{1,3}[^*]\+\*\{1,3}\|_\{1,3}[^_]\+_\{1,3}\)'
  let l:ranges = []
  let l:offset = 0

  while l:offset < strlen(a:text)
    let l:start = match(a:text, l:pattern, l:offset)
    if l:start < 0
      break
    endif

    let l:end = matchend(a:text, l:pattern, l:start)
    call add(l:ranges, [l:start, l:end])
    let l:offset = l:end
  endwhile

  return l:ranges
endfunction

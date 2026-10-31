" This script is used to run the tests for the vim-sembr plugin.

set nomore

let s:test_dir = fnamemodify(expand('<sfile>:p'), ':h')

execute 'set runtimepath^=' . fnameescape(fnamemodify(s:test_dir, ':h'))

runtime plugin/vim-sembr.vim

function! SemBrTestCase(name, test_case, expected) abort
  let l:error_count = len(v:errors)
  enew!
  call setline(1, a:test_case)
  :SemBr
  let l:actual = getline(1, '$')
  call assert_equal(a:expected, l:actual, a:name)

  if len(v:errors) == l:error_count
    echomsg 'PASS: ' . a:name
  else
    echomsg 'FAIL: ' . a:name
  endif
endfunction

execute 'source ' . fnameescape(s:test_dir . '/test_sentence_split.vim')

quitall!

let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')

execute 'set runtimepath^=' . fnameescape(s:root)
execute 'set runtimepath^=' . fnameescape(s:root . '/.vim-testify')
runtime plugin/testify.vim

for s:file in glob(s:root . '/t/**/*.vim', 0, 1)
  execute 'source' fnameescape(s:file)
endfor

let g:testify_fail = 0
call testify#run_all()
if g:testify_fail
  cquit
endif
quit

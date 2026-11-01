" vim-sembr.vim - SemBr
" Author: MakeJames
" Version: 0.1
" Description: Bring semantic linebreaks to vim.

if exists('g:loaded_vim_sembr')
  finish
endif
let g:loaded_vim_sembr = 1

command! -range=% SemBr call sembr#Format(<line1>, <line2>)

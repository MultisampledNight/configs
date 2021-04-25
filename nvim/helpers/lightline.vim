" File: lightline.vim
" Author: MultisampledNight (multisn8)

" it's visible on lightline already
set noshowmode

let g:lightline = {
      \ 'colorscheme': 'samplednight',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'readonly', 'filename', 'modified' ] ]
      \ },
      \ }

let g:lightline.separator = {
            \ 'left'  : '',
            \ 'right' : ''
            \ }

let g:lightline.subseparator = {
            \ 'left'  : '',
            \ 'right' : ''
            \ }

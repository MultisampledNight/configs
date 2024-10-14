" Settings if running NeoVim's TUI

nnoremap <A-S-j> <Cmd>2split<CR>z2<CR><Cmd>term i3status<CR><Cmd>set nonumber<CR>G<C-w>j
nnoremap <A-S-f> <Cmd>silent !brightnessctl --exponent set 5\%-<CR>
nnoremap <A-S-v> <Cmd>silent !brightnessctl --exponent set 3\%+<CR>

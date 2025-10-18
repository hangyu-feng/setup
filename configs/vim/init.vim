set nocompatible  " be iMproved, required

" see https://stackoverflow.com/questions/4976776/how-to-get-path-to-the-current-vimscript-being-executed
let vimrcDir = fnamemodify(resolve(expand('<sfile>:p')), ':h')
" With a map leader it's possible to do extra key combinations
let mapleader = " "

for filename in [
        \ "plugins.vim",
        \ "keymappings.vim",
        \ "helpers.vim",
        \ "settings.vim",
        \ ]
  exec "source " . vimrcDir . "/" . filename
endfor

if has('nvim')
  "runtime! expand(vimrcDir)/lua/*.lua
  for filename in [
        \ 'init.lua',
        \ 'lualine.lua',
        "\ 'oil.lua',
        \ 'mini.lua',
        \ 'treesitter.lua',
        \ 'lsp-zero.lua',
        \ ]
    exec 'luafile ' . vimrcDir . '/lua/' . filename
  endfor
endif

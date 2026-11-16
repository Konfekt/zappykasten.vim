command! -range=% -bang -nargs=? -complete=tag -bar Dlist  call search#list('d', <q-line1>, <q-line2>, <q-bang>, <q-args>)
command! -range=% -bang -nargs=? -complete=tag -bar Ilist  call search#list('i', <q-line1>, <q-line2>, <q-bang>, <q-args>)

" jump to selected include / list selected includes {{{
nnoremap <expr> [I      ':<c-u>Ilist \V' . escape(expand('<cword>'), '\') . '<cr>'
nnoremap <expr> ]I      line('.') < line('$') ? ':<c-u>+,$Ilist \V' . escape(expand('<cword>'), '\') . '<cr>' : ''
" }}}

" jump to selected makro / list selected makros {{{
nnoremap        [D      :<c-u>Dlist <C-R><C-W><CR>
nnoremap <expr> ]D      line('.') < line('$') ? ':<c-u>+,$Dlist <C-R><C-W><CR>' : ''
" }}}

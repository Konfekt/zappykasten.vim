" Buffer-local settings and gf in notes.
" vint: -ProhibitCommandRelyOnUser
execute 'source' fnameescape(g:zk_root . '/test/mock_fzf.vim')
let g:zk_dir = g:zk_tmp . '/zk'
call Mkfile(g:zk_dir . '/target.md', ['target'])
call Mkfile(g:zk_dir . '/note.md', ['text', '[plain](target)'])
let g:zk_search_paths = [g:zk_dir]
augroup zk_test
  autocmd BufRead,BufNewFile *.md setlocal suffixesadd=.txt
augroup END
runtime plugin/zappykasten.vim

function! Test_suffixesadd_appends_extension() abort
  execute 'edit' fnameescape(g:zk_dir . '/note.md')
  call assert_equal('.txt,.md', &l:suffixesadd)
endfunction

function! Test_reload_does_not_duplicate_settings() abort
  execute 'edit' fnameescape(g:zk_dir . '/note.md')
  let path = &l:path
  edit
  call assert_equal(path, &l:path)
  call assert_equal(1, count(split(&l:suffixesadd, ','), '.md'))
endfunction

function! Test_gf_on_plain_link() abort
  execute 'edit' fnameescape(g:zk_dir . '/note.md')
  call cursor(2, 12)
  normal gf
  call assert_equal(g:zk_dir . '/target.md', expand('%:p'))
endfunction

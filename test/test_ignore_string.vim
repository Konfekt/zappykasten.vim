" g:zk_ignore_pattern may be a string, as the documentation shows, or a list
" of patterns, which may contain quotes.
execute 'source' fnameescape(g:zk_root . '/test/mock_fzf.vim')
let g:zk_dir = g:zk_tmp . '/zk'
call Mkfile(g:zk_dir . '/alpha.md', ['alpha'])
call Mkfile(g:zk_dir . '/skip.txt', ['alpha'])
call Mkfile(g:zk_dir . "/it's.md", ['alpha'])
let g:zk_search_paths = [g:zk_dir]
let g:zk_ignore_pattern = ''
runtime plugin/zappykasten.vim
let g:loaded_empty = exists(':ZK') == 2
unlet g:loaded_zappykasten
let g:zk_ignore_pattern = ['*.txt', "it's.md"]
runtime plugin/zappykasten.vim

function! Test_empty_string_loads() abort
  call assert_true(g:loaded_empty)
endfunction

function! Test_patterns_are_ignored() abort
  ZK alpha
  let files = map(FzfSource(), 'fnamemodify(matchstr(v:val, "^[^:]*"), ":t")')
  call assert_equal(['alpha.md'], files)
endfunction

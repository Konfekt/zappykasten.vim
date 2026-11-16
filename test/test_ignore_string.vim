" g:zk_ignore_pattern may be a string, as the documentation shows.
execute 'source' fnameescape(g:zk_root . '/test/mock_fzf.vim')
let g:zk_dir = g:zk_tmp . '/zk'
call Mkfile(g:zk_dir . '/alpha.md', ['alpha'])
call Mkfile(g:zk_dir . '/skip.txt', ['alpha'])
let g:zk_search_paths = [g:zk_dir]
let g:zk_ignore_pattern = ''
runtime plugin/zappykasten.vim
let g:loaded_empty = exists(':ZK') == 2
unlet g:loaded_zappykasten
let g:zk_ignore_pattern = '*.txt'
runtime plugin/zappykasten.vim

function! Test_empty_string_loads() abort
  call assert_true(g:loaded_empty)
endfunction

function! Test_string_pattern_is_ignored() abort
  ZK alpha
  let files = map(FzfSource(), 'fnamemodify(matchstr(v:val, "^[^:]*"), ":t")')
  call assert_equal(['alpha.md'], files)
endfunction

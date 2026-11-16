" fzf may be loaded after this plug-in, depending on 'runtimepath' order.
let g:zk_dir = g:zk_tmp . '/zk'
call Mkfile(g:zk_dir . '/alpha.md', ['alpha'])
let g:zk_search_paths = [g:zk_dir]
runtime plugin/zappykasten.vim
let g:zk_message = execute('silent! ZK')
execute 'source' fnameescape(g:zk_root . '/test/mock_fzf.vim')

function! Test_missing_fzf_is_reported_on_use() abort
  call assert_match('fzf', g:zk_message)
endfunction

function! Test_fzf_loaded_later_is_used() abort
  call assert_equal(2, exists(':ZK'))
  ZK alpha
  call assert_equal(1, len(FzfSource()))
endfunction

" Opening, creating and yanking notes from the :ZK results.
execute 'source' fnameescape(g:zk_root . '/test/mock_fzf.vim')
let g:zk_dir = g:zk_tmp . '/zk'
call Mkfile(g:zk_dir . '/alpha.md', ['one', 'two: alpha'])
let g:zk_search_paths = [g:zk_dir]
runtime plugin/zappykasten.vim

function! Test_open_selected_line() abort
  ZK alpha
  let lines = FzfSource()
  call assert_equal(1, len(lines))
  call g:fzf_run_opts['sink*'](['alpha', ''] + lines)
  call assert_equal(g:zk_dir . '/alpha.md', expand('%:p'))
  call assert_equal(2, line('.'))
endfunction

function! Test_query_without_match_creates_note() abort
  call ZK_note_handler(['brand new', ''])
  call assert_equal(g:zk_dir . '/brand-new.md', expand('%:p'))
endfunction

function! Test_empty_query_without_match_does_nothing() abort
  enew
  call ZK_note_handler(['', ''])
  call assert_equal('', bufname('%'))
  call ZK_note_handler(['', 'ctrl-x', g:zk_dir . '/alpha.md:1:' . g:zk_dir . '/alpha.md:1:one'])
  call assert_equal('', bufname('%'))
endfunction

function! Test_yank_selected_files() abort
  let @" = ''
  call ZK_note_handler(['q', 'ctrl-y', g:zk_dir . '/alpha.md:1:x:1:one', g:zk_dir . '/b.md:3:y:3:z'])
  call assert_equal(g:zk_dir . "/alpha.md\n" . g:zk_dir . '/b.md', @")
endfunction

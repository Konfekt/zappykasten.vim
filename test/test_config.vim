" Loading the plug-in with user settings.
execute 'source' fnameescape(g:zk_root . '/test/mock_fzf.vim')
let g:zk_dir = g:zk_tmp . '/my notes'
call Mkfile(g:zk_dir . '/alpha.md', ['# Alpha', 'some text'])
let $ZK_TEST_MAIN = g:zk_dir
let g:zk_search_paths = [g:zk_dir]
let g:zk_main_directory = '$ZK_TEST_MAIN'
let g:zk_rg_options = ['--follow', '--smart-case', '--line-number', '--color never']
let g:zk_keymap = {'ctrl-s': 'split'}
let g:zk_ignore_pattern = []
runtime plugin/zappykasten.vim

function! Test_user_lists_are_not_modified() abort
  call assert_equal(['--follow', '--smart-case', '--line-number', '--color never'], g:zk_rg_options)
  call assert_equal({'ctrl-s': 'split'}, g:zk_keymap)
endfunction

function! Test_no_global_loop_variable() abort
  call assert_false(exists('g:path'), 'g:path leaked')
endfunction

function! Test_empty_ignore_list_adds_no_glob() abort
  ZK
  call assert_notmatch('--glob', g:fzf_run_opts.source)
  call assert_equal(1, len(filter(FzfSource(), 'v:val =~# "alpha\\.md:1:"')))
endfunction

function! Test_search_path_with_space_sets_up_buffers() abort
  execute 'edit' fnameescape(g:zk_dir . '/alpha.md')
  call assert_match('\.md', &l:suffixesadd)
  call assert_match('gf()', maparg('gf', 'n'))
endfunction

function! Test_main_directory_is_expanded() abort
  call ZK_note_handler(['new note', 'ctrl-x'])
  call assert_equal(g:zk_dir . '/new-note.md', expand('%:p'))
endfunction

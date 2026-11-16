" Links inserted by <C-X><C-Z> (ZK_make_note_link).
execute 'source' fnameescape(g:zk_root . '/test/mock_fzf.vim')
let g:zk_dir = g:zk_tmp . '/zk'
call Mkfile(g:zk_dir . '/a.md', ['a'])
call Mkfile(g:zk_dir . '/n.md', ['# My  Title', '# Note: sub', ''])
call Mkfile(g:zk_tmp . '/zk2/b.md', ['b'])
let g:zk_search_paths = [g:zk_dir]
let g:zk_insert_note_path = 'relative'
runtime plugin/zappykasten.vim

" A result line as fzf prints it, after shortening the path.
function! s:entry(file, lnum) abort
  let lines = filter(FzfSource(g:fzf_complete_opts), 'v:val =~# "^\\V" . escape(a:file, "\\") . ":" . a:lnum . ":"')
  call assert_equal(1, len(lines))
  return get(lines, 0, '')
endfunction

function! s:complete() abort
  execute 'edit' fnameescape(g:zk_dir . '/a.md')
  unlet! g:fzf_complete_opts
  execute "normal a\<C-X>\<C-Z>\<Esc>"
  call assert_true(exists('g:fzf_complete_opts'), '<C-X><C-Z> did not start fzf')
endfunction

function! Test_heading_marker_is_removed() abort
  call s:complete()
  call assert_equal('[My Title](n.md)', ZK_make_note_link(['q', s:entry(g:zk_dir . '/n.md', 1)]))
endfunction

function! Test_title_with_colon_is_kept() abort
  call s:complete()
  call assert_equal('[Note: sub](n.md)', ZK_make_note_link(['q', s:entry(g:zk_dir . '/n.md', 2)]))
endfunction

function! Test_empty_title_falls_back_to_query() abort
  call s:complete()
  call assert_equal('[query](n.md)', ZK_make_note_link(['query', g:zk_dir . '/n.md:3:' . g:zk_dir . '/n.md:3:']))
endfunction

function! Test_relative_path_to_sibling_directory() abort
  call s:complete()
  let file = g:zk_tmp . '/zk2/b.md'
  call assert_equal('[b](../zk2/b.md)', ZK_make_note_link(['q', file . ':1:' . file . ':1:b']))
endfunction

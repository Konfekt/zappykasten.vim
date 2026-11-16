" The :Open fallback for Vims without it.
if exists(':Open') == 2
  " Nothing to test: the editor provides :Open itself.
  function! Test_skipped_editor_has_open() abort
  endfunction
  finish
endif
let g:launched = []
command! -nargs=1 Launch call add(g:launched, <q-args>)
let s:path = $PATH
let $PATH = g:zk_tmp . '/empty'
let g:netrw_browsex_viewer = 'myviewer'
runtime after/plugin/launch.vim
let $PATH = s:path

function! Test_open_uses_netrw_browsex_viewer() abort
  Open https://example.com
  call assert_equal(["myviewer 'https://example.com'"], g:launched)
endfunction

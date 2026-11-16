" :Ilist and the [I ]I mappings.
" vint: -ProhibitCommandRelyOnUser
let g:zk_dir = g:zk_tmp . '/zk'
call Mkfile(g:zk_dir . '/a.md', ['foo here', '[b](b)', 'foo again'])
call Mkfile(g:zk_dir . '/b.md', ['bar', 'foo in b'])
runtime plugin/search.vim

function! Test_bracket_I_lists_matches() abort
  execute 'edit' fnameescape(g:zk_dir . '/a.md')
  call cursor(1, 1)
  normal [I
  call assert_equal(['foo here', 'foo again'], map(getloclist(0), 'v:val.text'))
endfunction

function! Test_close_bracket_I_lists_later_matches() abort
  execute 'edit' fnameescape(g:zk_dir . '/a.md')
  call setloclist(0, [])
  call cursor(1, 1)
  normal ]I
  call assert_equal(['foo again'], map(getloclist(0), 'v:val.text'))
endfunction

function! Test_no_match_is_reported() abort
  execute 'edit' fnameescape(g:zk_dir . '/a.md')
  messages clear
  Ilist \Vnothere
  call assert_match('Could not find', execute('messages'))
endfunction

function! Test_last_search_pattern_sets_column() abort
  execute 'edit' fnameescape(g:zk_dir . '/a.md')
  let @/ = 'again'
  Ilist
  call assert_equal([['foo again', 5]], map(getloclist(0), '[v:val.text, v:val.col]'))
endfunction

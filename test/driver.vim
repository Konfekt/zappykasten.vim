" Headless test driver. Usage (see run.sh):
"   vim -Nu NONE -i NONE -es --cmd 'let g:test_file = "test/test_x.vim"' -S test/driver.vim
" The test file configures the plug-in, loads it and defines Test_* functions.
let g:zk_root = fnamemodify(expand('<sfile>:p:h'), ':h')
let &runtimepath = g:zk_root . ',' . &runtimepath . ',' . g:zk_root . '/after'
let g:zk_tmp = resolve(fnamemodify(tempname(), ':p'))
call mkdir(g:zk_tmp, 'p')
let $HOME = g:zk_tmp . '/home'
call mkdir($HOME, 'p')
let s:out = get(g:, 'test_out', g:zk_tmp . '/result.txt')
let s:results = []
let v:errors = []

function! Mkfile(path, lines) abort
  call mkdir(fnamemodify(a:path, ':h'), 'p')
  call writefile(a:lines, a:path, 'b')
endfunction

" Strip ANSI color codes as fzf --ansi does.
function! StripAnsi(lines) abort
  return map(a:lines, 'substitute(v:val, "\e\\[[0-9;]*m", "", "g")')
endfunction

try
  execute 'source' fnameescape(g:test_file)
catch
  call add(v:errors, 'loading ' . g:test_file . ': ' . v:exception . ' @ ' . v:throwpoint)
endtry
if !empty(v:errors)
  call add(s:results, 'FAIL <load>: ' . join(v:errors, ' | '))
  let v:errors = []
endif

let s:tests = map(filter(split(execute('function /^Test_'), "\n"), 'v:val =~# "^function Test_"'),
      \ 'matchstr(v:val, ''^function \zsTest_\w\+'')')
for s:t in sort(s:tests)
  let v:errors = []
  try
    silent! %bwipeout!
    call call(s:t, [])
  catch
    call add(v:errors, v:exception . ' @ ' . v:throwpoint)
  endtry
  call add(s:results, (empty(v:errors) ? 'ok   ' : 'FAIL ') . s:t . (empty(v:errors) ? '' : ': ' . join(v:errors, ' | ')))
endfor
if empty(s:tests) && empty(s:results)
  call add(s:results, 'FAIL <no tests found>')
endif
call writefile(s:results, s:out)
qa!

" Make the fzf stand-ins in test/mock available.
let &runtimepath .= ',' . g:zk_root . '/test/mock'
command! -nargs=* FZF echo

" Run the source command of the last fzf call and return its lines as fzf
" with --ansi would print them.
function! FzfSource(...) abort
  let opts = a:0 ? a:1 : g:fzf_run_opts
  return StripAnsi(systemlist(opts.source))
endfunction

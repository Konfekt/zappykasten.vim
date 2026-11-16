" Stand-in for fzf's Vim functions; records what the plug-in passes.
function! fzf#wrap(...) abort
  let g:fzf_wrap_args = a:000
  for arg in a:000
    if type(arg) == type({}) | return arg | endif
  endfor
  return {}
endfunction

function! fzf#run(opts) abort
  let g:fzf_run_opts = a:opts
  return []
endfunction

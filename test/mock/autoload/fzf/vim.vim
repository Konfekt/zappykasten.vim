" Stand-in for fzf.vim's completion; records what the plug-in passes.
function! fzf#vim#complete(opts) abort
  let g:fzf_complete_opts = a:opts
  return ''
endfunction

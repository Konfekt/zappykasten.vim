" Show ]I and [I results in the quickfix window.
" From http://www.reddit.com/r/vim/comments/1rzvsm/do_any_of_you_redirect_results_of_i_to_the/
function! search#list(type, line1, line2, bang, search_pattern) abort
    let type = a:type
    let l:output = ''
    redir => l:output
    let search_pattern =
          \ (a:search_pattern =~# '\v^/?$' ? '/' . @/ : a:search_pattern)
    silent! execute a:line1 . ',' . a:line2 . type . 'list' . a:bang . ' ' . search_pattern
    redir END
    let lines = split(l:output, '\n')
    " Bail out on errors.
    if (len(lines) == 3) && ((type is# 'd' && lines[2] =~# '^E388:') || type is# 'i' && (lines[2] =~# '^E389:'))
        echomsg 'Could not find "' . search_pattern . '" . '
        return
    endif
    " Our results may span multiple files so we need to build a relatively complex list based on filenames.
    let filename   = ''
    let qf_entries = []
    for line in lines
        if line !~# '^\s*\d\+:'
            let filename = fnamemodify(line, ':p:.')
        else
            let lnum = split(line)[1]
            let text = substitute(line, '^\s*.\{-}:\s*\S\{-}\s', '', '')
            let col  = match(text, a:search_pattern) + 1
            call add(qf_entries, {'filename': filename, 'lnum': lnum, 'col': col, 'vcol': 1, 'text': text})
        endif
    endfor

    call setloclist(0, qf_entries)
    lwindow
endfunction

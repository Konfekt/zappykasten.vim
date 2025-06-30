" Check for compatibility or if the script is already loaded
if &compatible || exists('g:loaded_zappykasten') | finish | endif

" Ensure 'rg' (ripgrep) is installed
if !executable('rg')
    echomsg '`Ripgrep` is not installed. See https://github.com/BurntSushi/ripgrep for installation instructions.'
    finish
endif

" Ensure the Vim plug-in `Fzf` is installed
let s:use_fzf_lua = 0

if exists(':FZF') != 2
    if exists(':FzfLua') != 2
        echomsg 'The Vim plug-in `Fzf` is not installed. See https://github.com/junegunn/fzf for installation instructions.'
        echomsg 'Neovim also supports `fzf-lua`.'
        finish
    else
        let s:use_fzf_lua = 1
    endif
endif

let s:ext = get(g:, 'zk_default_extension', '.md')
let s:tag = get(g:, 'zk_tag_marker', '\[\[\ze\i\+\]\]')

" Set up user-defined search paths or default if not defined
if !exists('g:zk_search_paths')
    let g:zk_search_paths = []
    let s:zettelkasten = $HOME . '/zettelkasten'
    if !isdirectory(s:zettelkasten)
        call mkdir(s:zettelkasten, 'p')
    endif
    let g:zk_search_paths += [s:zettelkasten]
endif

let s:search_paths = map(copy(g:zk_search_paths), 'expand(v:val)')

" Determine the main directory from search paths
if exists('g:zk_main_directory')
    let s:main_dir = g:zk_main_directory
else
    for path in s:search_paths
        if isdirectory(path)
            let s:main_dir = path
            break
        endif
    endfor
    if !exists('s:main_dir')
        echomsg 'No directories found in `g:zk_search_paths`'
        finish
    endif
endif

let s:has_colon =
      \ has('win32unix') && g:zk_main_directory =~? '^/[a-z]/' ||
      \ has('win32') && g:zk_main_directory =~? '^[a-z]:'

" Convert path separators for Windows if necessary
if exists('+shellslash') && !&shellslash
    let g:zk_search_paths = map(copy(g:zk_search_paths), 'tr(v:val, "/", "\\")')
endif

" Windows-specific settings
if has('win32')
    let s:null_path = 'NUL'
    let s:command = ''
else
    let s:null_path = '/dev/null'
    let s:command = 'command'
endif

" Ripgrep Settings {{{1
" Ripgrep's necessary options
let s:rg_command = [s:command, 'rg']
let s:rg_musts = [
      \ '--no-messages',
      \ '--no-heading',
      \ '--with-filename',
      \ ]
" To make room for the full file name in the first FZF column, in the second column
" show only some neighboring words around the match as worked around by
"   rg --only-matching ".{0,40}$Q.{0,40}"
" at https://github.com/BurntSushi/ripgrep/issues/1352#issuecomment-1959071755

" Ripgrep's user's general options
let s:rg_options = get(g:, 'zk_rg_options', [
      \ '--follow',
      \ '--smart-case',
      \ '--line-number',
      \ '--color never',
      \ ])

" Ripgrep's user's ignore options
let s:include_hidden = get(g:, 'zk_include_hidden', 0) ? '--hidden' : ''
" Utility function to single-quote a string
function! s:single_quote(str) abort
    return "'" . a:str . "'"
endfunction
" Convert ignore patterns to string
function! s:ignore_list_to_str(pattern) abort
    let l:glob_fmt = ' --glob !'
    return l:glob_fmt . join(map(copy(a:pattern), 's:single_quote(v:val)'), l:glob_fmt)
endfunction
let s:use_ignore_files = get(g:, 'zk_use_ignore_files', 1) ? '' : '--no-ignore'
let s:ignore_pattern = exists('g:zk_ignore_pattern') ? s:ignore_list_to_str(g:zk_ignore_pattern) : ''
let s:rg_options += [
      \ s:include_hidden,
      \ s:use_ignore_files,
      \ s:ignore_pattern
      \ ]

" }}}

" FZF Settings {{{1
" FZF main window settings
let s:window_direction = get(g:, 'zk_window_direction', 'down')
" let s:window_width = get(g:, 'zk_window_width', &lines < 40 ? '60%' : '40%')
let s:window_command = get(g:, 'zk_window_command', '')
" FZF preview window settings
let s:fzf_preview_window_options = [
        \ exists('g:zk_preview_width') ? string(float2nr(str2float(g:zk_preview_width) / 100.0 * &columns)) : '',
        \ get(g:, 'zk_wrap_preview_text', 0) ? 'wrap' : '',
        \ get(g:, 'zk_show_preview', 1) ? '' : 'hidden',
        \ ]
        " \ get(g:, 'zk_preview_direction', &columns > 100 ? 'right' : 'down'),
let s:fzf_preview_window_options = join(filter(copy(s:fzf_preview_window_options), '!empty(v:val)') , ':')

" Format path expression based on user's option to use short pathnames
if get(g:, 'zk_use_short_pathnames', 1)
    let s:python_executable = executable('pypy3') ? 'pypy3' : get(g:, 'python3_host_prog', 'python3')
    let s:format_path_expr = join([' | ', s:python_executable, '-S', shellescape(expand('<sfile>:p:h:h') . '/py/shorten_path_for_notational_fzf.py'),])
    let s:display_start_index = s:has_colon ? '4..' : '3..'
else
    let s:format_path_expr = ''
    let s:display_start_index = '1..'
endif

" FZF Key mappings for creating notes and yanking
let s:create_note_key = get(g:, 'zk_create_note_key', 'ctrl-x')
let s:yank_key = get(g:, 'zk_yank_key', 'ctrl-y')
let s:create_note_window = get(g:, 'zk_create_note_window', 'vertical split ')
let s:keymap = get(g:, 'zk_keymap',
            \ { 'ctrl-s': 'split',
            \   'ctrl-v': 'vertical split',
            \   'ctrl-t': 'tabedit',
            \ })
let s:keymap = extend(s:keymap, {
            \ s:create_note_key : s:create_note_window,
            \ })
let s:expect_keys = join(keys(s:keymap) + get(g:, 'zk_expect_keys', []) + [s:yank_key], ',')

" FZF settings
let s:fzf_musts = [
      \ '--print-query',
      \ '--delimiter=":"',
      \ '--bind=' .  join([
                  \ 'alt-a:select-all',
                  \ 'alt-q:deselect-all',
                  \ 'alt-p:toggle-preview',
                  \ 'alt-u:page-up',
                  \ 'alt-d:page-down',
                  \ 'ctrl-w:backward-kill-word',
                  \ ], ','),
      \ ]
let s:fzf_options = get(g:, 'zk_fzf_options', [
      \ '--ansi',
      \ '--multi',
      \ '--exact',
      \ '--info=inline',
      \ '--tiebreak=' . 'length,begin' ,
      \ '--preview=' . shellescape('rg --smart-case --pretty --context 3 -- {q} ' ..
      \                             (s:has_colon ? '{1}:{2}' : '{1}')),
      \ ])
let s:fzf_options = s:fzf_options + [
      \ '--expect=' . s:expect_keys ,
      \ '--with-nth=' . s:display_start_index ,
      \ ]
let s:fzf_preview_options = '--preview-window=' . s:fzf_preview_window_options

" }}}

" Add settings and mappings to make gf jump to URL or file {{{1
" Configure paths for 'gf' command
let s:glob = ''
let s:path = ''
for path in g:zk_search_paths
    let path = resolve(expand(path))
    if exists('+shellslash') && !&shellslash
        let path = tr(path, "\\", "/")
    endif
    let s:glob .= path . '/*' . s:ext . ','
    let s:path .= path . '/*,'
endfor

augroup zappykasten
  autocmd!
  exe 'autocmd BufRead,BufNewFile' s:glob 'call s:zappykasten()'
augroup END

function! s:zappykasten() abort
    let &l:path = (empty(&path) ? '' : &path..',')..s:path
    let &l:suffixesadd =
                \ empty(&l:suffixesadd) ? s:ext : &l:suffixesadd..',.'..s:ext
    let &l:include = '\[.\{-}\](\zs\f\+\ze\%('..escape(s:ext,'.')..'\)\?)'
    let &l:includeexpr = 'v:fname =~# "\\V'..escape(s:ext,'\')..'\\$" ? v:fname : v:fname.."'..s:ext..'"'
    let &l:define = s:tag
    command! -buffer -nargs=1 -complete=file Pedit
                \  exe 'pedit' (<q-args> =~# '\V'..escape(s:ext,'\')..'\$' ? <q-args> : <q-args>..s:ext)
                \ | autocmd CursorMoved <buffer> ++once wincmd z
    let &l:keywordprg = ':Pedit'
    nnoremap <buffer> gf :<c-u>call <sid>gf()<cr>
    exe 'inoremap <buffer><expr>' s:insert_note_key '<sid>complete_file()'
endfunction

" unlet s:path
" unlet s:glob

function! s:gf() abort
    " Adapted from https://raw.githubusercontent.com/dharmx/nvim/main/plugin/gx.vim
    let URL = ''
    if searchpair('\[.\{-}\](', '', ')\zs', 'cbW', '', line('.')) > 0
        let base = '\%(https\?\|file\)://\S\{-}'
        let URL = matchstr(getline('.')[col('.')-1:], '\[.\{-}\](\zs'..base..'\ze\(\s\+.\{-}\)\?)')
        call search('(', 'ce')
    endif
    if !empty(URL)
        exe 'Open' escape(URL, '%#')
    else
        normal! gf
    endif
endfunction
" }}}

" Insert link to file into buffer by fuzzy search in insert mode {{{1
" Key mapping for inserting note links
let s:insert_note_key = get(g:, 'zk_insert_note_key', '<c-x><c-z>')
let s:insert_note_path = get(g:, 'zk_insert_note_path', 'name')

" Adapted from https://vi.stackexchange.com/a/28854
function! s:PathRelativeToDir(path, dir) abort
  " the path leads *inside* a subdirectory of the directory; we're done
  if stridx(a:path, a:dir) == 0
    return a:path[len(fnamemodify(a:dir, ':p')):]
  else
    " the path leads *outside*; let's move up in the hierarchy to find it
    return '../'..s:PathRelativeToDir(a:path, fnamemodify(a:dir, ':h'))
  endif
endfunction

" Adapted from https://www.frrobert.com/blog/linkingzettelkasten-2020-05-11-0735
function! ZK_make_note_link(l) abort
  let query = a:l[0]
  let array = split(a:l[1], ':')
  let line = array[-1]

  let file = s:has_colon ? array[0] .. ':' .. array[1] : array[0]
  if has('win32unix') | let file = systemlist('cygpath '..shellescape(file))[0] | endif
  let buf_dir = expand('%:h')
  let dir = isdirectory(buf_dir) ? buf_dir : s:main_dir
  if s:insert_note_path ==# 'relative'
    let zk_path = s:PathRelativeToDir(fnamemodify(file, ':p'), fnamemodify(dir, ':p:h'))
  elseif s:insert_note_path ==# 'absolute'
    let zk_path = fnamemodify(file, ':~')
  else " default to 'name'
    let zk_path = fnamemodify(file, ':t:r')
  endif

  try
    " remove title tags and spaces
    let zk_title = substitute(line, '^\#\+\s\+', '', '')
    let zk_title = trim(substitute(line, '\s\+', ' ', 'g'))
  catch
    let zk_title = query
  endtry

  return '[' . zk_title .']('. zk_path .')'
endfunction

" fuzzy find file containing search by completing word at cursor position
function! s:complete_file() abort
  " Prepare search path string for 'rg' command
  return fzf#vim#complete({
        \ 'reducer': function('ZK_make_note_link'),
        \ 'source': join(
            \   s:rg_command
            \ + s:rg_musts
            \ + s:rg_options
            \ + [
            \   '"\S"',
            \   join(map(copy(s:search_paths), 'shellescape(v:val)')),
            \   s:format_path_expr,
            \   '2>' . s:null_path,
            \ ]),
        \ 'window': s:window_command,
        \ s:window_direction: get(g:, 'zk_window_width', &lines < 40 ? '60%' : '40%'),
        \ 'options': join(s:fzf_musts + s:fzf_options)
            \ ..' '..s:fzf_preview_options..':'..get(g:, 'zk_preview_direction', &columns > 100 ? 'right' : 'down')
            \ ..' '..'--bind=?:"change-preview-window('.. (&columns > 100 ? 'down' : 'right') ..',border-top|hidden|)"',
        \ })
endfunction
" }}}

" Function for creating notes {{{1
function! s:yank_to_register(data)
    let path = a:data
    call setreg('"', path)

    let fpath = fnamemodify(path, ":p")
    if has('win32')
        silent! call setreg('+', tr(fpath, "/", "\\"))
    elseif has('win32unix')
        silent! call system('clip.exe', system('cygpath -w '..shellescape(fpath)))
    elseif has('unix') && exists('$WSL_DISTRO_NAME')
        silent! call system('clip.exe', system('wslpath -w '..shellescape(fpath)))
    else
        silent! call setreg('+', fpath)
        silent! call setreg('*', fpath)
    endif
endfunction

" Separator for yanked files
let s:yank_separator = get(g:, 'zk_yank_separator', "\n")

function! ZK_note_handler(lines) abort
  " exit if empty
  if a:lines == [] || a:lines == ['','','']
    return
  endif
  " Expect at least two elements, `query` and `keypress`, possibly empty
  let query    = a:lines[0]
  let keypress = a:lines[1]
  " `edit` is fallback in case something goes wrong
  let cmd = get(s:keymap, keypress, 'edit')
  " Preprocess candidates here. Expect lines to have the format
  " filename:linenum:content

  " Handle creating note.
  if keypress ==? s:create_note_key
    " replace blanks to more easily open file when positioning cursor on its name
    let filename = tr(query, ' ', '-')
    let candidates = [fnameescape(s:main_dir  . '/' . filename . s:ext)]
  elseif keypress ==? s:yank_key
    let pat = '\v(.{-}):\d+:'
    let hashes = join(filter(map(copy(a:lines[2:]), 'matchlist(v:val, pat)[1]'), 'len(v:val)'), s:yank_separator)
    return s:yank_to_register(hashes)
  else
    let filenames = a:lines[2:]
    let candidates = []
    if empty(filenames)
      " If there are no matches, then create a note
      let filename = tr(query, ' ', '-')
      let candidates = [fnameescape(s:main_dir  . '/' . filename . s:ext)]
    else
      for filename in filenames
        " Don't forget trailing space in replacement.
        let linenum = substitute(filename, '\v.{-}:(\d+):.*$', '+\1 ', '')
        let name = substitute(filename, '\v(.{-}):\d+:.*$', '\1', '')
        " fnameescape instead of shellescape because the file is consumed
        " by vim rather than the shell
        call add(candidates, linenum . fnameescape(name))
      endfor
    endif
  endif

  for candidate in candidates
    execute join([cmd, candidate])
  endfor
endfunction
" }}}

" Command to start fuzzy search {{{1
if s:use_fzf_lua
    silent! command -nargs=* -bang ZK lua require('zappykasten.fzf-lua')
        \.search_notes(vim.fn.eval("s:main_dir"),
        \   vim.fn.eval("s:create_note_key"),
        \   vim.fn.eval("s:yank_key"),
        \   vim.fn.eval("s:rg_musts + s:rg_options"))
else
    silent! command -nargs=* -bang ZK
          \ call fzf#run(
              \ fzf#wrap({
                  \ 'sink*': function('ZK_note_handler'),
                  \ 'source': join(
                        \   s:rg_command
                        \ + s:rg_musts
                        \ + s:rg_options
                        \ + [
                        \     empty(<q-args>) ? '"\S"' : shellescape(<q-args>),
                        \     join(map(copy(s:search_paths), 'shellescape(v:val)')),
                        \     s:format_path_expr,
                        \     '2>' . s:null_path,
                        \   ]
                        \ ),
                  \ 'window': s:window_command,
                  \ s:window_direction: get(g:, 'zk_window_width', &lines < 40 ? '60%' : '40%'),
                  \ 'options': join(s:fzf_musts + s:fzf_options)
                        \ ..' '..s:fzf_preview_options..':'..get(g:, 'zk_preview_direction', &columns > 100 ? 'right' : 'down')
                        \ ..' '..'--bind=?:"change-preview-window('.. (&columns > 100 ? 'down' : 'right') ..',border-top|hidden|)"',
                  \ }, <bang>0))

    " Let's break down the even more cryptic --preview-window expression
    "
    "     --preview-window '~4,+{2}+4/3,<80(up)'
    "
    " - ~4 makes the top four lines "sticky" header so that they are always
    "   visible regardless of the scroll offset. (Did I mention that you can
    "   scroll the preview window with your mouse/trackpad?)
    " - +{2} - The base offset is extracted from the second token
    " - +4 - We add 4 lines to the base offset to compensate for the header
    " - /3 adjusts the offset so that the matching line is shown at a third
    "   position in the window
    " - <80(up) - This expression specifies the alternative options for the
    "   preview window. By default, the preview window opens on the right side
    "   with 50% width. But if the width is narrower than 80 columns, it will open
    "   above the main window with 50% height.
    " }}}
endif

" Mark the script as loaded
let g:loaded_zappykasten = 1

" vim: set foldmethod=marker:

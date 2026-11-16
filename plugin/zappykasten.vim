" Check for compatibility or if the script is already loaded
if &compatible || exists('g:loaded_zappykasten') | finish | endif

" Ensure 'rg' (ripgrep) is installed
if !executable('rg')
    echomsg '`Ripgrep` is not installed. See https://github.com/BurntSushi/ripgrep for installation instructions.'
    finish
endif

let s:ext = get(g:, 'zk_default_extension', '.md')
let s:tag = get(g:, 'zk_tag_marker', '\[\[\ze\i\+\]\]')

" Set up user-defined search paths or default if not defined
if !exists('g:zk_search_paths')
    let g:zk_search_paths = [$HOME . '/zettelkasten']
    if !isdirectory(g:zk_search_paths[0])
        call mkdir(g:zk_search_paths[0], 'p')
    endif
endif

let s:search_paths = map(copy(g:zk_search_paths), 'expand(v:val)')

" Determine the main directory from search paths
if exists('g:zk_main_directory')
    let s:main_dir = expand(g:zk_main_directory)
else
    let s:main_dir = get(filter(copy(s:search_paths), 'isdirectory(v:val)'), 0, '')
    if empty(s:main_dir)
        echomsg 'No directories found in `g:zk_search_paths`'
        finish
    endif
endif

" Whether file names start with a drive letter followed by a colon
let s:has_colon =
      \ has('win32unix') && s:main_dir =~? '^/[a-z]/' ||
      \ has('win32') && s:main_dir =~? '^[a-z]:'

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
let s:rg_options = copy(get(g:, 'zk_rg_options', [
      \ '--follow',
      \ '--smart-case',
      \ '--line-number',
      \ '--color never',
      \ ]))

" Ripgrep's user's ignore options
let s:ignore_pattern = get(g:, 'zk_ignore_pattern', [])
if type(s:ignore_pattern) != type([])
    let s:ignore_pattern = empty(s:ignore_pattern) ? [] : [s:ignore_pattern]
endif
let s:rg_options += [
      \ get(g:, 'zk_include_hidden', 0) ? '--hidden' : '',
      \ get(g:, 'zk_use_ignore_files', 1) ? '' : '--no-ignore',
      \ ] + map(copy(s:ignore_pattern), '"--glob !''" . v:val . "''"')
unlet s:ignore_pattern

" }}}

" FZF Settings {{{1
" FZF main window settings
let s:window_direction = get(g:, 'zk_window_direction', 'down')
let s:window_command = get(g:, 'zk_window_command', '')
" FZF preview window settings
let s:fzf_preview_window_options = join(filter([
        \ exists('g:zk_preview_width') ? string(float2nr(str2float(g:zk_preview_width) / 100.0 * &columns)) : '',
        \ get(g:, 'zk_wrap_preview_text', 0) ? 'wrap' : '',
        \ get(g:, 'zk_show_preview', 1) ? '' : 'hidden',
        \ ], '!empty(v:val)'), ':')

" Format path expression based on user's option to use short pathnames
let s:use_short_pathnames = get(g:, 'zk_use_short_pathnames', 1)
if s:use_short_pathnames
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
let s:keymap = extend(copy(get(g:, 'zk_keymap',
            \ { 'ctrl-s': 'split',
            \   'ctrl-v': 'vertical split',
            \   'ctrl-t': 'tabedit',
            \ })), {
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
      \ '--preview=' . shellescape('rg --smart-case --pretty --context 3 -- {q} ' .
      \                             (s:has_colon ? '{1}:{2}' : '{1}')),
      \ ])
let s:fzf_options = s:fzf_options + [
      \ '--expect=' . s:expect_keys ,
      \ '--with-nth=' . s:display_start_index ,
      \ ]
let s:fzf_preview_options = '--preview-window=' . s:fzf_preview_window_options

" Shell command that lists all lines matching the (shell-quoted) pattern
function! s:source(pattern) abort
    return join(filter(s:rg_command + s:rg_musts + s:rg_options + [
          \ a:pattern,
          \ join(map(copy(s:search_paths), 'shellescape(v:val)')),
          \ s:format_path_expr,
          \ '2>' . s:null_path,
          \ ], '!empty(v:val)'))
endfunction

" Options for fzf#run() and fzf#vim#complete()
function! s:fzf_spec(source) abort
    let wide = &columns > 100
    return {
          \ 'source': a:source,
          \ 'window': s:window_command,
          \ s:window_direction : get(g:, 'zk_window_width', &lines < 40 ? '60%' : '40%'),
          \ 'options': join(s:fzf_musts + s:fzf_options)
          \   . ' ' . s:fzf_preview_options . ':' . get(g:, 'zk_preview_direction', wide ? 'right' : 'down')
          \   . ' --bind=?:"change-preview-window(' . (wide ? 'down' : 'right') . ',border-top|hidden|)"',
          \ }
endfunction

" fzf may be loaded after this plug-in, so check for it only when needed
function! s:has_fzf() abort
    if exists(':FZF') == 2
        return 1
    endif
    echohl ErrorMsg
    echomsg 'The Vim plug-in `Fzf` is not installed. See https://github.com/junegunn/fzf for installation instructions.'
    echohl None
    return 0
endfunction

" }}}

" Add settings and mappings to make gf jump to URL or file {{{1
" Configure paths for 'gf' command
let s:globs = []
let s:path = ''
for s:dir in g:zk_search_paths
    let s:dir = resolve(expand(s:dir))
    if exists('+shellslash') && !&shellslash
        let s:dir = tr(s:dir, "\\", '/')
    endif
    call add(s:globs, escape(s:dir, ' ,') . '/*' . s:ext)
    let s:path .= escape(s:dir, ' ,') . '/*,'
endfor
unlet! s:dir

augroup zappykasten
  autocmd!
  if !empty(s:globs)
    exe 'autocmd BufRead,BufNewFile' join(s:globs, ',') 'call s:zappykasten()'
  endif
augroup END
unlet s:globs

function! s:zappykasten() abort
    if stridx(&path, s:path) < 0
        let &l:path = (empty(&path) ? '' : &path . ',') . s:path
    endif
    if index(split(&l:suffixesadd, ','), s:ext) < 0
        let &l:suffixesadd = empty(&l:suffixesadd) ? s:ext : &l:suffixesadd . ',' . s:ext
    endif
    let &l:include = '\[.\{-}\](\zs\f\+\ze\%(' . escape(s:ext, '.') . '\)\?)'
    let &l:includeexpr = 'v:fname =~# "\\V' . escape(s:ext, '\') . '\\$" ? v:fname : v:fname . "' . s:ext . '"'
    let &l:define = s:tag
    command! -buffer -nargs=1 -complete=file Pedit
                \  exe 'pedit' (<q-args> =~# '\V' . escape(s:ext, '\') . '\$' ? <q-args> : <q-args> . s:ext)
                \ | autocmd CursorMoved <buffer> ++once wincmd z
    let &l:keywordprg = ':Pedit'
    nnoremap <buffer> gf :<c-u>call <sid>gf()<cr>
    exe 'inoremap <buffer><expr>' s:insert_note_key '<sid>complete_file()'
endfunction

function! s:gf() abort
    " Adapted from https://raw.githubusercontent.com/dharmx/nvim/main/plugin/gx.vim
    let URL = ''
    if searchpair('\[.\{-}\](', '', ')\zs', 'cbW', '', line('.')) > 0
        let base = '\%(https\?\|file\)://\S\{-}'
        let URL = matchstr(getline('.')[col('.')-1:], '\[.\{-}\](\zs' . base . '\ze\(\s\+.\{-}\)\?)')
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
  let dir = fnamemodify(a:dir, ':p')
  if dir !~# '[/\\]$'
    let dir .= '/'
  endif
  " the path leads *inside* a subdirectory of the directory; we're done
  if stridx(a:path, dir) == 0
    return a:path[len(dir):]
  endif
  " the path leads *outside*; let's move up in the hierarchy to find it
  let parent = fnamemodify(a:dir, ':h')
  " no common ancestor, such as on another drive
  if parent ==# a:dir
    return a:path
  endif
  return '../' . s:PathRelativeToDir(a:path, parent)
endfunction

" Lines are `file:line:content`, or `file:line:short file:line:content` with
" short path names; capture file and content
let s:file_pattern = s:has_colon ? '\a:.\{-}' : '.\{-}'
let s:entry_pattern = '^\(' . s:file_pattern . '\):\d\+:' .
      \ (s:use_short_pathnames ? '.\{-}:\d\+:' : '') . '\(.*\)$'

" Adapted from https://www.frrobert.com/blog/linkingzettelkasten-2020-05-11-0735
function! ZK_make_note_link(l) abort
  let query = a:l[0]
  let entry = matchlist(get(a:l, 1, ''), s:entry_pattern)
  if empty(entry)
    return query
  endif
  let [file, content] = entry[1:2]

  if has('win32unix') | let file = systemlist('cygpath ' . shellescape(file))[0] | endif
  let buf_dir = expand('%:h')
  let dir = isdirectory(buf_dir) ? buf_dir : s:main_dir
  if s:insert_note_path ==# 'relative'
    let zk_path = s:PathRelativeToDir(fnamemodify(file, ':p'), fnamemodify(dir, ':p:h'))
  elseif s:insert_note_path ==# 'absolute'
    let zk_path = fnamemodify(file, ':~')
  else " default to 'name'
    let zk_path = fnamemodify(file, ':t:r')
  endif

  " remove title tags and spaces
  let zk_title = trim(substitute(substitute(content, '^#\+\s\+', '', ''), '\s\+', ' ', 'g'))
  if empty(zk_title)
    let zk_title = query
  endif

  return '[' . zk_title . '](' . zk_path . ')'
endfunction

" fuzzy find file containing search by completing word at cursor position
function! s:complete_file() abort
  if !s:has_fzf()
    return ''
  endif
  let spec = s:fzf_spec(s:source('"\S"'))
  let spec.reducer = function('ZK_make_note_link')
  return fzf#vim#complete(spec)
endfunction
" }}}

" Function for creating notes {{{1
function! s:yank_to_register(data) abort
    let path = a:data
    call setreg('"', path)

    let fpath = fnamemodify(path, ':p')
    if has('win32')
        silent! call setreg('+', tr(fpath, '/', "\\"))
    elseif has('win32unix')
        silent! call system('clip.exe', system('cygpath -w ' . shellescape(fpath)))
    elseif has('unix') && exists('$WSL_DISTRO_NAME')
        silent! call system('clip.exe', system('wslpath -w ' . shellescape(fpath)))
    else
        silent! call setreg('+', fpath)
        silent! call setreg('*', fpath)
    endif
endfunction

" Separator for yanked files
let s:yank_separator = get(g:, 'zk_yank_separator', "\n")

" Escaped path of the note named after the query, with blanks replaced to
" more easily open the file when positioning the cursor on its name
function! s:new_note(query) abort
    return fnameescape(s:main_dir . '/' . tr(a:query, ' ', '-') . s:ext)
endfunction

function! ZK_note_handler(lines) abort
  " Expect at least two elements, `query` and `keypress`, possibly empty
  if len(a:lines) < 2
    return
  endif
  let query    = a:lines[0]
  let keypress = a:lines[1]
  " Lines have the format filename:linenum:content
  let selected = filter(a:lines[2:], '!empty(v:val)')
  " `edit` is fallback in case something goes wrong
  let cmd = get(s:keymap, keypress, 'edit')

  if keypress ==? s:yank_key
    if !empty(selected)
      let files = map(selected, 'matchstr(v:val, ''\v^.{-}\ze:\d+:'')')
      call s:yank_to_register(join(filter(files, '!empty(v:val)'), s:yank_separator))
    endif
    return
  endif

  if keypress ==? s:create_note_key || empty(selected)
    " Create the note named by the query, unless it is empty
    if empty(query)
      return
    endif
    let candidates = [s:new_note(query)]
  else
    let candidates = []
    for line in selected
      " Don't forget trailing space in replacement.
      let linenum = substitute(line, '\v.{-}:(\d+):.*$', '+\1 ', '')
      let name = substitute(line, '\v(.{-}):\d+:.*$', '\1', '')
      " fnameescape instead of shellescape because the file is consumed
      " by vim rather than the shell
      call add(candidates, linenum . fnameescape(name))
    endfor
  endif

  for candidate in candidates
    execute cmd candidate
  endfor
endfunction
" }}}

" Command to start fuzzy search {{{1
function! s:search(query, bang) abort
    if !s:has_fzf()
        return
    endif
    let spec = s:fzf_spec(s:source(empty(a:query) ? '"\S"' : shellescape(a:query)))
    let spec['sink*'] = function('ZK_note_handler')
    call fzf#run(fzf#wrap(spec, a:bang))
endfunction

silent! command -nargs=* -bang ZK call s:search(<q-args>, <bang>0)

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

" Mark the script as loaded
let g:loaded_zappykasten = 1

" vim: set foldmethod=marker:

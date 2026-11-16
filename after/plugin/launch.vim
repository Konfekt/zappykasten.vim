if exists(':Launch') != 2
  let s:null = has('win32') ? 'nul' : '/dev/null'
  let s:redir = &shellredir =~# '%s' ? printf(&shellredir, s:null) : &shellredir . s:null

  " Copied from NetrwPlugin.vim at 9.1.0818
  if has('unix')
    if has('win32unix')
      " If cygstart provided, then assume Cygwin and use cygstart --hide; see man cygstart.
      if executable('cygstart')
        command -complete=shellcmd -nargs=1 -bang Launch
            \ exe 'silent ! cygstart --hide' <q-args>  s:redir | redraw!
      elseif !empty($MSYSTEM) && executable('start')
        " MSYS2/Git Bash comes by default without cygstart; see
        " https://www.msys2.org/wiki/How-does-MSYS2-differ-from-Cygwin
        " Instead it provides /usr/bin/start script running `cmd.exe //c start`
        " Adding "" //b` sets void title, hides cmd window and blocks path conversion
        " of /b to \b\ " by MSYS2; see https://www.msys2.org/docs/filesystem-paths/
        command -complete=shellcmd -nargs=1 -bang Launch
              \ exe 'silent !start //b' <q-args>  s:redir | redraw!
      else
        " imitate /usr/bin/start script for other environments and hope for the best
        command -complete=shellcmd -nargs=1 -bang Launch
              \ exe 'silent !cmd //c start //b' <q-args>  s:redir | redraw!
      endif
    elseif exists('$WSL_DISTRO_NAME') " use cmd.exe to start GUI apps in WSL
      command -complete=shellcmd -nargs=1 -bang Launch execute ':silent !'..
            \ ((<q-args> =~? '\v<\f+\.(exe|com|bat|cmd)>') ?
              \ 'cmd.exe /c start /b ' .. <q-args> :
              \ 'nohup ' <q-args> .. s:redir .. ' &')
            \ | redraw!
    else
      command -complete=shellcmd -nargs=1 -bang Launch
          \ exe ':silent ! nohup' <q-args> s:redir (has('gui_running') ? '' : '&') | redraw!
    endif
  elseif has('win32')
    command -complete=shellcmd -nargs=1 -bang Launch
          \ exe 'silent !'.. (&shell =~? '\<cmd\.exe\>' ? '' : 'cmd.exe /c')
          \ 'start "" /b ' <q-args> s:redir | redraw!
  endif
endif

if exists(':Launch') == 2 && exists(':Open') != 2
  " Git Bash
  if has('win32unix')
      " start suffices
      let s:cmd = ''
  " Windows / WSL
  elseif executable('explorer.exe')
      let s:cmd = 'explorer.exe'
  " Linux / BSD
  elseif executable('xdg-open')
      let s:cmd = 'xdg-open'
  " MacOS
  elseif executable('open')
      let s:cmd = 'open'
  endif
  if !exists('s:cmd') && exists('g:netrw_browsex_viewer')
    let s:cmd = g:netrw_browsex_viewer
  endif
  function s:Open(file) abort
    if !exists('s:cmd')
      echoerr 'No program to open this path found. See :help Open for more information.'
    else
      exe 'Launch' s:cmd shellescape(a:file, 1)
    endif
  endfunction
  command -complete=file -nargs=1 Open call s:Open(<q-args>)
endif

function! s:sort(lhs, rhs) abort
  if a:lhs[-1:] ==# '/' && a:rhs[-1:] !=# '/'
    return -1
  elseif a:lhs[-1:] !=# '/' && a:rhs[-1:] ==# '/'
    return 1
  endif
  if a:lhs < a:rhs
    return -1
  elseif a:lhs > a:rhs
    return 1
  endif
  return 0
endfunction

function! s:name(base, v) abort
  let l:type = a:v['type']
  if l:type ==# 'link' || l:type ==# 'junction'
    if isdirectory(resolve(a:base .. a:v['name']))
      let l:type = 'dir'
    endif
  elseif l:type ==# 'linkd'
    let l:type = 'dir'
  endif
  return a:v['name'] .. (l:type ==# 'dir' ? '/' : '')
endfunction

function! molder#init() abort
  let l:path = resolve(expand('%:p'))
  if !isdirectory(l:path)
    return
  endif
  let l:dir = fnamemodify(l:path, ':p:gs!\!/!')
  if isdirectory(l:dir) && l:dir !~# '/$'
    let l:dir .= '/'
  endif

  let b:molder_dir = l:dir
  setlocal modifiable
  setlocal filetype=molder buftype=nofile bufhidden=wipe nobuflisted noswapfile
  setlocal nowrap cursorline
  let l:files = map(readdirex(l:path, '1', {'sort': 'none'}), {_, v -> s:name(l:dir, v)})
  if !get(b:, 'molder_show_hidden', get(g:, 'molder_show_hidden', 0))
    call filter(l:files, 'v:val =~# "^[^.]"')
  endif
  silent keepmarks keepjumps call setline(1, sort(l:files, function('s:sort')))
  setlocal nomodified nomodifiable
  for l:fn in filter(split(execute('function'), "\n"), 'v:val =~# "^function molder#extension#\\w\\+#init().*"')
    call call(split(l:fn, ' ')[1][:-3], [])
  endfor
  let l:alt = fnamemodify(expand('#'), ':p:h:gs!\!/!')
  if substitute(l:dir, '/$', '', '') ==# l:alt
    let l:alt = fnamemodify(expand('#'), ':t')
    call search('\v^' .. alt, 'c')
  endif
endfunction

function! molder#open() abort
  exe 'edit' b:molder_dir .. substitute(getline('.'), '/$', '', '')
endfunction

function! molder#up() abort
  let l:dir = substitute(b:molder_dir, '/$', '', '')
  let l:name = fnamemodify(l:dir, ':t:gs!\!/!')
  if empty(l:name)
    return
  endif
  let l:dir = fnamemodify(l:dir, ':p:h:h:gs!\!/!')
  exe 'edit' l:dir
  call search('\v^' .. l:name, 'c')
endfunction

function! molder#home() abort
  exe 'edit' substitute(fnamemodify(expand('~'), ':p:gs!\!/!'), '/$', '', '')
endfunction

function! molder#reload() abort
  edit
endfunction

function! molder#curdir() abort
  return get(b:, 'molder_dir', '')
endfunction

function! molder#current() abort
  return getline('.')
endfunction

function! molder#toggle_hidden() abort
  let b:molder_show_hidden = !get(b:, 'molder_show_hidden', get(g:, 'molder_show_hidden', 0))
  call molder#reload()
endfunction

function! molder#error(msg) abort
  redraw
  echohl Error
  echomsg a:msg
  echohl None
endfunction

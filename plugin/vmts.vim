" 目次を表示するウィンドウを左右のどちら側に表示するのかを設定する
if exists("g:vmts_toc_side") && g:vmts_toc_side !=? "right"
   " ユーザー指定がrightでない場合、デフォルトの値を設定する
   let g:vmts_toc_side = "left"
else
   let g:vmts_toc_side = "left"
endif

" 目次を表示するウィンドウの幅を設定する
if exists("g:vmts_toc_width") && type(g:vmts_toc_width)
   " ユーザー指定の値が数値ではない場合、デフォルトの値に設定する
   let g:vmts_toc_width = 36
else
   let g:vmts_toc_width = 36
endif

" 目次に表示される階層を示す冒頭の半角スペースの数を設定する
if exists("g:vmts_toc_spaces") && type(g:vmts_toc_spaces) != type(0)
   " ユーザー指定がない場合はデフォルトの値に設定する
   let g:vmts_toc_spaces = 3
else
   let g:vmts_toc_spaces = 3
endif

" 目次の階層を表す#を目次ウィンドウでは非表示にするかを設定する
if exists("g:vmts_hide_hashes") && g:vmts_hide_hashes != v:true
   " ユーザー指定がない場合はデフォルトの値に設定する
   let g:vmts_hide_hashes = v:false
else
   let g:vmts_hide_hashes = v:false
endif

" 目次を閉じた時、対応するmarkdownウィンドウも閉じるかどうかを設定する
if exists("g:vmts_close_markdown_with_toc") && g:vmts_close_markdown_with_toc != v:true
   " ユーザー指定がない場合はデフォルトの値に設定する
   let g:vmts_close_markdown_with_toc = v:false
else
   let g:vmts_close_markdown_with_toc = v:false
endif

" 目次を表示する
command OpenMdToc call vmts#Open_Toc()
" 目次を更新する
command RefreshMdToc call vmts#Refresh_Toc()
" 目次を閉じる
command CloseMdToc call vmts#Close_Toc()
" ウィンドウ分割時に目次の表示を綺麗に整える
command AlignMdToc call vmts#Align_Toc()
" 目次から対応するmarkdownウィンドウへ、またはその逆への移動をするショートカット
noremap <Plug>(vmts-go-to-pair) :<C-u>call vmts#Go_To_Pair_Window()<CR>

" 目次を開いているmarkdownウィンドウが閉じられた時、目次を開いているウィンドウも同時に閉じるようにする
" option: 目次を閉じた時、対応するmarkdownを開いているウィンドウも閉じる
augroup VMTSQuit
   au!
   au QuitPre * call vmts#Close_Window()
augroup END

" ウィンドウのサイズが変更された場合、目次の幅を調整する
augroup VMTSResize
   au!
   au WinResized * call vmts#Resize_Toc_Width()
augroup END

" :writeした場合に目次を更新する
augroup VMTSWrite
   au!
   au BufWritePost *.md RefreshMdToc
augroup END

" ウィンドウのフォーカスを変更した際に、このプラグインで管理されているウィンドウの場合、別のバッファを開いていないかをチェックする
augroup VMTSCheck
   au!
   au BufEnter * call vmts#Check() | call vmts#Resize_Toc_Width()
augroup END

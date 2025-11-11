" md, markdown ≒ markdown window, markdown buff
" toc, 目次 ≒ toc windows
" wid = window-id

" 目次を表示するウィンドウを左右のどちら側に表示させているか
let s:side = g:vmts_toc_side

" 目次を開こうとする
fu! vmts#Open_Toc() abort
   " カレントウィンドウがmarkdownかつ、目次が表示されていない場合、目次を開く
   if &filetype ==# "markdown"
      let current_wid = win_getid()
      let check = vmts#Check()
      " 不具合がある場合は目次を開き直す
      if check == v:false
         call s:Open_Toc()
      " 目次が開かれていない場合は目次を開く
      elseif check == 2
         call s:Open_Toc()
      else
         return
      endif
      call win_gotoid(current_wid)
   else
      " 現在のウィンドウがmarkdownではない
      return
   endif
endfu

" 目次を開く
fu! s:Open_Toc() abort

   " カレントウィンドウはmarkdown
   let current_win = win_getid()
   " 目次のlocation-listを作成する
   call s:Make_Toc()
   " location-listのtitleを変更
   call setloclist(0, [], "a", {"title": bufname(bufnr())})
   " location-listの表示内容を変更
   set quickfixtextfunc=s:Replace_LocationList

   " 目次を表示
   if exists("g:vmts_toc_side")
      if g:vmts_toc_side ==# "right"
         rightbelow vertical lwindow
      else
         aboveleft vertical lwindow
      endif
   else
      aboveleft vertical lwindow
   endif


   " 目次の幅を調整
   if exists("g:vmts_toc_width")
      execute "vert res" .. g:vmts_toc_width
   else
      execute "vert res 36"
   endif

   " 目次ウィンドウにmdウィンドウIDを記憶する
   let w:vmts_md_wid = current_win
   " 目次ウィンドウにmdウィンドウのbufnrと自身のbufnrを記憶する
   let w:vmts_identity = {"md": winbufnr(current_win), "toc": bufnr()}
   " mdウィンドウに目次ウィンドウIDを記憶する
   call setwinvar(current_win, "vmts_toc_wid", win_getid())
   " mdウィンドウに自身のbufnrと目次のbufnrを記憶する
   call setwinvar(current_win, "vmts_identity", {"md": winbufnr(current_win), "toc": bufnr()})
   
   call s:Sync_Cursor(current_win)
endfu

" location-listを作成する
fu! s:Make_Toc() abort
   let list = [] " location-listに代入するリスト
   let lines = getline(1, "$")
   let in_bcode = 0 " ブロックコード内か否か

   for n in range(len(lines))
      " ブロックコード内はスキップする
      if -1 != match(lines[n], '^```')
         if in_bcode == 1
            let in_bcode = 0
         else
            let in_bcode = 1
         endif
      elseif in_bcode == 0
         " 見出しか
         if -1 != match(lines[n], '^#\{1,6}\s')
            call add(list, {"lnum": n+1, "end_lnum": n+1, "bufnr": bufnr(""), "pattern": "", "valid": 1, "vcol": 0, "nr": 0, "module": "", "type": "", "end_col": "", "col": 0, "text": lines[n]})
         endif
      endif
   endfor

   " 見出しが存在しない場合は---だけを表示する
   if len(list) == 0
      call add(list, {"lnum": 0, "end_lnum": 0, "bufnr": bufnr(""), "pattern": "", "valid": 1, "vcol": 0, "nr": 0, "module": "", "type": "", "end_col": "", "col": 0, "text": "# ---"})
   endif

   call setloclist(0, list)
endfu

" 目次に表示されるテキストを見出しだけに変更する
fu! s:Replace_LocationList(info) abort
   let items = getloclist(0)
   let ls = [] " 最終的に表示されるテキストのリスト
   for idx in items
      " quickfixウィンドウで表示されるテキスト
      let t = ""
      " 現在見ている見出しの階層の深さ
      let hierarchy = strcharlen(matchstr(idx.text, "^#*"))

      " 見出しの階層深さの数だけループする
      for x in range(hierarchy)
         if x != 0
            " 見出しの階層構造を表現するために先頭に空白を挿入する
            let t = t .. s:Create_Toc_Space()
         endif
      endfor

      " #を表示するか
      if g:vmts_hide_hashes != v:false
         " 表示しない
         let t = t .. matchstr(idx.text, ".*$", hierarchy+1)
      else
         let t = t .. idx.text
      endif

      call add(ls, t)
   endfor
   return ls
endfu

" g:vmts_toc_spacesを元に見出しの先頭に挿入する空白を作成する
fu! s:Create_Toc_Space() abort
   let spaces = ""
   let i = 0
   if exists("g:vmts_toc_spaces")
      while i < g:vmts_toc_spaces
         let spaces = spaces .. " "
         let i = i + 1
      endwhile
      return spaces
   else
      " デフォルトを返す
      return "   "
   endif
endfu


" 目次を更新する
fu! vmts#Refresh_Toc() abort
   " 目次にいる場合、mdへ移動する
   if exists("w:vmts_md_wid")
      if vmts#Check()
         call win_gotoid(w:vmts_md_wid)
      else
         return
      endif
   " markdownにいる場合
   elseif exists("w:vmts_toc_wid")
      if !vmts#Check()
         return
      endif
   " このプラグインの管理下にあるウィンドウにいない
   else
      return
   endif


   let current_wid = win_getid() " カレントウィンドウはmarkdown

   call s:Store_Cursor()
   call s:Refresh_Toc()
   call s:Restore_Cursor()
   call s:Sync_Cursor(current_wid)
   call vmts#Resize_Toc_Width()
endfu

" カーソル位置を保存する
" カレントウィンドウはmarkdown
fu! s:Store_Cursor() abort
   let current_wid = win_getid()
   let s:md_cursor_position = winsaveview() " markdownのカーソル位置を保存
   call win_gotoid(w:vmts_toc_wid)
   let s:toc_cursor_position = winsaveview() " TOCのカーソル位置を保存
   call win_gotoid(current_wid) " markdownウィンドウへ戻る
endfu

" 目次を更新する
fu! s:Refresh_Toc() abort
   call s:Make_Toc()
   call setloclist(0, [], "a", {"title": bufname(bufnr())})
   set quickfixtextfunc=s:Replace_LocationList

   " 目次を表示する位置が変更されていた場合、開き直す
   if s:side !=# g:vmts_toc_side
      " 目次を表示する側の設定を更新する
      let s:side = g:vmts_toc_side 

      " 目次を開き直す
      CloseMdToc
      OpenMdToc
   endif
endfu

" カーソル位置を復元する
" カレントウィンドウはmarkdown
fu! s:Restore_Cursor() abort
   call winrestview(s:md_cursor_position)
   call win_gotoid(w:vmts_toc_wid)
   call winrestview(s:toc_cursor_position)
endfu

" カーソルの位置と、目次のカーソルの位置を同期する
fu! s:Sync_Cursor(win_id) abort
   call win_gotoid(a:win_id) " カレントウィンドウはmd

   let l:ll = getloclist(0)
   let loclist = getloclist(0)
   let l:se_size = len(l:ll)
   let loclist_size = len(l:ll)

   let l:now = line(".")
   let current_line = line(".")
   let n = 1
   for crsr in loclist
      if loclist_size <= n
         call setloclist(0, [], "a", {"idx": n})
         call win_gotoid(w:vmts_toc_wid)
         call cursor(n, 1)
         call win_gotoid(w:vmts_md_wid)
         return

      elseif crsr.lnum <= current_line && current_line < loclist[n].lnum
         call setloclist(0, [], "a", {"idx": n})
         call win_gotoid(w:vmts_toc_wid)
         call cursor(n, 1)
         call win_gotoid(w:vmts_md_wid)
         return
      endif
      let n += 1
   endfor
endfunction

" 目次だけを閉じる
" g:vmts_close_markdown_with_toc=v:trueでも目次だけを閉じる
fu! vmts#Close_Toc() abort

   " カレントウィンドウがmarkdownの場合
   " 正しいウィンドウであることを確認した後、mdと目次を管理下から外し、目次を閉じる
   if exists("w:vmts_toc_wid") && vmts#Check()
      let md_wid = win_getid()
      let toc_wid = w:vmts_toc_wid
      call s:Remove_From_Monitoring(0, w:vmts_toc_wid)
      call win_gotoid(toc_wid)
      quit
      call win_gotoid(md_wid)
      return
   endif
      
   " カレントウィンドウが目次の場合
   if exists("w:vmts_md_wid") && vmts#Check()
      let md_wid = w:vmts_md_wid
      call s:Remove_From_Monitoring(1, w:vmts_md_wid)
      quit
      call win_gotoid(md_wid)
      return
   endif
endfu

" VMTSQuit
" ウィンドウを閉じた際に、対応するウィンドウも一緒に閉じるか
fu! vmts#Close_Window() abort
   " カレントウィンドウがmarkdownの場合、目次を閉じる
   if exists("w:vmts_toc_wid") && vmts#Check() && win_gotoid(w:vmts_toc_wid)
      quit " 目次も閉じる
      return
   endif

   " カレントウィンドウが目次の場合、許可されている場合markdownを閉じる
   if exists("w:vmts_md_wid") && vmts#Check() && win_gotoid(w:vmts_md_wid)
      call s:Remove_From_Monitoring(1, w:vmts_toc_wid)
      " 目次を閉じた時に対応するmarkdownを開いているウィンドウも閉じるか
      if exists("g:vmts_close_markdown_with_toc") && g:vmts_close_markdown_with_toc == v:true
         quit
         return
      endif
   endif
endfu

" タブ内の目次の幅を再調整する
fu! vmts#Resize_Toc_Width() abort
   let current_wid = win_getid()

   for win in gettabinfo(tabpagenr())[0].windows
      if getwinvar(win, "vmts_md_wid", 0)
         call win_gotoid(win)
         if vmts#Check()
            execute "vert res" .. g:vmts_toc_width
         endif
      endif
   endfor

   call win_gotoid(current_wid)
endfu

" タブ内の目次を整理する
fu! vmts#Align_Toc() abort
   let current_wid = win_getid()
   " 閉じた目次に対応するmarkdownウィンドウのリスト
   let md_wins = []

   " タブ内の目次を全て閉じる
   for win in gettabinfo(tabpagenr())[0].windows
      if getwinvar(win, "vmts_md_wid", 0)
         call win_gotoid(win)
         if vmts#Check()
            let md_wid = w:vmts_md_wid
            call s:Remove_From_Monitoring(1, md_wid)
            call add(md_wins, md_wid)
            quit
         endif
      endif
   endfor

   " 閉じた目次を開き直す
   for win in md_wins
      call win_gotoid(win)
      OpenMdToc
   endfor

   call win_gotoid(current_wid)
endfu

" 対応するもう一方のウィンドウへ移動する
fu! vmts#Go_To_Pair_Window() abort
   " カレントウィンドウがmdなら目次へ移動する
   if exists("w:vmts_toc_wid") && vmts#Check() && win_gotoid(w:vmts_toc_wid)
      return
   " カレントウィンドウが目次ならmdへ移動する
   elseif exists("w:vmts_md_wid") && vmts#Check() && win_gotoid(w:vmts_md_wid)
      return
   endif
endfu

" カレントウィンドウをチェックする
" このプラグインで管理されているウィンドウに必要な変数が全て存在するか, 変数の値に齟齬がないか, 別のバッファを開いていないかをチェックする
fu! vmts#Check() abort
   let current_wid = win_getid()

   " markdownウィンドウか
   if exists("w:vmts_toc_wid")
      " identity変数は存在する
      if exists("w:vmts_identity")
         let current_i = w:vmts_identity

         " identity変数の辞書に既定のキーが存在しない
         if !has_key(w:vmts_identity, "md") || !has_key(w:vmts_identity, "toc")
            call s:Remove_From_Monitoring(0, w:vmts_toc_wid)
         " 別のバッファを開いている
         elseif w:vmts_identity["md"] != bufnr()
            call s:Remove_From_Monitoring(0, w:vmts_toc_wid)
         " toc_widへ移動できない
         elseif !win_gotoid(w:vmts_toc_wid)
            call s:Remove_From_Monitoring(0, w:vmts_toc_wid)
         " identity変数は存在しない
         elseif !exists("w:vmts_identity")
            call s:Remove_From_Monitoring(1, current_wid)
         " identity変数の辞書に既定のキーは存在しない
         elseif !has_key(w:vmts_identity, "md") || !has_key(w:vmts_identity, "toc")
            call s:Remove_From_Monitoring(1, current_wid)
         " 別のバッファを開いている
         elseif w:vmts_identity["toc"] != bufnr()
            call s:Remove_From_Monitoring(1, current_wid)
         " current_window_identityとidentityは一致しない
         elseif current_i["md"] != w:vmts_identity["md"] || current_i["toc"] != w:vmts_identity["toc"]
            call s:Remove_From_Monitoring(1, current_wid)
         " md_wid変数は存在しない
         elseif !exists("w:vmts_md_wid")
            call s:Remove_From_Monitoring(1, current_wid)
         " current_windowとmd_widは一致しない
         elseif current_wid != w:vmts_md_wid
            call s:Remove_From_Monitoring(1, current_wid)
         " 確認完了
         else
            call win_gotoid(current_wid)
            return v:true
         endif
      else
         " markdownにidentity変数が存在しなかった
         call s:Remove_From_Monitoring(0, w:vmts_toc_wid)
      endif
      call win_gotoid(current_wid)
      return v:false

   " 目次ウィンドウか
   elseif exists("w:vmts_md_wid")
      " identity変数は存在する
      if exists("w:vmts_identity")
         let current_i = w:vmts_identity

         " identity変数の辞書に既定のキーが存在しない
         if !has_key(w:vmts_identity, "md") || !has_key(w:vmts_identity, "toc")
            call s:Remove_From_Monitoring(1, w:vmts_md_wid)
         " 別のバッファを開いている
         elseif w:vmts_identity["toc"] != bufnr()
            call s:Remove_From_Monitoring(1, w:vmts_md_wid)
         " md_widへ移動できない
         elseif !win_gotoid(w:vmts_md_wid)
            call s:Remove_From_Monitoring(1, w:vmts_md_wid)
         " identity変数は存在しない
         elseif !exists("w:vmts_identity")
            call s:Remove_From_Monitoring(0, current_wid)
         " identity変数の辞書に既定のキーは存在しない
         elseif !has_key(w:vmts_identity, "md") || !has_key(w:vmts_identity, "toc")
            call s:Remove_From_Monitoring(0, current_wid)
         " 別のバッファを開いている
         elseif w:vmts_identity["md"] != bufnr()
            call s:Remove_From_Monitoring(0, current_wid)
         " current_window_identityとidentityは一致しない
         elseif current_i["md"] != w:vmts_identity["md"] || current_i["toc"] != w:vmts_identity["toc"]
            call s:Remove_From_Monitoring(0, current_wid)
         " toc_wid変数は存在しない
         elseif !exists("w:vmts_toc_wid")
            call s:Remove_From_Monitoring(0, current_wid)
         " current_windowとtoc_widは一致しない
         elseif current_wid != w:vmts_toc_wid
            " このウィンドウに来る前のウィンドウが優先
            call s:Remove_From_Monitoring(0, current_wid)
         " 確認完了
         else
            call win_gotoid(current_wid)
            return v:true
         endif
      else
         " 目次のidentity変数が存在しない
         call s:Remove_From_Monitoring(1, w:vmts_md_wid)
      endif
      call win_gotoid(current_wid)
      return v:false

   " 関係ないウィンドウ
   else
      call win_gotoid(current_wid)
      return 2
   endif
endfu

" このプラグインの管理下から外す
" カレントウィンドウの種類(md=0, toc=1), カレントウィンドウの対のウィンドウID
fu! s:Remove_From_Monitoring(current_kind, pair_wid) abort
   let current_wid = win_getid()
   " markdown
   if a:current_kind == 0

         " markdownにいる
         if exists("w:vmts_identity")
            unlet w:vmts_identity
         endif

         if exists("w:vmts_toc_wid")
            let toc_wid = w:vmts_toc_wid
            unlet w:vmts_toc_wid

            " 目次に移動する
            if win_gotoid(toc_wid)

               if exists("w:vmts_identity")
                  unlet w:vmts_identity
               endif

               if exists("w:vmts_md_wid")
                  unlet w:vmts_md_wid
               endif

            " 目次に移動できなかった
            elseif win_gotoid(a:pair_wid)
               if exists("w:vmts_identity")
                  unlet w:vmts_identity
               endif

               if exists("w:vmts_md_wid")
                  unlet w:vmts_md_wid
               endif
            endif
         " toc_widが存在しない
         elseif win_gotoid(a:pair_wid)
            if exists("w:vmts_identity")
               unlet w:vmts_identity
            endif
            
            if exists("w:vmts_md_wid")
               unlet w:vmts_md_wid
            endif
         endif
   " toc
   elseif a:current_kind == 1

         " 移動せず目次にいる
         if exists("w:vmts_identity")
            unlet w:vmts_identity
         endif

         if exists("w:vmts_md_wid")
            let md_wid = w:vmts_md_wid
            unlet w:vmts_md_wid

            " mdに移動する
            if win_gotoid(md_wid)

               if exists("w:vmts_identity")
                  unlet w:vmts_identity
               endif

               if exists("w:vmts_toc_wid")
                  unlet w:vmts_toc_wid
               endif

            " 目次に移動できなかった
            elseif win_gotoid(a:pair_wid)

               if exists("w:vmts_identity")
                  unlet w:vmts_identity
               endif

               if exists("w:vmts_toc_wid")
                  unlet w:vmts_toc_wid
               endif
            endif
         " md_widが存在しない
         elseif win_gotoid(a:pair_wid)

            if exists("w:vmts_identity")
               unlet w:vmts_identity
            endif

            if exists("w:vmts_toc_wid")
               unlet w:vmts_toc_wid
            endif
         endif
   endif
   " この関数実行時のカレントウィンドウへ戻る
   call win_gotoid(current_wid)
endfu

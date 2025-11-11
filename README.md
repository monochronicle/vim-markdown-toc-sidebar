# Vim markdown TOC sidebar

A Vim/Neovim plugin that shows a Markdown file's table of contents in a sidebar (left or right).

Markdownファイルの目次を左右どちらかのサイドバーに表示するVim/Neovimプラグイン。

![image1](sample/screenshot-left-side.png)

## Installation.

Use your favorite plugin manager or the built-in package support.

好きなパッケージマネージャーか、組み込みのパッケージ機能を使ってください。

## Usage.

1. Open markdown file (`$vim file.md`, `$nvim file.md`).
2. Run `:OpenMdToc`.
3. Want to close the TOC, run `:CloseMdToc`.

1. マークダンファイルを開く(`$vim file.md`, `$nvim file.md`)。
2. `:OpenMdToc`を実行する。
3. TOCを閉じたい場合、`:CloseMdToc`を実行する。

## Commands.

```
" Open the markdown TOC in the sidebar.
" 目次を開く。
:OpenMdToc

" Close only the markdown TOC sidebar.
" 目次だけを閉じる。
:CloseMdToc

" Update the TOC.
" 目次を更新する。
:RefreshMdToc

" Align the TOC sidebar with the markdown window.
" 目次ウィンドウをmarkdownウィンドウの隣に並べ直す。
:AlignMdToc
```

## Config.

Use the :RefreshToc command to apply any configuration changes without restarting the plugin.

:RefreshMdTocを使用し、変更した設定を即座に反映させることができる

```
" Which side to open the TOC sidebar on ("left" or "right"). Default: "right".
" 目次サイドバーを開く側を指定する("left"または"right")。既定値: "right"。
let g:vtms_toc_side = "right"

" Width of the TOC sidebar. Default: 32.
" 目次サイドバーの幅。既定値: 32。
let g:vtms_toc_width = 42

" Number of spaces added per heading level to show hierarchy in the TOC. Default: 3.
" 見出しの階層を示すために、階層毎に挿入する半角スペースの数。既定値: 3。
let g:vtms_hierarchy_spaces = 2

" Hide heading "#" marks. Default: v:false.
" "#"を非表示にする。既定値: v:false。
let g:vtms_hide_hashes = v:true

" Close the paired Markdown window when the TOC is closed. Default: v:false.
" 目次を閉じた時、対応するmarkdownも閉じるかどうか。既定値: v:false.
let g:vtms_close_markdown_with_toc = v:true
```

## Shortcuts/mappings.

Jump focus between the Markdown file and its TOC sidebar.

Markdownと目次との間でフォーカスを切り替える。

```
" Example mapping
nnoremap <silent><Leader><Leader> <plug>(vmts-go-to-pair)
```

You can replace it with a command of your own.

自分用のコマンドに置き換えできる。

```
" Example command alias (map :OpneMdToc to :Ot)
command! Ot OpenMdToc
```

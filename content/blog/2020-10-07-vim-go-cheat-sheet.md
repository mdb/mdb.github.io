---
title: A Cheat Sheet for using vim-go
date: 2020-10-07
tags:
- vim
- golang
thumbnail: night_waves_thumb.png
teaser: My notes and personal cheat sheet for useful vim-go features.
draft: true
---

`:GoRun` to run a `.go` file
`:GoBuild` to build
`:GoTest` to test. Running `:GoTestFunc` while the cursor is inside a specific test function runs that specific function (though this doesn't seem to work with `ginkgo`)
`:GoInstall` to install
`:GoCoverage` calls `go test -coverprofile tempfile` under the hood. `:GoCoverageClear` clears the coverage. `:GoCoverageToggle` toggles between the two commands. `:GoCoverageBrowser`
If there are errors, `:cnext` and `:cprevious` navigate between the errors
You could add shortcuts too. For example, to build and run a Go program with `<leader>b` and `<leader>r`, add the following to your `.vimrc`:

```
autocmd FileType go nmap <leader>b <Plug>(go-build)
autocmd FileType go nmap <leader>r <Plug>(go-run)
```

`dif` deletes the "inner function" of a function under the cursor (and operators other than `d` work too. For example, `yif` yanks the function body)
Similarly, `daf` deletes "a function" under the cursor
For example, `vaf` selects in visual mode an entire function under the cursor

`:GoAlternate` jumps between source code and and the corresponding test file.

`:GoDef` will jump to the definition of the function or variable under the cursor. `:GoDefPop` will return you. `:GoDefStack` will list your history of locations.

`:GoDecls` shows all type and function declarations within the current file. When in the list view, typing "foo" -- for example -- will filter results based on a fuzzy search.

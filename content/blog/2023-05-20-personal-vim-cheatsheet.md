---
title: "An Updated Personal Vim Cheatsheet"
date: 2023-05-20T13:35:02Z
tags:
thumbnail:
teaser:
---

_Recently, I've been working in a large Go monorepo. A refreshed Vim
configuration has helped. This is my cheet sheat_.

## [vim-go](https://github.com/fatih/vim-go)

Running, building, and installing code:

* `:GoRun` to run a `.go` file
* `:GoBuild` to build
* `:GoInstall` to install

Testing code:

* `:GoTest` to test.
* `:GoTestFunc` while the cursor is inside a specific test function runs that specific function
* `:GoCoverage` calls `go test -coverprofile tempfile` under the hood.
* `:GoCoverageClear` clears the coverage.
* `:GoCoverageToggle` toggles between the two commands.
* `:GoCoverageBrowser` opens the coverage report in a browser

If there are errors, `:cnext` and `:cprevious` navigate between the errors.

You could add shortcuts too. For example, to build and run a Go program with `<leader>b` and `<leader>r`, add the following to your `.vimrc`:

```bash
autocmd FileType go nmap <leader>b <Plug>(go-build)
autocmd FileType go nmap <leader>r <Plug>(go-run)
```

Vetting code quality:

* `:GoLint!` runs `go lint` for the directory or file under the cursor

Editing code:

`vim-go` provides several text objects:

* `af` - "a function;" select contents from a function definition to the closing brackets. For example: `daf` deletes the function under the cursor. `yaf` yanks the function.
* `if` - "inside a function;" select contents of a function, excluding the function definition and the closing bracket.
* `ac` - "a comment;" select contents of current comment block.
* `ic` - "inner comment;" select contents of current comment, excluding the start and end comment markers.

Navigating and learning about code:

* `]]` and `[[` navigate between next and previous function declarations, respectively.
* `:GoDoc` displays documentation; `:GoDocBrowser` does so in a web browser.
* `:GoAlternate` jumps between source code and and the corresponding test file.
* `:GoDef` will jump to the definition of the function or variable under the cursor. `:GoDefPop` will return you. `:GoDefStack` will list your history of locations. I've got this configured via... `au FileType go nmap <Leader>dt <Plug>(go-def-tab)` such that `<Leader>dt` opens the definition in a new tab.

    ```
    au Filetype go nnoremap <leader>v :vsp <CR>:exe "GoDef" <CR>
    au Filetype go nnoremap <leader>s :sp <CR>:exe "GoDef"<CR>
    au Filetype go nnoremap <leader>t :tab split <CR>:exe "GoDef"<CR>
    ```
* `:GoDecls` shows all type and function declarations within the current file. When in the list view, typing "foo," for example, filters results based on a fuzzy search.

* `<leader>gh` opens the current line in GitHub (Thanks [vim-gh-line(https://github.com/ruanyl/vim-gh-line#how-to-use)!])
* `<leader>gb` blames the current line in GitHub

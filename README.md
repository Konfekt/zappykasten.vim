The [Zettelkasten](#Zettelkasten-Embracing-Tags-Over-Folders) note-taking method gathers all assorted notes, *Zettels* in german, in a single folder, *Kasten*, as crawlable text (or markdown) files that can be interlinked by name.

`Zappykasten` is a Vim plug-in to

- crawl note folders (using [fzf](https://github.com/junegunn/fzf) and [ripgrep](https://github.com/BurntSushi/ripgrep))
- create a note with the designated search terms if yet missing,
- insert a link to a note through content searches, and jump to/preview linked notes,
- insert and complete tags, and search for them.

## Requirements

`Zappykasten` should work on Linux, Mac and Microsoft Windows, notably in Git Bash and WSL.
Ensure you have Vim installed along with [Ripgrep](https://github.com/BurntSushi/ripgrep) and [FZF(.vim)](https://github.com/junegunn/fzf.vim).
To use `ripgrep`, either install it with a package manager (such as [Scoop](https://scoop.sh) on Microsoft Windows) or download a binary from its release page [Ripgrep](https://github.com/BurntSushi/ripgrep/releases) and place it in your `$PATH`.

## Installation

If you use [vim-plug](https://github.com/junegunn/vim-plug), then in the vim-plug block in your `.vimrc` file, add the following line between the `plug#begin` and `plug#end` calls:

```vim
Plug 'junegunn/fzf'
    Plug 'junegunn/fzf.vim'
        Plug 'Konfekt/zappykasten.vim'
```

Give [autosync](https://github.com/benstaniford/vim-autosync) a spin to keep it in sync with a git repo.

## Initial Setup

Set the directories in which to search for notes and a *main* directory, in which to store new notes (which both default to `~/zettelkasten`):

```vim
let g:zk_search_paths = [$HOME..'/zettelkasten']
" let g:zk_search_paths += [$HOME..'/diary']
" let g:zk_search_paths += [$HOME..'/Desktop']
let g:zk_main_directory = g:zk_search_paths[0]
```

If you come from [Alok Singh's notational-fzf-vim](https://github.com/alok/notational-fzf-vim), then it should be a matter of simply replacing all occurrences of initial `nv` in the variable names by `zk`.

## Instructions

To use `Zappykasten`:

- In Normal mode, type `:ZK` to search for notes by content.
    If a note doesn't exist, it will be created whose title is given by your search terms.
    (Use a mapping, say `nnoremap m, :<c-u>ZK<cr>` for faster access.)
- In Normal mode, press
    - `K`/`gf`  to preview/open the linked note under the cursor,
    - `[<Tab>`/`[<C-D>` to jump to the (tagged) word under the cursor, respectively
    - `[I`/`[D` to list all its occurrences (see `:help include-search`).
- In insert mode:
    - press `<C-X><C-I>` to complete words from linked notes.
    - press `<C-X><C-Z>` to insert a link to a note (Zettel), searching for the term before the cursor, which can be refined in a fuzzy searcher.
    - to insert a tag, such as `Zettel`, surround it with double brackets (such as in `[[Zettel]]`).

## Key Bindings in Fuzzy Search Window

Inside the Fuzzy Search Window opened by `:ZK`, hit

- `Ctrl-X` to create a new note,
- `Ctrl-Y` to yank the selected filenames (to clipboard as well),
- `Ctrl-S` to open the note in a horizontal split,
- `Ctrl-V` to open the note in a vertical split, or
- `Ctrl-T` to open the note in a a new tab.

# Zettelkasten: Embracing Tags Over Folders

A [Zettelkasten](https://zettelkasten.de/) consists of assorted text files, or **zettels**, which may link to each other by name.
Traditionally, these were stored in a card file box; today, they are kept in a digital directory, often in Markdown format.

Folders, whether paper-based or digital, traditionally organize files.
However, since our computers (with tools like `(rip)grep`) search across the contents of thousands of files in milliseconds, a folder tree to organize files is no longer required:

If we think of the folder as a category tag, then a folder attaches a single tag to a file;
yet, a file often pertains to more than one category.
Tagging, which integrates keywords directly into the text, is by any means much more practical than managing multiple folders;
even more so since these tags usually need not be explicitly added, but already appear in the text.
(Similar to finding a browser bookmark by its title instead of folder navigation.)

Best, this method aligns with the workings of our mind, as we often recall files by remembering related words rather than a single label.

# Credits

This is a fork of [Alok Singh's notational-fzf-vim](https://github.com/alok/notational-fzf-vim) to whom all credit shall be due and whose license restrictions apply.
If stands on the shoulders on Vim along with `ripgrep` and `fzf`.

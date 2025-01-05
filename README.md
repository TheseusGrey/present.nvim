# `present.nvim`

A Neovim plugin for rendering awesome presentations using Markdown!.

---
- [Installation](#Installation)
- [Configuration](#Configuration)
- [Feature](#Features)
- [Usage](#usage)
- [wiki](https://github.com/TheseusGrey/present.nvim/wiki) for integration examples and (eventually) more
- [Credits](#credits)
---

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'TheseusGrey/present.nvim',
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
}
```

## Configuration

`present.nvim` comes with the following default options:

```lua
options = {
  -- visual options
  styles = {
    -- number of characters between window edge an slide
    border = 8,
    -- win_config for slides, see `:h nvim_open_win` for more options
    slide_window = {
      relative = "editor",
      -- width = vim.o.columns - 2 * styles.border,
      -- height = vim.o.lines - 2 * styles.border,
      style = "minimal",
      border = "none",
      -- col = styles.border,
      -- row = styles.border / 2 - 1,
      zindex = 2,
    },
    -- win_config for code exec window, see `:h nvim_open_win` for more options
    executor_window = {
        relative = "editor",
        style = "minimal",
        noautocmd = true,
        width = vim.o.columns * 0.8,
        height = vim.o.lines * 0.8,
        row = math.floor((vim.o.lines - vim.o.lines * 0.8) / 2),
        col = math.floor((vim.o.columns - vim.o.columns * 0.8) / 2),
        border = "rounded",
      },
  },
  executors = {
    lua = require("present.executors").lua,
    -- see #Features for full list of languages supported by default
  },
  integrations = {
    -- Let markview control styling slide content
    markview = false,
  },
  keys = {
    slide_next = "n",
    slide_previous = "p",
    presentation_quit = "q",
    executor_quit = "q",
    executor_run = "X",
  },
}
```


## Features

### Code block execution

You can execute a code block on the current slide (defaults to `X` key), and the output will get displayed in a floating window. Currently supported executors are:

- `Lua`
- `Python`
- `Javascript`
- `Rust`

You can also configure a custom executor for any code block by defining an `executor` for the language using `opts.executors`.

## Code Examples

Here is a lua code block you can use to test out the code executor:

```lua
print("Hello presentation!", 37, true)
```

You can even have multiple code blocks, and even multiple languages!

```python
print("Hello from python")
```

## Usage

There's a few commands you can use to work with your presentations:

- `:PresentStart {n?}` Will start your presentation, if `n` is provided it will start at the given slide, otherwise it will start from the first slide.
- `:PresentResume` lets you pick up where you left off, starting the presentation from the last slide you were on (useful if you need to hope out to walk through another file)

You can also do this from lua using the following:

```lua
require("present").start_presentation {
  bufnr = 0, -- defaults to current buffer
  slide = 1, -- slide to start presentation from
}
```

Moving between slides defaults to `n` and `p` for **n**ext and **p**revious slides respectively.

Presentations and execution windows can both be closed with `q`. 

For any slides containing code blocks, you can cycle through executing the blocks in order using `X`.

## Credits

- Original plugin author: [teej_dv](https://github.com/tjdevries)

# `present.nvim`

A Neovim plugin for rendering awesome presentations using Markdown!.

---
- [Installation](#Installation)
- [Feature](#Features)
- [Usage](#usage)
- [Credits](#credits)
---

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'tjdevries/present.nvim',
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
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

You can start a presentation from any markdown buffer using `:PresentStart`, or via lua using:

```lua
require("present").start_presentation {}
```

Moving between slides defaults to `n` and `p` for **n**ext and **p**revious slides respectively.

## Credits

- Original plugin author: [teej_dv](https://github.com/tjdevries)

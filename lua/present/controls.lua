local controls = {}

local present_keymap = function(mode, key, callback, buf)
  vim.keymap.set(mode, key, callback, {
    buffer = buf,
  })
end

---@param presentation present.Presentation
---@param cb function
local foreach_window = function(presentation, cb)
  for name, float in pairs(presentation.windows) do
    cb(name, float)
  end
end

---@param presentation present.Presentation
---@param render_slide function
---@param options table
controls.set_slide_controls = function(presentation, render_slide, options)
  present_keymap("n", "n", function()
    presentation.current_slide = math.min(presentation.current_slide + 1, #presentation.content)
    render_slide(presentation)
  end, presentation.windows.body.buf)

  present_keymap("n", "p", function()
    presentation.current_slide = math.max(presentation.current_slide - 1, 1)
    render_slide(presentation)
  end, presentation.windows.body.buf)

  present_keymap("n", "q", function()
    vim.api.nvim_win_close(presentation.windows.body.win, true)
  end, presentation.windows.body.buf)

  -- TODO: swap this to cycle through the found fenced_code_blocks inside the slide
  -- present_keymap("n", "X", function()
  --   local slide = presentation.content.slides[presentation.current_slide]
  --   -- TODO: Make a way for people to execute this for other languages
  --   local block = slide.blocks[1]
  --   if not block then
  --     print("No blocks on this page")
  --     return
  --   end
  --
  --   local executor = options.executors[block.language]
  --   if not executor then
  --     print("No valid executor for this language")
  --     return
  --   end
  --
  --   -- Table to capture print messages
  --   local output = { "# Code", "", "```" .. block.language }
  --   vim.list_extend(output, vim.split(block.body, "\n"))
  --   table.insert(output, "```")
  --
  --   table.insert(output, "")
  --   table.insert(output, "# Output")
  --   table.insert(output, "")
  --   table.insert(output, "```")
  --   vim.list_extend(output, executor(block))
  --   table.insert(output, "```")
  --
  --   local buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
  --   local temp_width = math.floor(vim.o.columns * 0.8)
  --   local temp_height = math.floor(vim.o.lines * 0.8)
  --   vim.api.nvim_open_win(buf, true, {
  --     relative = "editor",
  --     style = "minimal",
  --     noautocmd = true,
  --     width = temp_width,
  --     height = temp_height,
  --     row = math.floor((vim.o.lines - temp_height) / 2),
  --     col = math.floor((vim.o.columns - temp_width) / 2),
  --     border = "rounded",
  --   })
  --
  --   vim.bo[buf].filetype = "markdown"
  --   vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
  -- end, presentation.windows.body.buf)

  local restore = {
    cmdheight = {
      original = vim.o.cmdheight,
      present = 0,
    },
  }

  -- Set the options we want during presentation
  for option, config in pairs(restore) do
    vim.opt[option] = config.present
  end

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = presentation.windows.body.buf,
    callback = function()
      -- Reset the values when we are done with the presentation
      for option, config in pairs(restore) do
        vim.opt[option] = config.original
      end

      foreach_window(presentation, function(_, float)
        pcall(vim.api.nvim_win_close, float.win, true)
      end)
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("present-resized", {}),
    callback = function()
      if not vim.api.nvim_win_is_valid(presentation.windows.body.win) or presentation.windows.body.win == nil then
        return
      end

      local updated = options.styles.create_window_configurations(options.styles)
      foreach_window(presentation, function(name, _)
        vim.api.nvim_win_set_config(presentation.windows[name].win, updated[name])
      end)

      -- Re-calculates current slide contents
      render_slide(presentation.current_slide)
    end,
  })
end

return controls

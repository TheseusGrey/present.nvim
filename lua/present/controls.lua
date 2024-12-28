local controls = {}

local present_keymap = function(mode, key, callback, buf)
  vim.keymap.set(mode, key, callback, {
    buffer = buf,
  })
end

local foreach_float = function(presentation, cb)
  for name, float in pairs(presentation.floats) do
    cb(name, float)
  end
end

controls.set_slide_controls = function(presentation, set_slide_content, options)
  present_keymap("n", "n", function()
    presentation.current_slide = math.min(presentation.current_slide + 1, #presentation.parsed.slides)
    set_slide_content(presentation.current_slide)
  end, presentation.floats.body.buf)

  present_keymap("n", "p", function()
    presentation.current_slide = math.max(presentation.current_slide - 1, 1)
    set_slide_content(presentation.current_slide)
  end, presentation.floats.body.buf)

  present_keymap("n", "q", function()
    vim.api.nvim_win_close(presentation.floats.body.win, true)
  end, presentation.floats.body.buf)

  present_keymap("n", "X", function()
    local slide = presentation.parsed.slides[presentation.current_slide]
    -- TODO: Make a way for people to execute this for other languages
    local block = slide.blocks[1]
    if not block then
      print("No blocks on this page")
      return
    end

    local executor = options.executors[block.language]
    if not executor then
      print("No valid executor for this language")
      return
    end

    -- Table to capture print messages
    local output = { "# Code", "", "```" .. block.language }
    vim.list_extend(output, vim.split(block.body, "\n"))
    table.insert(output, "```")

    table.insert(output, "")
    table.insert(output, "# Output")
    table.insert(output, "")
    table.insert(output, "```")
    vim.list_extend(output, executor(block))
    table.insert(output, "```")

    local buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
    local temp_width = math.floor(vim.o.columns * 0.8)
    local temp_height = math.floor(vim.o.lines * 0.8)
    vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      style = "minimal",
      noautocmd = true,
      width = temp_width,
      height = temp_height,
      row = math.floor((vim.o.lines - temp_height) / 2),
      col = math.floor((vim.o.columns - temp_width) / 2),
      border = "rounded",
    })

    vim.bo[buf].filetype = "markdown"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
  end, presentation.floats.body.buf)

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
    buffer = presentation.floats.body.buf,
    callback = function()
      -- Reset the values when we are done with the presentation
      for option, config in pairs(restore) do
        vim.opt[option] = config.original
      end

      foreach_float(presentation, function(_, float)
        pcall(vim.api.nvim_win_close, float.win, true)
      end)
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("present-resized", {}),
    callback = function()
      if not vim.api.nvim_win_is_valid(presentation.floats.body.win) or presentation.floats.body.win == nil then
        return
      end

      local updated = options.styles.create_window_configurations(options.styles)
      foreach_float(function(name, _)
        vim.api.nvim_win_set_config(presentation.floats[name].win, updated[name])
      end)

      -- Re-calculates current slide contents
      set_slide_content(presentation.current_slide)
    end,
  })
end

return controls

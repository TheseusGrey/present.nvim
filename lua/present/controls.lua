local controls = {}

local logger = require("present.logger")
local styles = require("present.styles")
local renderer = require("present.renderer")

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
---@param options present.Options
controls.set_slide_controls = function(presentation, options)
  local next_block = 1

  present_keymap("n", options.keys.slide_next, function()
    presentation.current_slide = math.min(presentation.current_slide + 1, #presentation.content)
    next_block = 1
    renderer.render_slide(presentation, options)
  end, presentation.windows.body.buf)

  present_keymap("n", options.keys.slide_previous, function()
    presentation.current_slide = math.max(presentation.current_slide - 1, 1)
    next_block = 1
    renderer.render_slide(presentation, options)
  end, presentation.windows.body.buf)

  present_keymap("n", options.keys.presentation_quit, function()
    if options.integrations.markview then
      local markview_availible, markview = pcall(require, "markview")
      if markview_availible then
        markview.clear(presentation.windows.body.buf)
      end
    end

    vim.api.nvim_win_close(presentation.windows.body.win, true)
  end, presentation.windows.body.buf)

  present_keymap("n", options.keys.executor_run, function()
    local slide = presentation.content[presentation.current_slide]
    local code_blocks = slide.code_blocks

    if #code_blocks == 0 then
      logger.info("present.nvim: No code blocks on current slide")
      return
    end

    local block = code_blocks[next_block]
    local executor = options.executors[block.language]
    if not executor then
      logger.error("present.nvim: no executor for block starting on line: " .. block.row_start)
      return
    end

    -- Table to capture print messages
    local output = { "# Code", "", "```" .. block.language }
    vim.list_extend(output, block.code)
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
    local win = vim.api.nvim_open_win(
      buf,
      true,
      vim.tbl_deep_extend("force", {
        relative = "editor",
        style = "minimal",
        noautocmd = true,
        width = temp_width,
        height = temp_height,
        row = math.floor((vim.o.lines - temp_height) / 2),
        col = math.floor((vim.o.columns - temp_width) / 2),
        border = "rounded",
      }, options.styles.executor_window)
    )

    present_keymap("n", options.keys.executor_quit, function()
      vim.api.nvim_win_close(win, true)
    end, buf)

    vim.bo[buf].filetype = "markdown"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
    next_block = math.max(math.fmod(next_block + 1, #code_blocks + 1), 1)
  end, presentation.windows.body.buf)

  local restore = {
    conceallevel = { original = vim.o.conceallevel, present = 3 },
    concealcursor = { original = vim.o.concealcursor, present = "nc" },
    cmdheight = { original = vim.o.cmdheight, present = 0 },
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

      local updated = styles.create_window_configurations(options.styles)
      foreach_window(presentation, function(name, _)
        vim.api.nvim_win_set_config(presentation.windows[name].win, updated[name])
      end)

      -- Re-calculates current slide contents
      renderer.render_slide(presentation, options)
    end,
  })
end

return controls

local renderer = {}

renderer.namespace = vim.api.nvim_create_namespace("present")

renderer.create_floating_window = function(config, enter)
  if enter == nil then
    enter = false
  end

  local buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
  local win = vim.api.nvim_open_win(buf, enter or false, config)

  return { buf = buf, win = win }
end

local set_slide_content = function(presentation)
  local background_config = presentation.window_confs.background
  local slide_config = presentation.window_confs.content
  local slide = presentation.parsed.slides[presentation.current_slide]

  local content = {}
  local title = "# " .. slide.title
  table.insert(content, title)
  table.insert(content, "")
  vim.list_extend(content, slide.body)

  local footer =
    string.format("%d / %d | %s", presentation.current_slide, #presentation.parsed.slides, presentation.title)

  background_config.footer = footer
  slide_config.title = slide.title

  -- Set slide content
  vim.api.nvim_buf_set_lines(presentation.windows.body.buf, 0, -1, false, content)
  vim.api.nvim_win_set_config(presentation.windows.background.win, background_config)
  vim.api.nvim_win_set_config(presentation.windows.body.win, slide_config)

  -- Set highlights
  vim.api.nvim_win_set_hl_ns(presentation.windows.background.win, renderer.namespace)
  vim.api.nvim_set_hl(0, "FloatFooter", { fg = "orange" })
end

---@param presentation present.Presentation
renderer.render_slide = function(presentation)
  local slide = presentation.content[presentation.current_slide]

  local footer = string.format("%d / %d | %s", presentation.current_slide, #presentation.content, presentation.title)

  presentation.window_confs.background.footer = footer
  presentation.window_confs.content.title = slide.content[1] -- TODO: Better title formatting

  -- Set slide content
  vim.api.nvim_buf_set_lines(presentation.windows.body.buf, 0, -1, false, slide.content)
  vim.api.nvim_win_set_config(presentation.windows.background.win, presentation.window_confs.background)
  vim.api.nvim_win_set_config(presentation.windows.body.win, presentation.window_confs.content)
end

renderer.render_title = function() end

return renderer

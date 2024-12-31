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

  -- Set highlights
  vim.api.nvim_set_hl(renderer.namespace, "FloatFooter", { fg = "orange" })
  vim.api.nvim_set_hl(renderer.namespace, "PresentHeader", { fg = "green", bg = "#FF0000" })
  vim.api.nvim_win_set_hl_ns(presentation.windows.background.win, renderer.namespace)
  vim.api.nvim_win_set_hl_ns(presentation.windows.body.win, renderer.namespace)

  -- Set extmarks
  for _, content in ipairs(slide.captures) do
    if content.name == "heading" then
      print("Header Found")
      renderer.render_title(presentation.windows.body.buf, content)
    end
  end
end

---@param buf number: slide content buffer number
---@param content present.SlideCapture: capture info on the title
renderer.render_title = function(buf, content)
  vim.api.nvim_buf_set_extmark(buf, renderer.namespace, content.row_start, content.col_start, {
    undo_restore = false,
    invalidate = true,

    hl_group = "PresentHeader",

    hl_mode = "combine",
    virt_text = { { content.text:gsub("^#* ", ""), "PresentHeader" } },
    virt_text_pos = "inline",
  })
end

return renderer

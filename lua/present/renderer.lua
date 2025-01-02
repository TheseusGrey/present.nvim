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

---@param presentation present.Presentation
renderer.render_slide = function(presentation)
  local slide = presentation.content[presentation.current_slide]

  local footer = string.format("%d / %d | %s", presentation.current_slide, #presentation.content, presentation.title)

  presentation.window_confs.background.footer = footer
  presentation.window_confs.content.title = vim.api.nvim_buf_get_name(0)

  -- Set slide content
  vim.api.nvim_buf_set_lines(presentation.windows.body.buf, 0, -1, false, slide.content)
  vim.api.nvim_win_set_config(presentation.windows.background.win, presentation.window_confs.background)
  vim.api.nvim_win_set_config(presentation.windows.body.win, presentation.window_confs.content)

  -- Set highlights
  vim.api.nvim_win_set_hl_ns(presentation.windows.background.win, renderer.namespace)
  vim.api.nvim_win_set_hl_ns(presentation.windows.body.win, renderer.namespace)
  renderer.highlight()

  -- Set extmarks
  for _, content in ipairs(slide.captures) do
    if content.name == "heading" then
      renderer.render_title(presentation.windows.body.buf, content)
    end
  end
end

---@param name string
renderer.get_hl = function(name)
  return vim.api.nvim_get_hl(0, {
    name = name,
    create = false,
  })
end

---@param buf number: slide content buffer number
---@param content present.SlideCapture: capture info on the title
renderer.render_title = function(buf, content)
  vim.api.nvim_set_hl(renderer.namespace, "PresentHeader", {})

  vim.api.nvim_buf_set_extmark(buf, renderer.namespace, content.row_start, content.col_start, {
    end_col = content.col_end,
    undo_restore = false,
    invalidate = true,

    hl_group = "PresentHeader",

    hl_mode = "replace",
    virt_text = {
      { " " .. content.text:gsub("^#* ", "") .. string.rep(" ", content.text:len()), "PresentHeader" },
    },
    virt_text_pos = "overlay",
  })

  vim.api.nvim_buf_set_extmark(buf, renderer.namespace, content.row_start + 1, content.col_start, {
    end_row = content.row_end + 1,
    undo_restore = false,
    invalidate = true,

    hl_group = "PresentHeader",

    hl_mode = "combine",
    virt_text = {
      { string.rep("🮂", content.text:len() + 1) },
    },
    virt_text_pos = "inline",
    conceal = "",
  })
end

renderer.highlight = function()
  vim.api.nvim_set_hl(renderer.namespace, "FloatFooter", { fg = "orange" })
end

return renderer

local renderer = {}

local logger = require("present.logger")

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
---@param opts present.Options
renderer.render_slide = function(presentation, opts)
  local slide = presentation.content[presentation.current_slide]

  local footer = string.format("%d / %d | %s", presentation.current_slide, #presentation.content, presentation.title)

  presentation.window_confs.background.footer = footer
  presentation.window_confs.content.title = vim.api.nvim_buf_get_name(0)

  -- Set slide content
  vim.api.nvim_buf_set_lines(presentation.windows.body.buf, 0, -1, false, slide.content)
  vim.api.nvim_win_set_config(presentation.windows.background.win, presentation.window_confs.background)
  vim.api.nvim_win_set_config(
    presentation.windows.body.win,
    vim.tbl_deep_extend("force", presentation.window_confs.content, opts.styles.slide_window)
  )

  if opts.integrations.markview then
    if not vim.cmd.Markview then
      logger.error("present.nvim: Markview cmd not found, is the plugin installed and enabled?")
    end

    vim.cmd.Markview("attach")
    vim.cmd.Markview("enable")
  else
    -- Set highlights
    vim.api.nvim_win_set_hl_ns(presentation.windows.background.win, renderer.namespace)
    vim.api.nvim_win_set_hl_ns(presentation.windows.body.win, renderer.namespace)
    renderer.highlight()

    -- Set extmarks
    for _, content in ipairs(slide.captures) do
      if content.name == "heading" then
        renderer.render_heading(presentation.windows.body.buf, content)
      elseif content.name == "subheading" then
        renderer.render_subheading(presentation.windows.body.buf, content)
      elseif content.name == "horizontal_rule" then
      end
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
renderer.render_heading = function(buf, content)
  -- col_end is relative to the marker (e.g. "## ..."), not the whole header
  local level = content.col_end
  vim.api.nvim_set_hl(renderer.namespace, "PresentHeading", { link = "markdownH" .. level, bold = true })

  vim.api.nvim_buf_set_extmark(buf, renderer.namespace, content.row_start, content.col_start, {
    end_col = content.col_end,
    undo_restore = false,
    invalidate = true,

    hl_group = "PresentHeading",

    hl_mode = "replace",

    virt_text = {
      { " " .. content.text:gsub("^#* ", "") .. string.rep(" ", content.text:len()), "PresentHeading" },
    },
    virt_text_pos = "overlay",
    conceal = "",
  })

  vim.api.nvim_buf_set_extmark(buf, renderer.namespace, content.row_start + 1, content.col_start, {
    end_row = content.row_end + 1,
    undo_restore = false,
    invalidate = true,

    hl_group = "PresentHeading",

    hl_mode = "combine",
    virt_text = {
      { string.rep("▔", content.text:len() + 1), "PresentHeading" },
    },
    virt_text_pos = "inline",
    conceal = "",
  })
end

---@param buf number: slide content buffer number
---@param content present.SlideCapture: capture info on the title
renderer.render_subheading = function(buf, content)
  -- col_end is relative to the marker (e.g. "## ..."), not the whole header
  local level = content.col_end
  vim.api.nvim_set_hl(renderer.namespace, "PresentSubheading", { link = "markdownH" .. level, bold = true })

  vim.api.nvim_buf_set_extmark(buf, renderer.namespace, content.row_start, content.col_start, {
    end_col = content.col_end,
    undo_restore = false,
    invalidate = true,

    hl_group = "PresentSubheading",

    hl_mode = "replace",

    virt_text = {
      { content.text:gsub("^#* ", "") .. string.rep(" ", content.text:len()), "PresentSubheading" },
    },
    virt_text_pos = "overlay",
    conceal = "",
  })
end

renderer.highlight = function()
  vim.api.nvim_set_hl(renderer.namespace, "FloatFooter", { fg = "orange" })
end

return renderer

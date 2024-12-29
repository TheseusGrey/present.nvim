local M = {}
local renderer = require("present.renderer")
local executors = require("present.executors")
local parser = require("present.parser")
local styles = require("present.styles")
local controls = require("present.controls")

local options = {
  styles = {
    border = 8,
    executor_window = {},
  },
  executors = {
    lua = executors.lua,
    javascript = executors.create_system_executor("node"),
    python = executors.create_system_executor("python"),
    rust = executors.rust,
  },
}

M.setup = function(opts)
  opts = opts or {}

  vim.tbl_deep_extend("force", options, opts)
  options = opts
end

---@type present.Presentation
local presentation = {
  parsed = {},
  current_slide = 1,
  slide_buf = {},
  windows = {},
  window_confs = {},
  content = {},
  title = "",
}

local foreach_float = function(cb)
  for name, float in pairs(presentation.windows) do
    cb(name, float)
  end
end

M.test = function(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or 0

  local parsed = parser.parse(opts.bufnr)
  if parsed == nil then
    vim.notify("present.nvim: unable to parse buffer, might not be a markdown file?", vim.log.levels.ERROR)
    return
  end
  presentation.content = parsed
  presentation.current_slide = 1
  presentation.title = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(opts.bufnr), ":t")

  presentation.window_confs = styles.create_window_configurations(options.styles)
  presentation.windows.background = renderer.create_floating_window(presentation.window_confs.background)
  presentation.windows.body = renderer.create_floating_window(presentation.window_confs.content, true)
  vim.bo[presentation.windows.body.buf].filetype = "markdown"

  controls.set_slide_controls(presentation, renderer.render_slide, options)
  -- renderer.render_slide(presentation.content[presentation.current_slide])
end

M.start_presentation = function(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or 0

  presentation.parsed = parser.query_slides(opts.bufnr)
  presentation.current_slide = 1
  presentation.title = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(opts.bufnr), ":t")

  local windows = styles.create_window_configurations(options.styles)
  presentation.windows.background = renderer.create_floating_window(windows.background)
  presentation.windows.body = renderer.create_floating_window(windows.content, true)

  foreach_float(function(_, float)
    vim.bo[float.buf].filetype = "markdown"
  end)

  local set_slide_content = function(id)
    local background_config = windows.background
    local slide_config = windows.content
    local slide = presentation.parsed.slides[id]

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

  controls.set_slide_controls(presentation, set_slide_content, options)
  set_slide_content(presentation.current_slide)
end

return M

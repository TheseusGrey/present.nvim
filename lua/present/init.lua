local M = {}
local renderer = require("present.renderer")
local executors = require("present.executors")
local parser = require("present.parser")
local styles = require("present.styles")
local controls = require("present.controls")
local logger = require("present.logger")

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

M.start_presentation = function(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or 0

  local parsed = parser.parse(opts.bufnr)
  if parsed == nil then
    logger.warn("present.nvim: unable to parse buffer, might not be a markdown file?")
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
  renderer.render_slide(presentation)
end

return M

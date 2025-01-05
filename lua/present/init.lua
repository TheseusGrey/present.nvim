local M = {}
local renderer = require("present.renderer")
local executors = require("present.executors")
local parser = require("present.parser")
local styles = require("present.styles")
local controls = require("present.controls")
local logger = require("present.logger")

---@type present.Options
M.options = {
  styles = {
    border = 8,
    slide_window = {},
    executor_window = {},
  },
  executors = {
    lua = executors.lua,
    javascript = executors.create_system_executor("node"),
    python = executors.create_system_executor("python"),
    rust = executors.rust,
  },
  integrations = {
    markview = false,
  },
  keys = {
    slide_next = "n",
    slide_previous = "p",
    presentation_quit = "q",
    executor_quit = "q",
    executor_run = "X",
  },
}

M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

---@type present.Presentation
M.presentation = {
  captures = {},
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
  M.presentation.content = parsed
  M.presentation.current_slide = opts.slide or 1
  M.presentation.title = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(opts.bufnr), ":t")

  M.presentation.window_confs = styles.create_window_configurations(M.options.styles)
  M.presentation.windows.background = renderer.create_floating_window(M.presentation.window_confs.background)
  M.presentation.windows.body = renderer.create_floating_window(M.presentation.window_confs.content, true)
  vim.bo[M.presentation.windows.body.buf].filetype = "markdown"

  controls.set_slide_controls(M.presentation, M.options)
  renderer.render_slide(M.presentation, M.options)
end

return M

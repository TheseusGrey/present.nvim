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

renderer.render_title = function() end

return renderer

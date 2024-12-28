local styles = {}

styles.create_window_configurations = function(slide_styles)
  slide_styles = slide_styles or {}
  local width = vim.o.columns
  local height = vim.o.lines

  return {
    background = {
      relative = "editor",
      width = width,
      height = height - 2,
      style = "minimal",
      border = "solid",
      col = 0,
      row = 0,
      footer = "test",
      footer_pos = "right",
      zindex = 1,
    },
    content = {
      relative = "editor",
      width = width - 2 * slide_styles.border,
      height = height - 2 * slide_styles.border,
      style = "minimal",
      border = "none",
      col = slide_styles.border,
      row = slide_styles.border / 2 - 1,
      zindex = 2,
    },
  }
end

return styles

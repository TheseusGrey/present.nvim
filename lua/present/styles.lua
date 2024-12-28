local styles = {}

styles.create_window_configurations = function(slide_styles)
  slide_styles = slide_styles or {}
  local width = vim.o.columns
  local height = vim.o.lines

  local header_height = 1 + 2 -- 1 + border
  local footer_height = 1 -- 1, no border
  local body_height = height - header_height - footer_height - 2 - 1 -- for our own border

  return {
    background = {
      relative = "editor",
      width = width,
      height = height,
      style = "minimal",
      col = 0,
      row = 0,
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
      footer = "",
      footer_pos = "right",
      zindex = 2,
    },
    header = {
      relative = "editor",
      width = width,
      height = 1,
      style = "minimal",
      border = "rounded",
      col = 0,
      row = 0,
      zindex = 2,
    },
    body = {
      relative = "editor",
      width = width - 8,
      height = body_height,
      style = "minimal",
      border = { " ", " ", " ", " ", " ", " ", " ", " " },
      col = 8,
      row = 4,
    },
    footer = {
      relative = "editor",
      width = width,
      height = 1,
      style = "minimal",
      -- TODO: Just a border on the top?
      -- border = "rounded",
      col = 0,
      row = height - 1,
      zindex = 3,
    },
  }
end

return styles

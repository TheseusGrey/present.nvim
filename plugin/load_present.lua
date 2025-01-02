vim.api.nvim_create_user_command("PresentStart", function(opts)
  require("present").start_presentation({ slide = tonumber(opts.args) })
end, { nargs = "?" })

vim.api.nvim_create_user_command("PresentResume", function()
  local last_slide = require("present").presentation.current_slide
  require("present").start_presentation({ slide = last_slide })
end, {})

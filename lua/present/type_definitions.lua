---@class present.Presentation
---@field title string: title of the presentation, defaults to buffer name
---@field current_slide integer: current slide of the presentation
---@field windows table: table containing the `win` and `buf` of the `background` and `body` of the presentation
---@field window_confs table<string, vim.api.keyset.win_config>: table with the corresponding configs for the presentation windows
---@field content present.Slide[]: content parsed from the markdown file used for the presentation

---@class present.Slide
---@field content string[]: Markdown text that makes up the slide
---@field captures present.SlideCapture[]: Capture info on slide content

---@class present.SlideCapture
---@field id integer: id of the capture
---@field node TSNode: node from the capture if needed
---@field name string: name of the node
---@field text string: text of the node
---@field row_start integer
---@field row_end integer
---@field col_start integer
---@field col_end integer

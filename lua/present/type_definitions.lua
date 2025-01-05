---@class present.Presentation
---@field title string: title of the presentation, defaults to buffer name
---@field current_slide integer: current slide of the presentation
---@field windows table: table containing the `win` and `buf` of the `background` and `body` of the presentation
---@field window_confs table<string, vim.api.keyset.win_config>: table with the corresponding configs for the presentation windows
---@field content present.Slide[]: content parsed from the markdown file used for the presentation

---@class present.Slide
---@field content string[]: Markdown text that makes up the slide
---@field code_blocks present.CodeBlock[]: Any code blocks found on the slide
---@field captures present.SlideCapture[]: Capture info on slide content

---@class present.CodeBlock
---@field language string: Language used by the code block
---@field code string[]: code contained inside the block
---@field row_start integer
---@field row_end integer

---@class present.SlideCapture
---@field id integer: id of the capture
---@field slide integer: clide the capture is located on
---@field node TSNode: node from the capture if needed
---@field name string: name of the node
---@field text string: text of the node
---@field row_start integer
---@field row_end integer
---@field col_start integer
---@field col_end integer

---@class present.Options
---@field styles present.options.styles?
---@field executors present.options.executors?
---@field integrations present.Integrations?
---@field keys present.Keymaps?

---@class present.options.styles
---@field border number?
---@field executor_window vim.api.keyset.win_config?
---@field slide_window vim.api.keyset.win_config?

---@class present.Integrations
---@field markview boolean?

---@class present.Keymaps
---@field slide_next string?
---@field slide_previous string?
---@field presentation_quit string?
---@field executor_quit string?
---@field executor_run string?

---@class present.options.executors

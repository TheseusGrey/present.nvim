local parser = {}

local ts_available, treesitter_parsers = pcall(require, "nvim-treesitter.parsers")
local logger = require("present.logger")

--- Checks if a parser is available or not
---@param name string
---@return boolean
local function parser_installed(name)
  return (ts_available and treesitter_parsers.has_parser(name)) or pcall(vim.treesitter.query.get, name, "highlights")
end

local queries = vim.treesitter.query.parse(
  "markdown",
  [[
		((setext_heading) @setext_heading)

		(atx_heading [
			(atx_h1_marker)
			(atx_h2_marker)
		] @heading)

    (atx_heading [
			(atx_h3_marker)
			(atx_h4_marker)
			(atx_h5_marker)
			(atx_h6_marker)
    ] @subheading)

		((fenced_code_block) @code)

		((block_quote) @block_quote)

		((thematic_break) @horizontal_rule)

		((pipe_table) @table)

		((task_list_marker_unchecked) @checkbox_off)
		((task_list_marker_checked) @checkbox_on)

		((list_item) @list_item)
	]]
)

local inline_queries = vim.treesitter.query.parse(
  "markdown_inline",
  [[
		((shortcut_link) @callout)

		([
			(inline_link)
			(full_reference_link)
		] @hyperlink)
			
		((email_autolink) @email)
		((image) @image)

		((code_span) @code)

		((entity_reference) @entity)

		((backslash_escape) @escaped)
	]]
)

---@param root TSNode: root nose to parse content from
---@param bufnr integer: buffer of parsed tree
---@param current_slide present.Slide
---@param slide_number integer
---@param last_slide_row_end integer
local parse_inline_captures = function(root, bufnr, current_slide, slide_number, last_slide_row_end)
  for id, node, _ in inline_queries:iter_captures(root, bufnr, 0, -1) do
    local capture_name = queries.captures[id]
    local capture_text = vim.treesitter.get_node_text(node, bufnr)
    local row_start, col_start, row_end, col_end = node:range()

    table.insert(current_slide.captures, {
      id = id,
      slide = slide_number,
      node = node,
      name = capture_name,
      text = capture_text,
      row_start = row_start - last_slide_row_end,
      row_end = row_end - last_slide_row_end,
      col_start = col_start,
      col_end = col_end,
    })
  end
end

---@param bufnr integer
---@return present.Slide[]|nil
parser.parse = function(bufnr)
  if not parser_installed("markdown") then
    logger.error("present.nvim: No Markdown parser found, cannot create slides!")
    return
  end

  ---@type present.Slide[]
  local parsed_content = {}

  local tree_parser = vim.treesitter.get_parser(bufnr)
  local root = tree_parser:parse()[1]:root()

  local current_row_header = 0
  local last_slide_row_end = 0

  ---@type present.Slide
  local current_slide = {
    content = {},
    captures = {},
    code_blocks = {},
  }

  for id, node, _ in queries:iter_captures(root, bufnr, 0, -1) do
    local capture_name = queries.captures[id]
    local capture_text = vim.treesitter.get_node_text(node, bufnr)
    local row_start, col_start, row_end, col_end = node:range()

    if capture_name == "heading" and row_start ~= 0 then
      current_slide.content = vim.api.nvim_buf_get_lines(bufnr, current_row_header, row_start, false)
      current_row_header = row_start
      last_slide_row_end = row_end
      parse_inline_captures(root, bufnr, current_slide, #parsed_content, last_slide_row_end)
      table.insert(parsed_content, current_slide)
      current_slide = {
        content = {},
        captures = {},
        code_blocks = {},
      }
    end

    -- Grab full parent node to get full heading text
    if capture_name == "heading" or capture_name == "subheading" then
      ---@diagnostic disable-next-line: param-type-mismatch
      capture_text = vim.treesitter.get_node_text(node:parent(), bufnr)
    end

    if capture_name == "code" then
      ---@diagnostic disable-next-line: param-type-mismatch
      local language = vim.treesitter.get_node_text(node:child(1), bufnr)
      local code = vim.api.nvim_buf_get_lines(bufnr, row_start + 1, row_end - 1, false)
      ---@type present.CodeBlock
      table.insert(current_slide.code_blocks, {
        language = language,
        code = code,
        row_start = row_start - last_slide_row_end,
        row_end = row_end - last_slide_row_end,
      })
    end

    table.insert(current_slide.captures, {
      id = id,
      slide = #parsed_content,
      node = node,
      name = capture_name,
      text = capture_text,
      row_start = row_start - last_slide_row_end,
      row_end = row_end - last_slide_row_end,
      col_start = col_start,
      col_end = col_end,
    })
  end
  current_slide.content = vim.api.nvim_buf_get_lines(bufnr, current_row_header, -1, false)
  table.insert(parsed_content, current_slide)

  return parsed_content
end

return parser

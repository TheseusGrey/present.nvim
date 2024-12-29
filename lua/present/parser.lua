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

---@param bufnr integer
---@return present.Slide[]|nil
parser.parse = function(bufnr)
  if not parser_installed("markdown") then
    logger.error("present.nvim: No Markdown parser found, cannot create slides!")
    return
  end

  ---@type present.Slide[]
  local parsed_content = {}

  ---@type present.Slide
  local current_slide = {
    content = {},
    captures = {},
  }

  local tree_parser = vim.treesitter.get_parser(bufnr)
  local root = tree_parser:parse()[1]:root()
  for id, node, _ in queries:iter_captures(root, bufnr, 0, -1) do
    local capture_name = queries.captures[id]
    local capture_text = vim.treesitter.get_node_text(node, bufnr)
    local row_start, col_start, row_end, col_end = node:range()

    if capture_name == "heading" and row_start ~= 0 then
      table.insert(parsed_content, current_slide)
      current_slide = {
        content = {},
        captures = {},
      }
    end

    -- Grab full parent node to get full heading text
    if capture_name == "heading" or capture_name == "subheading" then
      ---@diagnostic disable-next-line: param-type-mismatch
      capture_text = vim.treesitter.get_node_text(node:parent(), bufnr)
    end

    table.insert(current_slide.content, capture_text)

    table.insert(current_slide.captures, {
      id = id,
      node = node,
      name = capture_name,
      text = capture_text,
      row_start = row_start,
      row_end = row_end,
      col_start = col_start,
      col_end = col_end,
    })
  end
  table.insert(parsed_content, current_slide)

  return parsed_content
end

return parser

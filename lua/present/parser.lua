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

		((code_span) @inline_code)

		((entity_reference) @entity)

		((backslash_escape) @escaped)
	]]
)

---@param tree TSTree: tree or sub-tree to parse
---@param bufnr integer: buffer of parsed tree
---@param parsed_content present.Slide[]
---@param from integer: 0-indexed row number the tree or subtree starts at in the document
---@param to integer: 0-indexed row number the tree or subtree ends at in the document
parser.md_inline = function(tree, bufnr, parsed_content, from, to)
  if not parser_installed("markdown_inline") then
    logger.error("present.nvim: No inline markdown parser found, cannot create slides!")
    return
  end

  local get_slide = function(row_start)
    local rows = 0
    local slide_row_start = 0
    local slide_row_end = 0
    for index, slide in pairs(parsed_content) do
      rows = rows + #slide.content
      slide_row_start = slide_row_end
      slide_row_end = rows

      if row_start < rows then
        return index, slide_row_start, slide_row_end - 1
      end
    end
    return #parsed_content, slide_row_start, slide_row_end - 1
  end

  local root = tree:root()
  for id, node, _ in inline_queries:iter_captures(root, bufnr, from, to) do
    local capture_name = queries.captures[id]
    local capture_text = vim.treesitter.get_node_text(node, bufnr)
    local row_start, col_start, row_end, col_end = node:range()

    local slide, slide_start, _ = get_slide(row_start)
    row_start = 0

    table.insert(parsed_content[slide].captures, {
      id = id,
      node = node,
      name = capture_name,
      text = capture_text,
      row_start = row_end - slide_start,
      row_end = row_end - slide_start,
      col_start = col_start,
      col_end = col_end,
    })
  end
end

---@param tree TSTree
---@param bufnr integer
---@param from integer: 0-indexed row number the tree or subtree starts at in the document
---@param to integer: 0-indexed row number the tree or subtree ends at in the document
parser.md = function(tree, bufnr, parsed_content, from, to)
  if not parser_installed("markdown") then
    logger.error("present.nvim: No Markdown parser found, cannot create slides!")
    return
  end

  ---@type present.Slide
  local current_slide = {
    content = {},
    captures = {},
    code_blocks = {},
  }

  local root = tree:root()
  local row_heading = 0
  local last_slide_row_end = 0
  for id, node, _ in queries:iter_captures(root, bufnr, from, to) do
    local capture_name = queries.captures[id]
    local capture_text = vim.treesitter.get_node_text(node, bufnr)
    local row_start, col_start, row_end, col_end = node:range()

    if capture_name == "heading" and row_start ~= 0 then
      current_slide.content = vim.api.nvim_buf_get_lines(bufnr, row_heading, row_start, false)
      row_heading = row_start
      last_slide_row_end = row_end
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
  current_slide.content = vim.api.nvim_buf_get_lines(bufnr, row_heading, -1, false)
  table.insert(parsed_content, current_slide)
end

---@param buf number
parser.parse = function(buf)
  ---@type present.Slide[]
  local parsed_content = {}

  local buf_parser = vim.treesitter.get_parser(buf)
  buf_parser:parse(true)

  buf_parser:for_each_tree(function(ts_tree, language_tree)
    local language = language_tree:lang()
    local row_start, _, row_end, _ = ts_tree:root():range()

    -- challange is working out what slide we're on T_T
    if language == "markdown" then
      parser.md(ts_tree, buf, parsed_content, row_start, row_end)
    elseif language == "markdown_inline" then
      parser.md_inline(ts_tree, buf, parsed_content, row_start, row_end)
    end
  end)

  return parsed_content
end

return parser

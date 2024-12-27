local parser = {}

-- Matches on every section in a markdown doc, returning the header and content of the section
local slide_query = vim.treesitter.query.parse(
  "markdown",
  [[
(section 
  (atx_heading
    (atx_h1_marker)
    heading_content: (_) @header
    )
  (_)+ @content)+

(fenced_code_block
  (info_string
    (language) @language)
  (code_fence_content) @code)
]]
)

---@param bufnr integer|nil
---@return present.Slides
parser.query_slides = function(bufnr)
  bufnr = bufnr or 0

  local tree = vim.treesitter.get_parser(bufnr):parse()
  local root = tree[1]:root()

  local slides = { slides = {} }
  local current_slide = {
    title = "",
    body = {},
    blocks = {},
  }
  local code_block = {
    language = "",
    body = {},
  }
  for id, node, _ in slide_query:iter_captures(root, bufnr, 0, -1) do
    local name = slide_query.captures[id]
    local text = vim.treesitter.get_node_text(node, 0)
    local type = node.type(node)

    -- Every time we hit a header, insert the slide so we can start a new one
    if name == "header" and current_slide.title ~= "" then
      table.insert(slides.slides, current_slide)
    end

    if name == "header" then
      current_slide.title = text
    elseif name == "content" then
      table.insert(current_slide.body, text)
    elseif name == "language" then
      code_block.language = text
    elseif name == "code" then
      code_block.body = text
      table.insert(current_slide.blocks, code_block)
      -- Code blocks are always a single "language" capture, followed by a single "code" capture, so we can safely
      -- insert the code block here
    end
  end

  -- Insert last slide since there's not other heading to trigger the insert
  table.insert(slides, current_slide)
  vim.print(slides.slides)
  return slides
end

--- Takes some lines and parses them
---@param lines string[]: The lines in the buffer
---@return present.Slides
parser.parse_slides = function(lines)
  local slides = { slides = {} }
  local current_slide = {
    title = "",
    body = {},
    blocks = {},
  }

  local separator = "^#"

  for _, line in ipairs(lines) do
    if line:find(separator) then
      if #current_slide.title > 0 then
        table.insert(slides.slides, current_slide)
      end

      current_slide = {
        title = line,
        body = {},
        blocks = {},
      }
    else
      table.insert(current_slide.body, line)
    end
  end

  table.insert(slides.slides, current_slide)

  for _, slide in ipairs(slides.slides) do
    local block = {
      language = nil,
      body = "",
    }
    local inside_block = false
    for _, line in ipairs(slide.body) do
      if vim.startswith(line, "```") then
        if not inside_block then
          inside_block = true
          block.language = string.sub(line, 4)
        else
          inside_block = false
          block.body = vim.trim(block.body)
          table.insert(slide.blocks, block)
        end
      else
        -- OK, we are inside of a current markdown block
        -- but it is not one of the guards.
        -- so insert this text
        if inside_block then
          block.body = block.body .. line .. "\n"
        end
      end
    end
  end

  return slides
end

return parser

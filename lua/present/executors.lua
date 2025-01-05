local executors = {}

--- Default executor for Rust code
---@param block present.CodeBlock
executors.rust = function(block)
  local tempfile = vim.fn.tempname() .. ".rs"
  local outputfile = tempfile:sub(1, -4)
  vim.fn.writefile(block.code, tempfile)
  local result = vim.system({ "rustc", tempfile, "-o", outputfile }, { text = true }):wait()
  if result.code ~= 0 then
    local output = vim.split(result.stderr, "\n")
    return output
  end
  result = vim.system({ outputfile }, { text = true }):wait()
  return vim.split(result.stdout, "\n")
end

--- Default executor for lua code
---@param block present.CodeBlock
executors.lua = function(block)
  -- Override the default print function, to capture all of the output
  -- Store the original print function
  local original_print = print

  local output = {}

  -- Redefine the print function
  print = function(...)
    local args = { ... }
    local message = table.concat(vim.tbl_map(tostring, args), "\t")
    table.insert(output, message)
  end

  -- Call the provided function
  local chunk = loadstring(table.concat(block.code, "\n"))
  pcall(function()
    if not chunk then
      table.insert(output, " <<<BROKEN CODE>>>")
    else
      chunk()
    end

    return output
  end)

  -- Restore the original print function
  print = original_print

  return output
end

---@param program string: name of program that will run the code
executors.create_system_executor = function(program)
  ---@param block present.CodeBlock
  return function(block)
    local tempfile = vim.fn.tempname()
    vim.fn.writefile(block.code, tempfile)
    local result = vim.system({ program, tempfile }, { text = true }):wait()
    return vim.split(result.stdout, "\n")
  end
end

return executors

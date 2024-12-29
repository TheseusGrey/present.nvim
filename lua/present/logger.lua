local logger = {}

---@param msg string
logger.info = function(msg)
  vim.notify(msg, vim.log.levels.INFO)
end

---@param msg string
logger.error = function(msg)
  vim.notify(msg, vim.log.levels.ERROR)
end

---@param msg string
logger.warn = function(msg)
  vim.notify(msg, vim.log.levels.WARN)
end

return logger

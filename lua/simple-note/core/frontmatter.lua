local util = require("simple-note.util")

local M = {}

---@param line string
---@return boolean
local function delimiter(line)
  return vim.trim(line or "") == "+++"
end

---@param line string
---@return boolean
local function blank(line)
  return vim.trim(line or "") == ""
end

---@param args string[]
function M.run(args)
  if #args > 1 then
    util.notify("frontmatter takes no arguments")
    return
  end

  local cfg = require("simple-note").config
  local ext = vim.fn.expand("%:e")
  local matched = false
  for _, item in ipairs(cfg.frontmatter_extensions or {}) do
    if item == ext then
      matched = true
      break
    end
  end
  if not matched then
    util.notify(("frontmatter: unsupported extension: %s"):format(ext))
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if lines[1] and vim.trim(lines[1]) == "---" then
    util.notify("YAML frontmatter is not supported")
    return
  end

  if not delimiter(lines[1]) then
    local out = { "+++", "", "+++", "" }
    for _, line in ipairs(lines) do
      out[#out + 1] = line
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    return
  end

  local close
  for i = 2, #lines do
    if delimiter(lines[i]) then
      close = i
      break
    end
  end
  if not close then
    util.notify("unterminated frontmatter (missing closing +++)")
    return
  end

  if blank(lines[close - 1]) then
    vim.api.nvim_win_set_cursor(0, { close - 1, 0 })
    return
  end

  table.insert(lines, close, "")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { close, 0 })
end

return M

local M = {}

M._items = nil

---@param dir string
---@param rel string
---@param out string[]
local function scan(dir, rel, out)
  local ok, iter = pcall(vim.fs.dir, dir)
  if not ok then
    return
  end
  for name, kind in iter do
    if name:sub(1, 1) ~= "." and kind ~= "link" then
      local next_rel = rel == "" and name or (rel .. "/" .. name)
      if kind == "directory" then
        scan(dir .. "/" .. name, next_rel, out)
      elseif kind == "file" and name:match("%.md$") then
        out[#out + 1] = next_rel:gsub("%.md$", "")
      end
    end
  end
end

---@return string[]
function M.list()
  if M._items then
    return M._items
  end
  local items = {}
  local cfg = require("simple-note").config
  local ok = require("simple-note.config").validate_relative(cfg.templates_dir)
  if not ok then
    M._items = items
    return items
  end
  local root = require("simple-note.vault").root()
  local dir = require("simple-note.util").join(root, cfg.templates_dir)
  if vim.fn.isdirectory(dir) == 1 then
    scan(dir, "", items)
  end
  table.sort(items)
  M._items = items
  return items
end

function M.refresh()
  M._items = nil
  return M.list()
end

---@param prefix string
---@return string[]
function M.complete(prefix)
  local out = {}
  for _, item in ipairs(M.list()) do
    if item:sub(1, #prefix) == prefix then
      out[#out + 1] = item
    end
  end
  return out
end

return M

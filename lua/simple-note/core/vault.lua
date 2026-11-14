local util = require("simple-note.util")
local vault = require("simple-note.vault")

local M = {}

---@param path string
---@param root string
---@return boolean
local function in_vault(path, root)
  local normalized = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
  return normalized == root .. "/" or normalized:sub(1, #root + 1) == root .. "/"
end

---@param args string[]
function M.run(args)
  if #args > 1 then
    util.notify("vault takes no arguments")
    return
  end
  local root = vault.ensure()
  if not root then
    util.notify("cannot prepare vault")
    return
  end

  local target
  for _, path in ipairs(vim.v.oldfiles or {}) do
    if in_vault(path, root) and vim.fn.filereadable(path) == 1 then
      target = path
      break
    end
  end

  if not target then
    target = util.join(root, "Untitle.md")
    if not util.file_exists(target) then
      local ok, err = util.write_lines(target, {})
      if not ok then
        util.notify(tostring(err))
        return
      end
    end
  end

  vault.cd_root()
  vault.open_tab(target)
end

return M

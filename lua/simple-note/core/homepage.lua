local util = require("simple-note.util")
local vault = require("simple-note.vault")

local M = {}

---@param args string[]
function M.run(args)
  if #args > 1 then
    util.notify("homepage takes no arguments")
    return
  end
  local path, err = vault.homepage_path()
  if not path then
    util.notify(tostring(err))
    return
  end
  util.cd(vim.fn.fnamemodify(path, ":h"))
  vault.open_tab(path)
end

return M

local M = {}

local initial = require("simple-note.config")
M.defaults = initial.defaults
M.config = vim.deepcopy(initial.defaults)
M._opts = {}

---@param opts table?
---@param refresh_welcome boolean?
---@return table
function M.setup(opts, refresh_welcome)
  M._opts = opts or {}
  local config = require("simple-note.config")
  M.defaults = config.defaults
  M.config = config.merge(M._opts)
  require("simple-note.commands").setup()
  if refresh_welcome ~= false then
    require("simple-note.welcome").setup(M.config)
  end
  return M.config
end

function M.reload()
  local names = {}
  for name in pairs(package.loaded) do
    if name:match("^simple%-note%.") then
      names[#names + 1] = name
    end
  end
  for _, name in ipairs(names) do
    package.loaded[name] = nil
  end

  M.setup(M._opts, false)

  local ok, mfc = pcall(require, "markdown-frontmatter-complete")
  if ok and type(mfc.reload) == "function" then
    pcall(mfc.reload)
  end
  if ok and vim.fn.exists(":MFC") == 2 then
    pcall(vim.cmd, "MFC rebuild")
  end
  return M.config
end

return M

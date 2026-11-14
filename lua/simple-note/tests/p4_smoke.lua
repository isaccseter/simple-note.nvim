vim.o.swapfile = false
vim.o.hidden = true
pcall(function()
  require("astrocore").config.sessions.autosave = false
end)
pcall(vim.api.nvim_clear_autocmds, { group = "resession_auto_save" })
local sn = require("simple-note")

local snacks = require("snacks")
local keys = snacks.config.dashboard.preset.keys
local function count_v()
  local n = 0
  for _, item in ipairs(keys) do
    if item.key == "v" then
      n = n + 1
    end
  end
  return n
end
assert(count_v() == 1, "welcome entry added once")
assert(package.loaded["simple-note.core"] == nil, "core not loaded at startup")

local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp .. "/Templates/sub", "p")
vim.fn.writefile({ "+++", "+++", "a" }, tmp .. "/Templates/a.md")
vim.fn.writefile({ "+++", "+++", "b" }, tmp .. "/Templates/sub/b.md")
vim.fn.writefile({ "+++", "+++", "hidden" }, tmp .. "/Templates/.hidden.md")
sn.setup({ vault = tmp, welcome = false })

local function comp(line)
  return vim.fn.getcompletion(line, "cmdline")
end
local function contains(list, value)
  for _, item in ipairs(list) do
    if item == value then
      return true
    end
  end
  return false
end

local c = comp("Snote template ")
assert(contains(c, "a"), "template a")
assert(contains(c, "sub/b"), "template sub/b")
assert(not contains(c, ".hidden"), "hidden excluded")
assert(package.loaded["simple-note.core"] ~= nil, "template Tab loads core")
assert(contains(comp("Snote ntemplate "), "a"), "ntemplate completion")
assert(not contains(comp("Snote template a "), "a"), "title position no template")

vim.fn.writefile({ "+++", "+++", "c" }, tmp .. "/Templates/c.md")
assert(not contains(comp("Snote template "), "c"), "template list is cached")
local before = count_v()
vim.cmd("Snote reload")
assert(contains(comp("Snote template "), "c"), "reload refreshes templates")
assert(count_v() == before, "reload does not duplicate welcome entry")
assert(sn.config.vault == tmp, "reload keeps saved opts")
assert(vim.fn.exists(":Snote") == 2, "command after reload")

vim.cmd("silent! tabonly")
vim.cmd("silent! %bwipeout!")
vim.fn.delete(tmp, "rf")
print("P4 smoke ok")

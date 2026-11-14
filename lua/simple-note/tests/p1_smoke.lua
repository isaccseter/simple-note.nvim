local sn = require("simple-note")
local cfg = require("simple-note.config")

assert(sn.config.welcome == true, "welcome default")
assert(vim.fn.exists(":Snote") == 2, ":Snote command must exist")
assert(package.loaded["simple-note.core"] == nil, "core must not load at startup")

local comp = vim.fn.getcompletion("Snote ", "cmdline")
assert(#comp >= 9, "subcommand completion")
assert(package.loaded["simple-note.core"] == nil, "subcommand completion must not load core")

vim.cmd("Snote")
assert(package.loaded["simple-note.core"] == nil, "no-arg Snote must not load core")

vim.cmd("Snote bogus")
assert(package.loaded["simple-note.core"] == nil, "invalid subcommand must not load core")

assert(cfg.is_absolute("/tmp/x"), "absolute path detection")
assert(cfg.has_parent("a/../b"), "parent detection")
assert(not cfg.validate_relative("../x"), "parent must be rejected")
assert(cfg.validate_relative("notes/x"), "relative must be accepted")

vim.o.swapfile = false
vim.o.hidden = true
local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")
sn.setup({ vault = tmp, welcome = false })
vim.v.oldfiles = {}
vim.cmd("Snote vault")
assert(package.loaded["simple-note.core"] ~= nil, "valid subcommand must load core")

vim.cmd("silent! tabonly")
vim.cmd("silent! %bwipeout!")
vim.fn.delete(tmp, "rf")
print("P1 smoke ok")

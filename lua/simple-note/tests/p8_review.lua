vim.o.swapfile = false
vim.o.hidden = true
pcall(function()
  require("astrocore").config.sessions.autosave = false
end)
pcall(vim.api.nvim_clear_autocmds, { group = "resession_auto_save" })

local sn = require("simple-note")
local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp .. "/Templates", "p")
sn.setup({ vault = tmp, welcome = false })

-- vault: oldfiles hit
local old = tmp .. "/old.md"
vim.fn.writefile({ "+++", "+++", "old" }, old)
vim.v.oldfiles = { old }
vim.cmd("Snote vault")
assert(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t") == "old.md", "vault oldfile")

-- daily: template without basename -> target date
vim.fn.writefile({ "+++", "+++", "body" }, tmp .. "/Templates/nobase.md")
sn.setup({ vault = tmp, welcome = false, daily_template = "nobase.md" })
vim.cmd("Snote daily 0")
local target = os.date("%Y-%m-%d")
assert(vim.fn.filereadable(tmp .. "/Daily/" .. target .. ".md") == 1, "daily no basename")

-- new: no title -> Untitle
sn.setup({ vault = tmp, welcome = false, defaultnew_template = "default-new.md" })
vim.cmd("Snote new")
assert(vim.fn.filereadable(tmp .. "/Untitle.md") == 1, "new no title")

-- frontmatter: existing blank reused
vim.cmd("edit " .. vim.fn.fnameescape(tmp .. "/front.md"))
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "+++", "", "+++", "x" })
vim.cmd("Snote frontmatter")
local l = vim.api.nvim_buf_get_lines(0, 0, -1, false)
assert(#l == 4 and l[2] == "" and l[3] == "+++", "frontmatter blank reuse")
assert(vim.api.nvim_win_get_cursor(0)[1] == 2, "frontmatter cursor")

-- homepage missing: no file created
sn.setup({ vault = tmp, welcome = false, homepage = "missing.md" })
vim.cmd("Snote homepage")
assert(vim.fn.filereadable(tmp .. "/missing.md") == 0, "homepage missing no file")

vim.cmd("silent! tabonly")
vim.cmd("silent! %bwipeout!")
vim.fn.delete(tmp, "rf")
print("P8 SNn review ok")

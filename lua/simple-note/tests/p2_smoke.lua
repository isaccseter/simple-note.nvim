local sn = require("simple-note")

vim.o.swapfile = false
vim.o.hidden = true
pcall(function()
  require("astrocore").config.sessions.autosave = false
end)
pcall(vim.api.nvim_clear_autocmds, { group = "resession_auto_save" })

local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")
sn.setup({ vault = tmp, welcome = false, homepage = "home.md" })

local function lines(path)
  return vim.fn.readfile(path)
end

local function assert_file(path)
  assert(vim.fn.filereadable(path) == 1, "file missing: " .. path)
end

-- frontmatter: empty file
local md = tmp .. "/front.md"
vim.cmd("edit " .. vim.fn.fnameescape(md))
vim.cmd("Snote frontmatter")
local l = vim.api.nvim_buf_get_lines(0, 0, -1, false)
assert(l[1] == "+++" and l[2] == "" and l[3] == "+++", "empty frontmatter")
assert(vim.api.nvim_win_get_cursor(0)[1] == 2, "cursor middle")

-- frontmatter: existing without blank
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "+++", "a = 1", "+++" })
vim.cmd("Snote frontmatter")
l = vim.api.nvim_buf_get_lines(0, 0, -1, false)
assert(l[1] == "+++" and l[2] == "a = 1" and l[3] == "" and l[4] == "+++", "insert blank")

-- YAML rejected
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "---", "a: 1", "---" })
vim.cmd("Snote frontmatter")
l = vim.api.nvim_buf_get_lines(0, 0, -1, false)
assert(l[1] == "---", "YAML unchanged")

-- vault: create dirs/daily template and Untitle
vim.v.oldfiles = {}
vim.cmd("Snote vault")
assert_file(tmp .. "/Untitle.md")
assert_file(tmp .. "/Templates/daily.md")
assert(vim.fn.isdirectory(tmp .. "/Daily") == 1, "Daily dir")

-- daily: today + input
vim.cmd("Snote today foo")
local date = os.date("%Y-%m-%d")
assert_file(tmp .. "/Daily/" .. date .. "-foo.md")
assert(lines(tmp .. "/Daily/" .. date .. "-foo.md")[2] == 'type = "daily"', "type daily")

-- new: path + cursor
vim.cmd("Snote new notes/hello")
assert_file(tmp .. "/notes/hello.md")
assert(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t") == "hello.md", "new buffer")
assert(vim.api.nvim_win_get_cursor(0)[1] >= 1, "cursor")

-- new: hidden final rejected
vim.cmd("Snote new .hidden")
assert(vim.fn.filereadable(tmp .. "/.hidden.md") == 0, "hidden rejected")

-- ntemplate missing rejected
vim.cmd("Snote ntemplate missing")
assert(vim.fn.filereadable(tmp .. "/missing.md") == 0, "missing template rejected")

-- ntemplate + basename + input + title
vim.fn.writefile({
  "+++",
  'basename = "X-{{input}}"',
  "+++",
  "{{title}} / {{input}}",
}, tmp .. "/Templates/custom.md")
vim.cmd("Snote ntemplate custom notes/hello")
assert_file(tmp .. "/notes/X-hello.md")
local custom = lines(tmp .. "/notes/X-hello.md")
assert(custom[#custom] == "X-hello / {{input}}", "custom ntemplate content")

-- dedupe
vim.cmd("Snote new hello")
vim.cmd("Snote new hello")
assert_file(tmp .. "/hello.md")
assert_file(tmp .. "/hello-1.md")

-- daily +1
vim.cmd("Snote daily 1")
local tomorrow = os.date("%Y-%m-%d", os.time() + 86400)
assert_file(tmp .. "/Daily/" .. tomorrow .. ".md")

-- homepage
vim.fn.writefile({ "# Home" }, tmp .. "/home.md")
vim.cmd("Snote homepage")
assert(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t") == "home.md", "homepage buffer")

vim.cmd("silent! wall")
vim.cmd("silent! tabonly")
vim.cmd("silent! %bwipeout!")
vim.fn.delete(tmp, "rf")
print("P2 smoke ok")

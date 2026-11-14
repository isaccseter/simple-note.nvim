vim.o.swapfile = false
vim.o.hidden = true
pcall(function()
  require("astrocore").config.sessions.autosave = false
end)
pcall(vim.api.nvim_clear_autocmds, { group = "resession_auto_save" })
local sn = require("simple-note")
local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")
sn.setup({ vault = tmp, welcome = false })
vim.fn.mkdir(tmp .. "/Templates", "p")
vim.fn.writefile({
  "+++",
  'type = "template"',
  'tags = ["b","c"]',
  "draft = true",
  'status = "ready"',
  "created = {{date}}",
  "+++",
  "template body {{title}}",
}, tmp .. "/Templates/tpl.md")

local function set_lines(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end
local function get_lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end
local function has(lines, needle)
  for _, line in ipairs(lines) do
    if line == needle then
      return true
    end
  end
  return false
end

vim.cmd("edit " .. vim.fn.fnameescape(tmp .. "/note.md"))
set_lines({
  "+++",
  'type = "note"',
  'tags = ["a"]',
  "draft = false",
  'status = "inbox"',
  "+++",
  "",
  "body",
})
vim.cmd("Snote template tpl")
local out = get_lines()
assert(has(out, 'type = "template"'), "substitute type")
assert(has(out, 'tags = ["a","b","c",]'), "merge arrays: " .. vim.inspect(out))
assert(has(out, "draft = true"), "boolean replace")
assert(has(out, 'status = "ready"'), "substitute status")
assert(has(out, "template body note"), "body title")
assert(out[#out] == "template body note", "body appended")
assert(has(out, ""), "blank before body")

-- scalar + array -> flatten
set_lines({ "+++", 'tags = "a"', "+++", "x" })
vim.cmd("Snote template tpl")
out = get_lines()
assert(has(out, 'tags = ["a","b","c",]'), "scalar + array flatten")

-- array + scalar -> append
set_lines({ "+++", 'tags = ["a"]', "+++", "x" })
vim.cmd("Snote template tpl")
out = get_lines()
assert(has(out, 'tags = ["a","b","c",]'), "array + scalar append")

-- scalar + scalar -> array
set_lines({ "+++", 'tags = "a"', "+++", "x" })
vim.cmd("Snote template tpl")
out = get_lines()
assert(has(out, 'tags = ["a","b","c",]'), "scalar + scalar array")

-- complex current skipped
set_lines({ "+++", "tags = [{a = 1}]", "+++", "x" })
vim.cmd("Snote template tpl")
out = get_lines()
assert(has(out, "tags = [{a = 1}]"), "complex untouched")

-- multi-line array append
set_lines({ "+++", "tags = [", '  "a",', "]", "+++", "x" })
vim.cmd("Snote template tpl")
out = get_lines()
assert(has(out, '  "a",'), "multiline old element")
assert(has(out, '  "b",'), "multiline new b")
assert(has(out, '  "c",'), "multiline new c")

-- multi-line array without trailing comma
set_lines({ "+++", "tags = [", '  "a"', "]", "+++", "x" })
vim.cmd("Snote template tpl")
out = get_lines()
assert(has(out, '  "a",'), "add comma to previous")
assert(has(out, '  "b",'), "multiline no comma b")

-- template basename is removed when creating a block
vim.fn.writefile({ "+++", 'basename = "X-{{input}}"', 'tags = ["b"]', "+++", "body" }, tmp .. "/Templates/base.md")
set_lines({ "original" })
vim.cmd("Snote template base")
out = get_lines()
for _, line in ipairs(out) do
  assert(not line:match("^basename%s*="), "basename removed")
end
assert(has(out, 'tags = ["b"]'), "template key added")
assert(has(out, "original"), "original content")

-- YAML current rejected
set_lines({ "---", "a: 1", "---" })
vim.cmd("Snote template tpl")
out = get_lines()
assert(out[1] == "---", "YAML current unchanged")

-- missing template rejected
set_lines({ "+++", "+++", "x" })
vim.cmd("Snote template missing")
out = get_lines()
assert(out[2] == "+++", "missing template unchanged")

-- comments preserved on scalar->array and array append
vim.fn.writefile({ "+++", 'tags = ["b","c"]', "+++", "body" }, tmp .. "/Templates/simple.md")
set_lines({ "+++", 'tags = ["a"] # note', "+++", "x" })
vim.cmd("Snote template simple")
out = get_lines()
assert(has(out, 'tags = ["a","b","c",] # note'), "comment preserved")

-- duplicate template key: last wins
vim.fn.writefile({ "+++", 'tags = ["b"]', 'tags = ["c"]', "+++", "body" }, tmp .. "/Templates/dup.md")
set_lines({ "+++", 'tags = ["a"]', "+++", "x" })
vim.cmd("Snote template dup")
out = get_lines()
assert(has(out, 'tags = ["a","c",]'), "duplicate template last wins")

-- empty template block
vim.fn.writefile({ "+++", "+++", "body" }, tmp .. "/Templates/empty.md")
set_lines({ "x" })
vim.cmd("Snote template empty")
out = get_lines()
assert(out[1] == "+++" and out[2] == "+++", "empty block inserted")
assert(has(out, "x"), "original kept")

-- YAML template rejected
vim.fn.writefile({ "---", "a: 1", "---" }, tmp .. "/Templates/yaml.md")
set_lines({ "+++", 'tags = ["a"]', "+++", "x" })
vim.cmd("Snote template yaml")
out = get_lines()
assert(has(out, 'tags = ["a"]'), "YAML template unchanged")

-- multiline array with closing bracket on last element line
set_lines({ "+++", "tags = [", '  "a"]', "+++", "x" })
vim.cmd("Snote template simple")
out = get_lines()
assert(has(out, '  "a","b","c",]'), "closing bracket on element line")

-- new key goes before table headers
set_lines({ "+++", 'title = "old"', "[table]", "x = 1", "+++", "body" })
vim.cmd("Snote template simple")
out = get_lines()
local tags_idx, table_idx
for i, line in ipairs(out) do
  if line:match("^tags%s*=") then
    tags_idx = i
  end
  if line == "[table]" then
    table_idx = i
  end
end
assert(tags_idx and table_idx and tags_idx < table_idx, "top-level key before table")

-- no frontmatter: create block + blank + original
set_lines({ "# body" })
vim.cmd("Snote template tpl")
out = get_lines()
assert(out[1] == "+++", "block created")
assert(has(out, "# body"), "original kept")
assert(has(out, "template body note"), "body from template")

-- current body only, template no frontmatter
vim.fn.writefile({ "only body {{title}}" }, tmp .. "/Templates/body.md")
set_lines({ "# body" })
vim.cmd("Snote template body")
out = get_lines()
assert(out[1] == "# body", "no block")
assert(out[#out] == "only body note", "body-only template")

vim.cmd("silent! wall")
vim.cmd("silent! tabonly")
vim.cmd("silent! %bwipeout!")
vim.fn.delete(tmp, "rf")
print("P3 smoke ok")

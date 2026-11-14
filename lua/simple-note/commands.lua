local M = {}

M.subcommands = {
  "vault",
  "today",
  "daily",
  "homepage",
  "frontmatter",
  "new",
  "ntemplate",
  "template",
  "reload",
}

local valid = {}
for _, name in ipairs(M.subcommands) do
  valid[name] = true
end

---@param msg string
---@param level integer?
local function notify(msg, level)
  vim.notify("Snote: " .. msg, level or vim.log.levels.WARN)
end

---@param arglead string
---@param cmdline string
---@param cursorpos integer
---@return string[]
function M.complete(arglead, cmdline, cursorpos)
  local before = cmdline:sub(1, cursorpos)
  local trailing = before:match("%s$") ~= nil
  local parts = vim.split(before, "%s+", { trimempty = true })
  local rest = {}
  for i = 2, #parts do
    rest[#rest + 1] = parts[i]
  end

  if #rest == 0 or (#rest == 1 and not trailing) then
    local out = {}
    for _, name in ipairs(M.subcommands) do
      if name:sub(1, #arglead) == arglead then
        out[#out + 1] = name
      end
    end
    return out
  end

  local sub = rest[1]
  if sub == "ntemplate" or sub == "template" or sub == "new_from_template" then
    local template_pos = (#rest == 1 and trailing) or (#rest == 2 and not trailing)
    if template_pos then
      pcall(require, "simple-note.core")
      local ok, templates = pcall(require, "simple-note.templates")
      if ok then
        return templates.complete(arglead)
      end
    end
  end
  return {}
end

---@param opts table
function M.dispatch(opts)
  local args = opts.fargs or {}
  local sub = args[1]
  if not sub then
    notify("usage: :Snote <vault|today|daily|homepage|frontmatter|new|ntemplate|template|reload>")
    return
  end
  if not valid[sub] then
    notify(("unknown subcommand: %s"):format(sub), vim.log.levels.ERROR)
    return
  end

  local ok, core = pcall(require, "simple-note.core")
  if not ok then
    notify(("core unavailable: %s"):format(core), vim.log.levels.ERROR)
    return
  end

  local ok2, err = pcall(core.run, sub, args, opts)
  if not ok2 then
    notify(tostring(err), vim.log.levels.ERROR)
  end
end

function M.setup()
  pcall(vim.api.nvim_del_user_command, "Snote")
  vim.api.nvim_create_user_command("Snote", M.dispatch, {
    nargs = "*",
    complete = M.complete,
    desc = "Simple note commands",
  })
end

return M

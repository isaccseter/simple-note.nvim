local date = require("simple-note.date")
local template = require("simple-note.template")
local util = require("simple-note.util")
local vault = require("simple-note.vault")

local M = {}

---@param raw string?
---@return string
local function last_input(raw)
  if not raw or raw == "" then
    return ""
  end
  local parts = vim.split(raw, "/", { plain = true })
  return util.sanitize(parts[#parts] or "")
end

---@param args string[]
---@param today boolean
---@return integer?, string?, string?
local function parse(args, today)
  if today then
    if #args > 2 then
      return nil, nil, "today takes at most one input"
    end
    return 0, last_input(args[2]), nil
  end
  local n = -1
  if args[2] then
    n = tonumber(args[2])
    if not n or n ~= math.floor(n) then
      return nil, nil, "daily n must be an integer"
    end
  end
  if #args > 3 then
    return nil, nil, "daily takes at most n and input"
  end
  return n, last_input(args[3]), nil
end

---@param args string[]
---@param today boolean
function M.run(args, today)
  local n, input, err = parse(args, today)
  if err then
    util.notify(err)
    return
  end

  local cfg = require("simple-note").config
  local root, root_err = vault.ensure()
  if not root then
    util.notify(tostring(root_err))
    return
  end
  local tpl_path, tpl_err = vault.daily_template()
  if not tpl_path then
    util.notify(tostring(tpl_err))
    return
  end
  local lines = util.read_lines(tpl_path)
  local parsed, parse_err = template.parse(lines)
  if not parsed then
    util.notify(tostring(parse_err))
    return
  end

  local target = date.target_date(n, cfg.date_format)
  local ctx = { input = input, daily_date = target }
  local _, basename = template.render_parsed(parsed, ctx, nil)

  local filename
  if basename then
    local rendered = template.render(basename, ctx, true)
    rendered = util.sanitize(rendered)
    filename = rendered ~= "" and rendered or "Untitle"
  else
    filename = util.sanitize(target)
  end
  if util.hidden_name(filename) then
    util.notify("daily filename cannot start with `.`")
    return
  end

  local path = util.join(root, cfg.daily_dir .. "/" .. filename .. ".md")
  if util.file_exists(path) then
    vault.cd_root()
    vault.open_tab(path)
    return
  end

  local title = util.stem(path)
  local out = template.render_parsed(parsed, ctx, title)
  if not out then
    util.notify("cannot render daily template")
    return
  end
  local ok, write_err = util.write_lines(path, out)
  if not ok then
    util.notify(tostring(write_err))
    return
  end
  vault.cd_root()
  vault.open_tab(path)
end

return M

local template = require("simple-note.template")
local util = require("simple-note.util")
local vault = require("simple-note.vault")

local M = {}

---@param name string
---@param title string?
---@return string|nil, string?
local function resolve_template(name, title)
  local root, root_err = vault.ensure()
  if not root then
    return nil, root_err
  end
  local path, err
  if name == "new" then
    path, err = vault.defaultnew_template()
  else
    path, err = vault.resolve_template(title)
  end
  if not path then
    return nil, err
  end
  return path, nil
end

---@param title string?
---@return string|nil, string|nil, string?
local function split_path(title)
  if title and title ~= "" then
    local ok, err = require("simple-note.config").validate_relative(title)
    if not ok then
      return nil, nil, "title: " .. tostring(err)
    end
  end
  local root = vault.root()
  local dir, base = util.split_title(root, title or "")
  return dir, base, nil
end

---@param args string[]
---@param use_template boolean
function M.run(args, use_template)
  local template_name
  local title
  if use_template then
    template_name = args[2]
    title = args[3]
    if not template_name then
      util.notify("ntemplate requires a template")
      return
    end
    if #args > 3 then
      util.notify("ntemplate takes template and optional title")
      return
    end
  else
    title = args[2]
    if #args > 2 then
      util.notify("new takes at most one title")
      return
    end
  end

  local tpl_path, tpl_err =
    resolve_template(use_template and "ntemplate" or "new", use_template and template_name or nil)
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

  local dir, base, path_err = split_path(title)
  if not dir then
    util.notify(tostring(path_err))
    return
  end
  local input = base or ""
  local ctx = { input = input }
  local _, basename = template.render_parsed(parsed, ctx, nil)

  local filename
  if basename then
    local rendered = template.render(basename, ctx, true)
    rendered = util.sanitize(rendered)
    filename = rendered ~= "" and rendered or "Untitle"
  else
    filename = base ~= "" and base or "Untitle"
  end
  if util.hidden_name(filename) then
    util.notify("filename cannot start with `.`")
    return
  end

  local raw_path = util.join(dir, filename .. ".md")
  local path = util.dedupe(raw_path)
  local title_stem = util.stem(path)
  local out = template.render_parsed(parsed, ctx, title_stem)
  if not out then
    util.notify("cannot render template")
    return
  end
  local ok, write_err = util.write_lines(path, out)
  if not ok then
    util.notify(tostring(write_err))
    return
  end

  vault.cd_root()
  vault.open_tab(path)
  local line_count = vim.api.nvim_buf_line_count(0)
  vim.api.nvim_win_set_cursor(0, { math.max(line_count, 1), 0 })
end

return M

local template = require("simple-note.template")
local toml = require("simple-note.toml")
local util = require("simple-note.util")
local vault = require("simple-note.vault")

local M = {}

---@param line string?
---@return boolean
local function blank(line)
  return vim.trim(line or "") == ""
end

---@param lines string[]
---@param ctx table
---@return string[]
local function render_lines(lines, ctx)
  local out = {}
  for _, line in ipairs(lines) do
    out[#out + 1] = template.render(line, ctx, false)
  end
  return out
end

---@param args string[]
function M.run(args)
  if #args > 2 then
    util.notify("template takes one template argument")
    return
  end
  local name = args[2]
  if not name then
    util.notify("template requires a template")
    return
  end

  local path = vim.api.nvim_buf_get_name(0)
  if path == "" or not vault.is_in_vault(path) then
    util.notify("template is only available inside the vault")
    return
  end
  local root, root_err = vault.ensure()
  if not root then
    util.notify(tostring(root_err))
    return
  end

  local cfg = require("simple-note").config
  local cur_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  if vim.trim(cur_lines[1] or "") == "---" then
    util.notify("YAML frontmatter is not supported")
    return
  end
  local cur, cur_err = template.parse(cur_lines)
  if not cur then
    util.notify(tostring(cur_err))
    return
  end

  local tpl_path, tpl_err = vault.resolve_template(name)
  if not tpl_path then
    util.notify(tostring(tpl_err))
    return
  end
  local tpl_lines = util.read_lines(tpl_path)
  if vim.trim(tpl_lines[1] or "") == "---" then
    util.notify("YAML frontmatter is not supported")
    return
  end
  local tpl, parse_err = template.parse(tpl_lines)
  if not tpl then
    util.notify(tostring(parse_err))
    return
  end

  local _, tpl_header = template.extract_basename(tpl.header)
  local ctx = { title = util.stem(path) }
  local tpl_header_rendered = render_lines(tpl_header, ctx)
  local tpl_body_rendered = render_lines(tpl.body, ctx)
  local tpl_parsed, tpl_toml_err = toml.parse(tpl_header_rendered)
  if not tpl_parsed or tpl_toml_err then
    util.notify(tostring(tpl_toml_err or "cannot parse template frontmatter"))
    return
  end
  local tpl_entries = toml.unique(tpl_parsed)

  local substitute = {}
  for _, key in ipairs(cfg.substitute_key or {}) do
    substitute[key] = true
  end

  local lines

  if not cur.has_frontmatter then
    if tpl.has_frontmatter then
      local block = { "+++" }
      for _, entry in ipairs(tpl_entries) do
        if not entry.complex then
          toml.add_key(block, #block + 1, entry.key, entry.raw)
        end
      end
      block[#block + 1] = "+++"
      if #cur_lines > 0 then
        block[#block + 1] = ""
      end
      for _, line in ipairs(cur_lines) do
        block[#block + 1] = line
      end
      lines = block
    else
      lines = vim.deepcopy(cur_lines)
    end
  else
    local header = vim.deepcopy(cur.header)
    local parsed, parsed_err = toml.parse(header)
    if not parsed or parsed_err then
      util.notify(tostring(parsed_err or "cannot parse current frontmatter"))
      return
    end

    for _, entry in ipairs(tpl_entries) do
      if not entry.complex then
        local current = parsed.by_key[entry.key]
        if not current then
          toml.add_key(header, toml.top_level_insert_line(header), entry.key, entry.raw)
        elseif not current.complex then
          if substitute[entry.key] then
            toml.replace_value(header, current, entry.raw)
          elseif toml.is_boolean(current.raw) or toml.is_boolean(entry.raw) then
            toml.replace_value(header, current, entry.raw)
          elseif current.type == "array" and entry.type == "array" then
            toml.append_array(header, current, entry.elements)
          elseif current.type == "array" then
            toml.append_array(header, current, { entry.raw })
          elseif entry.type == "array" then
            toml.convert_to_array(header, current, entry.elements)
          else
            toml.convert_to_array(header, current, { entry.raw })
          end
        end
      end

      parsed, parsed_err = toml.parse(header)
      if not parsed or parsed_err then
        util.notify(tostring(parsed_err or "cannot parse frontmatter after merge"))
        return
      end
    end

    lines = { "+++" }
    for _, line in ipairs(header) do
      lines[#lines + 1] = line
    end
    lines[#lines + 1] = "+++"
    for _, line in ipairs(cur.body) do
      lines[#lines + 1] = line
    end
  end

  if #lines > 0 and not blank(lines[#lines]) then
    lines[#lines + 1] = ""
  end
  for _, line in ipairs(tpl_body_rendered) do
    lines[#lines + 1] = line
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

return M

local M = {}

M.default_daily = {
  "+++",
  'type = "daily"',
  "created = {{date}}",
  'basename = "{{daily_date}}{{hinput}}"',
  "+++",
  "",
  "## What did I do today?",
  "",
}

M.default_new = {
  "+++",
  "created = {{date}}",
  "+++",
  "",
  "",
}

---@param raw string
---@return string
function M.parse_string(raw)
  local s = vim.trim(raw)
  if s:sub(1, 1) == '"' and s:sub(-1) == '"' then
    s = s:sub(2, -2)
    s = s:gsub('\\"', '"'):gsub("\\\\", "\\")
    return s
  end
  if s:sub(1, 1) == "'" and s:sub(-1) == "'" then
    return s:sub(2, -2)
  end
  return s
end

---@param line string
---@return string
function M.strip_comment(line)
  local quote
  local escaped = false
  for i = 1, #line do
    local c = line:sub(i, i)
    if escaped then
      escaped = false
    elseif c == "\\" and quote == '"' then
      escaped = true
    elseif quote then
      if c == quote then
        quote = nil
      end
    elseif c == '"' or c == "'" then
      quote = c
    elseif c == "#" then
      return line:sub(1, i - 1)
    end
  end
  return line
end

---@param lines string[]
---@return table|nil, string?
function M.parse(lines)
  if #lines == 0 then
    return { has_frontmatter = false, header = {}, body = {} }
  end
  local first = (lines[1] or ""):gsub("\r$", "")
  if first == "---" then
    return nil, "YAML frontmatter is not supported"
  end
  if first ~= "+++" then
    return { has_frontmatter = false, header = {}, body = lines }
  end

  local close
  for i = 2, #lines do
    if (lines[i] or ""):gsub("\r$", "") == "+++" then
      close = i
      break
    end
  end
  if not close then
    return nil, "unterminated frontmatter (missing closing +++)"
  end

  local header = {}
  for i = 2, close - 1 do
    header[#header + 1] = lines[i]
  end
  local body = {}
  for i = close + 1, #lines do
    body[#body + 1] = lines[i]
  end
  return { has_frontmatter = true, header = header, body = body, close = close }
end

---@param header string[]
---@return string?, string[]
function M.extract_basename(header)
  local value
  local out = {}
  for _, line in ipairs(header) do
    local raw = line:match("^%s*basename%s*=%s*(.+)$")
    if raw then
      value = M.parse_string(M.strip_comment(raw))
    else
      out[#out + 1] = line
    end
  end
  return value, out
end

---@param text string
---@param ctx table
---@param allow_input boolean
---@return string
function M.render(text, ctx, allow_input)
  local sn = require("simple-note")
  local cfg = sn.config
  local input = ctx.input or ""
  local hinput = input ~= "" and ("-" .. input) or ""
  local uinput = input ~= "" and ("_" .. input) or ""

  return (
    text:gsub("{{([^{}]+)}}", function(expr)
      local name, arg = expr:match("^([%w_]+):?(.*)$")
      if not name then
        return "{{" .. expr .. "}}"
      end
      if name == "input" or name == "hinput" or name == "uinput" then
        if not allow_input then
          return "{{" .. expr .. "}}"
        end
        if name == "input" then
          return input
        end
        if name == "hinput" then
          return hinput
        end
        return uinput
      end
      if name == "title" then
        return ctx.title or ("{{" .. expr .. "}}")
      end
      if name == "daily_date" then
        if arg ~= "" or not ctx.daily_date then
          return "{{" .. expr .. "}}"
        end
        return ctx.daily_date
      end
      if name == "timestamp" then
        if arg ~= "" then
          return "{{" .. expr .. "}}"
        end
        return require("simple-note.date").format(cfg.timestamp_format)
      end
      if name == "date" then
        return require("simple-note.date").format(arg ~= "" and arg or cfg.date_format)
      end
      if name == "time" then
        return require("simple-note.date").format(arg ~= "" and arg or cfg.time_format)
      end
      return "{{" .. expr .. "}}"
    end)
  )
end

---@param lines string[]
---@param ctx table
---@param fallback_basename string?
---@return string[]|nil, string?, string?
function M.render_template(lines, ctx, fallback_basename)
  local parsed, err = M.parse(lines)
  if not parsed then
    return nil, nil, err
  end

  local basename, header = M.extract_basename(parsed.header)
  basename = basename or fallback_basename
  local out = {}

  if parsed.has_frontmatter then
    out[#out + 1] = "+++"
    for _, line in ipairs(header) do
      out[#out + 1] = M.render(line, ctx, false)
    end
    out[#out + 1] = "+++"
  end
  for _, line in ipairs(parsed.body) do
    out[#out + 1] = M.render(line, ctx, false)
  end
  return out, basename, nil
end

---@param parsed table
---@param ctx table
---@param title string?
---@return string[]|nil, string?
function M.render_parsed(parsed, ctx, title)
  local basename, header = M.extract_basename(parsed.header)
  ctx.title = title
  local out = {}
  if parsed.has_frontmatter then
    out[#out + 1] = "+++"
    for _, line in ipairs(header) do
      out[#out + 1] = M.render(line, ctx, false)
    end
    out[#out + 1] = "+++"
  end
  for _, line in ipairs(parsed.body) do
    out[#out + 1] = M.render(line, ctx, false)
  end
  return out, basename
end

return M

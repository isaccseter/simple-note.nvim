local M = {}

---@param s string
---@return string
local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

---@param s string
---@return string
function M.strip_comment(s)
  local quote
  local escaped = false
  for i = 1, #s do
    local c = s:sub(i, i)
    if escaped then
      escaped = false
    elseif quote and quote == '"' and c == "\\" then
      escaped = true
    elseif quote then
      if c == quote then
        quote = nil
      end
    elseif c == '"' or c == "'" then
      quote = c
    elseif c == "#" then
      return s:sub(1, i - 1)
    end
  end
  return s
end

---@param raw string
---@return string
function M.scalar_type(raw)
  local s = trim(raw)
  if s:match('^".*"$') or s:match("^'.*'$") then
    return "string"
  end
  if s == "true" or s == "false" then
    return "boolean"
  end
  if s:match("^[+-]?%d") then
    return "number"
  end
  if s:match("^%d%d%d%d%-%d%d%-%d%d") then
    return "date"
  end
  return "other"
end

---@param raw string
---@return boolean
function M.is_boolean(raw)
  local s = trim(raw)
  return s == "true" or s == "false"
end

---@param content string
---@return string[], boolean
local function parse_elements(content)
  local elements = {}
  local complex = false
  local buf = {}
  local depth = 0
  local quote
  local comment = false
  local i = 1

  local function flush()
    local raw = trim(table.concat(buf))
    buf = {}
    if raw ~= "" then
      if raw:sub(1, 1) == "[" or raw:sub(1, 1) == "{" or raw:sub(1, 3) == '"""' or raw:sub(1, 3) == "'''" then
        complex = true
      end
      elements[#elements + 1] = raw
    end
  end

  while i <= #content do
    local c = content:sub(i, i)
    if comment then
      if c == "\n" then
        comment = false
      end
    elseif quote then
      buf[#buf + 1] = c
      if quote == '"' and c == "\\" then
        buf[#buf + 1] = content:sub(i + 1, i + 1)
        i = i + 1
      elseif c == quote then
        quote = nil
      end
    elseif c == "#" then
      comment = true
    elseif c == '"' or c == "'" then
      quote = c
      buf[#buf + 1] = c
    elseif c == "[" or c == "{" then
      depth = depth + 1
      complex = true
      buf[#buf + 1] = c
    elseif c == "]" or c == "}" then
      depth = depth - 1
      buf[#buf + 1] = c
    elseif c == "," and depth == 0 then
      flush()
    else
      buf[#buf + 1] = c
    end
    i = i + 1
  end
  flush()
  return elements, complex
end

---@param header string[]
---@param start_line integer
---@param start_col integer
---@return table?, string?
local function parse_array(header, start_line, start_col)
  local depth = 0
  local quote
  local comment = false
  local close_line, close_col

  for li = start_line, #header do
    local line = header[li]
    local col = li == start_line and start_col or 1
    comment = false
    local triple = line:find('"""', col, true) or line:find("'''", col, true)
    if triple then
      return nil, "multi-line string in array is not supported"
    end
    while col <= #line do
      local c = line:sub(col, col)
      if comment then
        break
      elseif quote then
        if quote == '"' and c == "\\" then
          col = col + 2
        elseif c == quote then
          quote = nil
          col = col + 1
        else
          col = col + 1
        end
      elseif c == "#" then
        comment = true
        break
      elseif c == '"' or c == "'" then
        quote = c
        col = col + 1
      elseif c == "[" then
        depth = depth + 1
        if depth > 1 then
          return nil, "nested array is not supported"
        end
        col = col + 1
      elseif c == "]" then
        depth = depth - 1
        if depth == 0 then
          close_line, close_col = li, col
          break
        end
        col = col + 1
      elseif c == "{" then
        return nil, "inline table in array is not supported"
      else
        col = col + 1
      end
    end
    if close_line then
      break
    end
  end

  if not close_line then
    return nil, "unterminated array"
  end

  local raw
  if close_line == start_line then
    raw = header[start_line]:sub(start_col, close_col)
  else
    local parts = { header[start_line]:sub(start_col) }
    for li = start_line + 1, close_line - 1 do
      parts[#parts + 1] = header[li]
    end
    parts[#parts + 1] = header[close_line]:sub(1, close_col)
    raw = table.concat(parts, "\n")
  end
  local content = raw:sub(2, -2)
  local elements, complex = parse_elements(content)

  local last_line = start_line
  for li = close_line, start_line, -1 do
    local l = trim(header[li] or "")
    if l ~= "" and l:sub(1, 1) ~= "#" and l ~= "]" then
      last_line = li
      break
    end
  end

  return {
    type = "array",
    raw = raw,
    open_line = start_line,
    open_col = start_col,
    close_line = close_line,
    close_col = close_col,
    multiline = close_line > start_line,
    elements = elements,
    complex = complex,
    last_element_line = last_line,
  }
end

---@param header string[]
---@return table, string?
function M.parse(header)
  local entries = {}
  local by_key = {}
  local in_table = false
  local skip_quote
  local skip_brace = 0
  local i = 1

  while i <= #header do
    local line = header[i]
    local t = trim(line)
    if skip_quote then
      if line:find(skip_quote, 1, true) then
        skip_quote = nil
      end
      i = i + 1
    elseif skip_brace > 0 then
      for c in line:gmatch(".") do
        if c == "{" then
          skip_brace = skip_brace + 1
        elseif c == "}" then
          skip_brace = skip_brace - 1
        end
      end
      i = i + 1
    elseif t == "" or t:sub(1, 1) == "#" then
      i = i + 1
    elseif t:sub(1, 1) == "[" then
      in_table = true
      i = i + 1
    elseif in_table then
      i = i + 1
    else
      local key = line:match("^%s*([%w_-]+)%s*=")
      if key then
        local eq = line:find("=", 1, true)
        local vs = eq + 1
        while line:sub(vs, vs):match("%s") do
          vs = vs + 1
        end
        local rest = line:sub(vs)
        local entry = { key = key, line = i, value_start_col = vs }
        local valid = true

        if rest:sub(1, 3) == '"""' or rest:sub(1, 3) == "'''" then
          entry.complex = true
          skip_quote = rest:sub(1, 3)
        elseif rest:sub(1, 1) == "{" then
          entry.complex = true
          for c in rest:gmatch(".") do
            if c == "{" then
              skip_brace = skip_brace + 1
            elseif c == "}" then
              skip_brace = skip_brace - 1
            end
          end
          if skip_brace < 0 then
            skip_brace = 0
          end
        elseif rest:sub(1, 1) == "[" then
          local arr, err = parse_array(header, i, vs)
          if not arr then
            entry.complex = true
            if err and err:match("^unterminated") then
              return entries, err
            end
          else
            for k, v in pairs(arr) do
              entry[k] = v
            end
            entry.value_end_col = arr.close_col
          end
        else
          local raw = trim(M.strip_comment(rest))
          if raw == "" then
            valid = false
          else
            entry.raw = raw
            entry.type = M.scalar_type(raw)
            entry.value_end_col = vs + #raw - 1
          end
        end

        if valid then
          entries[#entries + 1] = entry
          by_key[key] = entry
        end
      end
      i = i + 1
    end
  end
  return { entries = entries, by_key = by_key }
end

---@param lines string[]
---@param entry table
---@param raw string
function M.replace_value(lines, entry, raw)
  local line = lines[entry.line]
  lines[entry.line] = line:sub(1, entry.value_start_col - 1) .. raw .. line:sub(entry.value_end_col + 1)
end

---@param lines string[]
---@param entry table
---@param raws string[]
function M.append_array(lines, entry, raws)
  if #raws == 0 then
    return
  end
  if not entry.multiline then
    local line = lines[entry.open_line]
    local prefix = line:sub(1, entry.close_col - 1)
    local suffix = line:sub(entry.close_col)
    local content = trim(prefix:sub(entry.open_col + 1))
    local needs_comma = content ~= "" and not content:match(",%s*$")
    local insert = (needs_comma and "," or "") .. table.concat(raws, ",") .. ","
    lines[entry.open_line] = prefix .. insert .. suffix
    return
  end

  local close_line = entry.close_line
  if entry.last_element_line == close_line then
    local line = lines[close_line]
    local prefix = line:sub(1, entry.close_col - 1)
    local content = trim(prefix)
    local needs_comma = content ~= "" and not content:match(",%s*$")
    local insert = (needs_comma and "," or "") .. table.concat(raws, ",") .. ","
    lines[close_line] = prefix .. insert .. line:sub(entry.close_col)
    return
  end

  local close_indent = lines[close_line]:match("^%s*") or ""
  local last_line = entry.last_element_line or (close_line - 1)
  local indent = lines[last_line] and lines[last_line]:match("^%s*") or ""
  if indent == "" then
    indent = close_indent .. "  "
  end

  if last_line ~= close_line then
    local l = lines[last_line] or ""
    local code = l:match("^(.-)%s*#") or l
    if not code:match(",%s*$") then
      local replaced = l:gsub("^(.-)(%s*#.*)$", "%1,%2")
      if replaced == l then
        replaced = l .. ","
      end
      lines[last_line] = replaced
    end
  end

  local new_lines = {}
  for _, raw in ipairs(raws) do
    new_lines[#new_lines + 1] = indent .. raw .. ","
  end
  for offset, l in ipairs(new_lines) do
    table.insert(lines, close_line + offset - 1, l)
  end
end

---@param lines string[]
---@param entry table
---@param raws string[]
function M.convert_to_array(lines, entry, raws)
  local parts = { entry.raw }
  for _, raw in ipairs(raws) do
    parts[#parts + 1] = raw
  end
  M.replace_value(lines, entry, "[" .. table.concat(parts, ",") .. ",]")
end

---@param lines string[]
---@return integer
function M.top_level_insert_line(lines)
  for i, line in ipairs(lines) do
    if trim(line):sub(1, 1) == "[" then
      return i
    end
  end
  return #lines + 1
end

---@param lines string[]
---@param close_line integer
---@param key string
---@param raw string
function M.add_key(lines, close_line, key, raw)
  local parts = vim.split(raw, "\n", { plain = true })
  parts[1] = key .. " = " .. parts[1]
  for offset, l in ipairs(parts) do
    table.insert(lines, close_line + offset - 1, l)
  end
end

---@param parsed table
---@return table[]
function M.unique(parsed)
  local out = {}
  for _, entry in ipairs(parsed.entries) do
    if parsed.by_key[entry.key] == entry then
      out[#out + 1] = entry
    end
  end
  return out
end

return M

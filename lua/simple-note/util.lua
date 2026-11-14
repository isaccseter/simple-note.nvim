local M = {}

---@param msg string
---@param level integer?
function M.notify(msg, level)
  vim.notify("Snote: " .. msg, level or vim.log.levels.WARN)
end

---@param path string
---@return boolean
function M.exists(path)
  return vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1
end

---@param path string
---@return boolean
function M.file_exists(path)
  return vim.fn.filereadable(path) == 1
end

---@param path string
---@return string[]
function M.read_lines(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return {}
  end
  return lines
end

---@param path string
---@param lines string[]
---@return boolean, string?
function M.write_lines(path, lines)
  local dir = vim.fn.fnamemodify(path, ":h")
  if dir ~= "" and dir ~= "." then
    local ok = pcall(vim.fn.mkdir, dir, "p")
    if not ok then
      return false, "cannot create directory: " .. dir
    end
  end
  local ok, err = pcall(vim.fn.writefile, lines, path)
  if not ok then
    return false, tostring(err)
  end
  return true
end

---@param root string
---@param rel string?
---@return string
function M.join(root, rel)
  if not rel or rel == "" then
    return root
  end
  return root .. "/" .. rel:gsub("^/+", "")
end

---@param path string
---@return string
function M.escape(path)
  return vim.fn.fnameescape(path)
end

---@param path string
function M.cd(path)
  vim.cmd("cd " .. M.escape(path))
end

---@param path string
function M.open_tab(path)
  vim.cmd("tabnew")
  vim.cmd("edit " .. M.escape(path))
end

---@param path string
---@return string
function M.stem(path)
  local name = vim.fn.fnamemodify(path, ":t")
  return name:gsub("%.md$", "")
end

---@param s string
---@return string
function M.sanitize(s)
  -- 保留 UTF-8 字节；只替换 ASCII 空白和标点。
  return (
    s:gsub("[%s%p]", function(c)
      if c:match("[-_.%(%)%[%]]") then
        return c
      end
      return "-"
    end)
  )
end

---@param s string
---@return boolean
function M.hidden_name(s)
  return s:sub(1, 1) == "."
end

---@param root string
---@param title string
---@return string dir, string base
function M.split_title(root, title)
  local dir, base = title:match("^(.*)/([^/]*)$")
  if not dir then
    dir, base = "", title
  end
  local parts = {}
  for part in dir:gmatch("[^/]+") do
    parts[#parts + 1] = M.sanitize(part)
  end
  return M.join(root, table.concat(parts, "/")), M.sanitize(base)
end

---@param path string
---@return string
function M.dedupe(path)
  if not M.exists(path) then
    return path
  end
  local base = path:gsub("%.md$", "")
  local n = 1
  while true do
    local candidate = ("%s-%d.md"):format(base, n)
    if not M.exists(candidate) then
      return candidate
    end
    n = n + 1
  end
end

---@param lines string[]
---@return string
function M.join_lines(lines)
  return table.concat(lines, "\n")
end

return M

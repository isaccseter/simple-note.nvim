local M = {}

M.defaults = {
  vault = nil,
  homepage = nil,
  welcome = true,
  welcome_action = "today",
  welcome_key = "v",
  welcome_label = "Open My Vault",
  welcome_icon = "󰉋",
  notice_missing_welcome = true,
  daily_dir = "Daily",
  templates_dir = "Templates",
  daily_template = "daily.md",
  defaultnew_template = "default-new.md",
  frontmatter_extensions = { "md" },
  substitute_key = { "status", "created", "type" },
  date_format = "YYYY-MM-DD",
  time_format = "HH:mm",
  timestamp_format = "YYYY-MM-DD HH:mm",
}

---@param opts table?
---@return table
function M.merge(opts)
  return vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

---@param path string?
---@return boolean
function M.is_absolute(path)
  if type(path) ~= "string" or path == "" then
    return false
  end
  return path:sub(1, 1) == "/" or path:match("^%a:[/\\]") ~= nil or path:match("^\\\\") ~= nil
end

---@param path string?
---@return boolean
function M.has_parent(path)
  if type(path) ~= "string" then
    return false
  end
  for part in path:gmatch("[^/\\]+") do
    if part == ".." then
      return true
    end
  end
  return false
end

---@param path string?
---@return boolean, string?
function M.validate_relative(path)
  if type(path) ~= "string" or path == "" then
    return false, "path is empty"
  end
  if M.is_absolute(path) then
    return false, "absolute path is not allowed"
  end
  if M.has_parent(path) then
    return false, "`..` is not allowed"
  end
  return true
end

return M

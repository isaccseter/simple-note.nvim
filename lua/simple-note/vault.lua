local util = require("simple-note.util")
local template = require("simple-note.template")

local M = {}

---@return string
function M.root()
  local cfg = require("simple-note").config
  local vault = cfg.vault
  if not vault or vault == "" then
    vault = "~/Vault"
  end
  local path = vim.fn.fnamemodify(vim.fn.expand(vault), ":p")
  return (path:gsub("/+$", ""))
end

---@param rel string?
---@return string|nil, string?
function M.relative_path(rel)
  if rel == nil or rel == "" then
    return nil, "path is empty"
  end
  local ok, err = require("simple-note.config").validate_relative(rel)
  if not ok then
    return nil, err
  end
  return rel
end

---@return string|nil, string?
function M.ensure()
  local cfg = require("simple-note").config
  local root = M.root()
  local ok = pcall(vim.fn.mkdir, root, "p")
  if not ok then
    return nil, "cannot create vault: " .. root
  end

  local dirs = {}
  for _, name in ipairs({ "daily_dir", "templates_dir" }) do
    local rel, rel_err = M.relative_path(cfg[name])
    if not rel then
      return nil, name .. ": " .. tostring(rel_err)
    end
    local path = util.join(root, rel)
    local ok2 = pcall(vim.fn.mkdir, path, "p")
    if not ok2 then
      return nil, "cannot create " .. name .. ": " .. path
    end
    dirs[name] = path
  end

  if cfg.daily_template == "daily.md" then
    local daily = util.join(dirs.templates_dir, cfg.daily_template)
    if not util.file_exists(daily) then
      local ok3, err3 = util.write_lines(daily, template.default_daily)
      if not ok3 then
        return nil, err3
      end
    end
  end
  return root, nil
end

---@return string|nil, string?
function M.daily_template()
  local cfg = require("simple-note").config
  local root, err = M.ensure()
  if not root then
    return nil, err
  end
  local rel, rel_err = M.relative_path(cfg.daily_template)
  if not rel then
    return nil, "daily_template: " .. tostring(rel_err)
  end
  local path = util.join(root, cfg.templates_dir .. "/" .. rel)
  if not util.file_exists(path) then
    if cfg.daily_template == "daily.md" then
      local ok, write_err = util.write_lines(path, template.default_daily)
      if not ok then
        return nil, write_err
      end
    else
      return nil, "daily template not found: " .. path
    end
  end
  return path, nil
end

---@return string|nil, string?
function M.defaultnew_template()
  local cfg = require("simple-note").config
  local root, err = M.ensure()
  if not root then
    return nil, err
  end
  local rel, rel_err = M.relative_path(cfg.defaultnew_template)
  if not rel then
    return nil, "defaultnew_template: " .. tostring(rel_err)
  end
  local path = util.join(root, cfg.templates_dir .. "/" .. rel)
  if not util.file_exists(path) then
    local ok, write_err = util.write_lines(path, template.default_new)
    if not ok then
      return nil, write_err
    end
  end
  return path, nil
end

---@param rel string
---@return string|nil, string?
function M.path(rel)
  local root = M.root()
  local ok, err = M.relative_path(rel)
  if not ok then
    return nil, err
  end
  return util.join(root, rel), nil
end

---@return string|nil, string?
function M.homepage_path()
  local cfg = require("simple-note").config
  if not cfg.homepage or cfg.homepage == "" then
    return nil, "homepage is not configured"
  end
  local root = M.root()
  local ok, err = M.relative_path(cfg.homepage)
  if not ok then
    return nil, err
  end
  local path = util.join(root, cfg.homepage)
  if not util.file_exists(path) then
    return nil, "homepage not found: " .. path
  end
  return path, nil
end

function M.cd_root()
  util.cd(M.root())
end

---@param path string
function M.open_tab(path)
  util.open_tab(path)
end

---@param name string?
---@return string|nil, string?
function M.resolve_template(name)
  if not name or name == "" then
    return nil, "template is required"
  end
  local cfg = require("simple-note").config
  local ok, err = require("simple-note.config").validate_relative(name)
  if not ok then
    return nil, "template: " .. tostring(err)
  end
  if not name:match("%.md$") then
    name = name .. ".md"
  end
  local path = util.join(M.root(), cfg.templates_dir .. "/" .. name)
  if not util.file_exists(path) then
    return nil, "template not found: " .. path
  end
  return path, nil
end

---@param path string
---@return boolean
function M.is_in_vault(path)
  local root = M.root()
  local normalized = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
  return normalized:sub(1, #root + 1) == root .. "/"
end

return M

local M = {}

M._added = false

---@param cfg table
---@return table
function M.entry(cfg)
  local action = cfg.welcome_action
  if action ~= "last" and action ~= "today" and action ~= "homepage" then
    action = "today"
  end
  local sub = action == "last" and "vault" or action
  return {
    key = cfg.welcome_key,
    desc = cfg.welcome_label .. "  ",
    icon = cfg.welcome_icon,
    action = function()
      vim.cmd("Snote " .. sub)
    end,
  }
end

---@param cfg table
local function attach(cfg)
  if M._added then
    return
  end
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    if cfg.notice_missing_welcome then
      vim.notify("Snote: snacks.nvim not found; welcome entry disabled", vim.log.levels.WARN)
    end
    return
  end

  snacks.config = snacks.config or {}
  local dashboard = snacks.config.dashboard
  if type(dashboard) ~= "table" then
    dashboard = {}
    snacks.config.dashboard = dashboard
  end
  local preset = dashboard.preset
  if type(preset) ~= "table" then
    preset = {}
    dashboard.preset = preset
  end
  local keys = preset.keys
  if type(keys) ~= "table" then
    keys = {}
    preset.keys = keys
  end
  for _, item in ipairs(keys) do
    if item.key == cfg.welcome_key then
      M._added = true
      return
    end
  end
  keys[#keys + 1] = M.entry(cfg)
  M._added = true
end

---@param cfg table
function M.setup(cfg)
  if not cfg.welcome then
    return
  end
  if M._added then
    return
  end
  if package.loaded["snacks"] then
    attach(cfg)
    return
  end
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      attach(cfg)
    end,
  })
end

return M

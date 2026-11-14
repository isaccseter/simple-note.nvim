local M = {}

local tokens = {
  YYYY = "%Y",
  YY = "%y",
  MM = "%m",
  DD = "%d",
  HH = "%H",
  mm = "%M",
  ss = "%S",
}

---@param fmt string
---@param ts integer?
---@return string
function M.format(fmt, ts)
  local now = ts or os.time()
  local out = fmt
  for _, tok in ipairs({ "YYYY", "YY", "MM", "DD", "HH", "mm", "ss" }) do
    out = out:gsub(tok, os.date(tokens[tok], now))
  end
  return out
end

---@param days integer
---@return string
function M.target_date(days, fmt)
  local ts = os.time() + days * 86400
  return M.format(fmt or "%Y-%m-%d", ts)
end

return M

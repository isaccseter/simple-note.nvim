local util = require("simple-note.util")

local M = {}

local handlers = {
  frontmatter = function(args)
    require("simple-note.core.frontmatter").run(args)
  end,
  vault = function(args)
    require("simple-note.core.vault").run(args)
  end,
  homepage = function(args)
    require("simple-note.core.homepage").run(args)
  end,
  daily = function(args)
    require("simple-note.core.daily").run(args, false)
  end,
  today = function(args)
    require("simple-note.core.daily").run(args, true)
  end,
  new = function(args)
    require("simple-note.core.new").run(args, false)
  end,
  ntemplate = function(args)
    require("simple-note.core.new").run(args, true)
  end,
  template = function(args)
    require("simple-note.core.template").run(args)
  end,
  reload = function(_)
    require("simple-note").reload()
  end,
}

---@param sub string
---@param args string[]
---@param _ table
function M.run(sub, args, _)
  local handler = handlers[sub]
  if not handler then
    util.notify(("unknown subcommand: %s"):format(sub), vim.log.levels.ERROR)
    return
  end
  handler(args)
end

pcall(function()
  require("simple-note.templates").list()
end)

return M

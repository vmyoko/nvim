-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "bearded-arc",

  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
  },
  integrations = { "dap" },
}

M.nvdash = {
  load_on_startup = false,
}

M.ui = {
  tabufline = {
    enabled = true,
    lazyload = false,
    order = { "treeOffset", "buffers", "tabs", "btns" },
  },

  cmp = {
    style = "flat_light",
    icons_left = true,
  },
}

M.lsp = {
  signature = false,
}

return M

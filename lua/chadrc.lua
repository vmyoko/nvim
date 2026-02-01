-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

if vim.g.neovide then
  --1. FONT (Must be installed on WINDOWS, not just WSL)
  vim.o.guifont = "JetBrainsMono Nerd Font:h11" -- h11 is the size. Adjust as needed.

  vim.g.neovide_refresh_rate = 165

  -- 2. FULLSCREEN & MAXIMIZED
  vim.g.neovide_fullscreen = false -- Set to true if you want full immersion
  vim.g.neovide_remember_window_size = true
  -- 3. ANIMATIONS (The smooth feeling)
  vim.g.neovide_cursor_animation_length = 0.13
  vim.g.neovide_scroll_animation_length = 0.3
  vim.g.neovide_hide_mouse_when_typing = true

  -- 4. COPY/PASTE SYNC (Crucial for hybrid feel)
  -- This allows Ctrl+C/V in Windows to talk to your Neovim y/p
  vim.o.clipboard = "unnamedplus"

  vim.g.neovide_transparency = 1
  vim.o.pumblend = 25
  vim.o.winblend = 25
end

M.base46 = {
  theme = "material-deep-ocean",

  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
  },
  integrations = { "dap" },
}

M.nvdash = {
  load_on_startup = true,

  buttons = {
    { txt = "  New File", keys = "nf", cmd = "AdvancedNewFile" },
    { txt = "  New Project", keys = "np", cmd = "AdvancedNewProject" },

    { txt = "" },

    { txt = "  Find File", keys = "ff", cmd = "Telescope find_files" },
    { txt = "  Recent Files", keys = "fo", cmd = "Telescope oldfiles" },
    { txt = "󰩮  Find Word", keys = "fw", cmd = "Telescope live_grep" },
    { txt = "󰆍  Open Terminal", keys = "c", cmd = "terminal" },

    { txt = "" },

    { txt = "  Themes", keys = "th", cmd = "Telescope themes" },
    { txt = "  Mappings", keys = "ch", cmd = "NvCheatsheet" },
  },
}
M.ui = {
  tabufline = {
    enabled = true,
    lazyload = false,
    order = { "treeOffset", "buffers", "tabs", "btns" },
  },
}

return M

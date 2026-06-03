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
  vim.g.neovide_hide_mouse_when_typing = false

  -- 4. VISUAL EFFECTS (Transparency & Blur)
  vim.g.neovide_transparency = 0.93
  vim.g.neovide_window_blurred = true
  
  -- 5. CURSOR PARTICLES (The WOW factor)
  vim.g.neovide_cursor_vfx_mode = "railgun" -- Try "torpedo", "pixiedust", "sonicboom", "ripple", "wireframe"
  vim.g.neovide_cursor_vfx_particle_density = 10.0

  -- 6. WINDOW PADDING (Breathes better)
  vim.g.neovide_padding_top = 10
  vim.g.neovide_padding_bottom = 10
  vim.g.neovide_padding_right = 10
  vim.g.neovide_padding_left = 10

  -- 7. COPY/PASTE SYNC (Crucial for hybrid feel)
  -- This allows Ctrl+C/V in Windows to talk to your Neovim y/p
  vim.o.clipboard = "unnamedplus"

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

return M

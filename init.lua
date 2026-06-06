vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- Dynamically inject common Windows paths so Neovim/Mason can find 7z and gcc without the user needing to modify their environment variables
if vim.fn.has "win32" == 1 then
  local extra_paths = {
    "C:\\Program Files\\7-Zip",
    "C:\\Program Files\\Git\\mingw64\\bin",
    "C:\\Program Files\\Git\\usr\\bin",
  }
  for _, p in ipairs(extra_paths) do
    if vim.fn.isdirectory(p) == 1 and not string.find(vim.env.PATH, p, 1, true) then
      vim.env.PATH = vim.env.PATH .. ";" .. p
    end
  end
end

if vim.g.neovide then
  vim.o.guifont = "JetBrainsMono NF:h11"

  vim.g.neovide_refresh_rate = 165

  vim.g.neovide_fullscreen = false -- Set to true if you want full immersion
  vim.g.neovide_remember_window_size = true
  vim.g.neovide_cursor_animation_length = 0.13
  vim.g.neovide_scroll_animation_length = 0.3
  vim.g.neovide_hide_mouse_when_typing = false

  vim.g.neovide_opacity = 1

  vim.o.clipboard = "unnamedplus"

  vim.o.pumblend = 25
  vim.o.winblend = 25

  vim.g.neovide_floating_shadow = false
end

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

local function start_lazy()
  -- load plugins
  require("lazy").setup({
    {
      "NvChad/NvChad",
      lazy = false,
      branch = "v2.5",
      import = "nvchad.plugins",
    },
    { import = "plugins" },
  }, lazy_config)

  -- load theme
  dofile(vim.g.base46_cache .. "defaults")
  dofile(vim.g.base46_cache .. "statusline")
end

local user_data_path = vim.fn.stdpath "config" .. "/data/user.json"
if vim.fn.filereadable(user_data_path) == 0 then
  require("configs.wizard").start(start_lazy)
else
  start_lazy()
end

require "project_templates"
require("healthcheck").run()

require "options"
require "autocmds"
require "mappings"

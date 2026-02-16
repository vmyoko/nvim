vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

vim.opt.scrolloff = 0

-- Normal, Insert, and Visual mode horizontal scrolling
-- Using <ScrollWheelLeft/Right> which some terminals send for Shift+Scroll
vim.keymap.set({ "n", "i", "v" }, "<ScrollWheelLeft>", "5zh", { silent = true })
vim.keymap.set({ "n", "i", "v" }, "<ScrollWheelRight>", "5zl", { silent = true })

-- Manual fallback if Shift+Scroll specifically reaches Neovim
vim.keymap.set({ "n", "i", "v" }, "<S-ScrollWheelUp>", "5zh", { silent = true })
vim.keymap.set({ "n", "i", "v" }, "<S-ScrollWheelDown>", "5zl", { silent = true })

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

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

require "options"
require "autocmds"

vim.schedule(function()
  require "mappings"
end)

-- lua/init.lua
-- lua/init.lua

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Only open tree if we opened a file (nvim main.cpp)
    if vim.fn.argc() > 0 then
      require("nvim-tree.api").tree.open()
      vim.cmd "wincmd p" -- Focus the file, not the tree
    end
    -- If argc == 0, NvChad opens the Dashboard automatically.
  end,
})

-- Keyboard users
vim.keymap.set("n", "<C-t>", function()
  require("menu").open "default"
end, {})

-- mouse users + nvimtree users!
vim.keymap.set({ "n", "v" }, "<RightMouse>", function()
  require("menu.utils").delete_old_menus()

  vim.cmd.exec '"normal! \\<RightMouse>"'

  -- clicked buf
  local buf = vim.api.nvim_win_get_buf(vim.fn.getmousepos().winid)
  local options = vim.bo[buf].ft == "NvimTree" and "nvimtree" or "default"

  require("menu").open(options, { mouse = true })
end, {})

-- Example: Integrating with a Telescope Picker
-- You would call spawn_template_project(selection[1]) inside your
-- Telescope attach_mappings function.

require "project_templates"

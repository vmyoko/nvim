require "nvchad.options"

local opt = vim.opt

opt.wrap = false
opt.scrolloff = 8          -- Vertical workspace padding
opt.sidescrolloff = 8      -- Horizontal workspace padding
opt.sidescroll = 1

-- Folding settings
opt.foldcolumn = "1"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true

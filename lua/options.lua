require "nvchad.options"

-- add yours here!

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!
--
-- local opt = vim.opt
local opt = vim.opt

opt.wrap = false           -- No "doBarrelR" / "oll();" breaks
opt.scrolloff = 8          -- Vertical workspace padding
opt.sidescrolloff = 8
opt.sidescroll = 1
-- Horizontal workspace padding

-- Folding settings
opt.foldcolumn = '1'
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true



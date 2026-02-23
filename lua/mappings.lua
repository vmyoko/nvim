-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "material-deep-ocean",

	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

-- M.nvdash = { load_on_startup = true }
-- M.ui = {
--       tabufline = {
--          lazyload = false
--      }
-- }

require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

map({ "n", "t" }, "<C-t>", function()
  vim.cmd "FloatermToggle"
end, {})

map("n", "<C-f>", function()
  vim.cmd(":Telescope file_browser")
end)

map("n", "<F2>", function()
  require "nvchad.lsp.renamer"()
end)

map({ "i", "n", "v" }, "<ScrollWheelLeft>", "<zl>")
map({ "i", "n", "v" }, "<ScrollWheelRight", "<zh>")

-- Copy (Visual mode)
map("v", "<C-c>", '"+y', { desc = "Copy to system clipboard" })

-- Paste (Normal and Insert mode)
-- In Insert mode, we use <C-r>+ to pull from the clipboard register
map("n", "<C-v>", '"+p', { desc = "Paste from system clipboard" })
map("i", "<C-v>", "<C-r>+", { desc = "Paste from system clipboard" })

-- Cut (Visual mode)
map("v", "<C-x>", '"+d', { desc = "Cut to system clipboard" })

-- Undo / Redo
map("n", "<C-z>", "u", { desc = "Undo" })
map("n", "<C-y>", "<C-r>", { desc = "Redo" })
map("n", "<C-S-z>", "<C-r>", { desc = "Redo (Shift+Z)" })

-- Start Selection

-- 1. Normal Mode: Enter Visual Mode and move
map("n", "<S-Right>", "v<Right>", { desc = "Select Right" })
map("n", "<S-Left>", "v<Left>", { desc = "Select Left" })
map("n", "<S-Up>", "v<Up>", { desc = "Select Up" })
map("n", "<S-Down>", "v<Down>", { desc = "Select Down" })

-- -- 2. Visual Mode: Extend selection (FIXED: Added < > brackets)
map("v", "<S-Right>", "<Right>", { desc = "Extend Right" })
map("v", "<S-Left>", "<Left>", { desc = "Extend Left" })
map("v", "<S-Up>", "<Up>", { desc = "Extend Up" })
map("v", "<S-Down>", "<Down>", { desc = "Extend Down" })

-- -- 3. Insert Mode: Escape to Visual Mode and move (VS Code Style)
-- This fixes the "Switching" issue when you try to select while typing
map("i", "<S-Right>", "<Esc>v<Right>", { desc = "Select Right" })
map("i", "<S-Left>", "<Esc>v<Left>", { desc = "Select Left" })
map("i", "<S-Up>", "<Esc>v<Up>", { desc = "Select Up" })
map("i", "<S-Down>", "<Esc>v<Down>", { desc = "Select Down" })

local cmp = require "cmp"

cmp.setup {
  mapping = {
    -- Down Arrow: Go to next item
    ["<Down>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end, { "i", "s" }),

    -- Up Arrow: Go to previous item
    ["<Up>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end, { "i", "s" }),

    -- Tab: Confirm selection (VS Code style)
    ["<Tab>"] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },

    -- Enter: Regular newline (unless you want it to confirm)
    ["<CR>"] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Insert,
      select = false, -- Only confirm if you specifically selected an item
    },
  },
}

map({ "i", "n", "v" }, "<F5>", function()
  vim.cmd "Debug"
end)

map({ "i", "n", "v" }, "<S-F5>", function()
  vim.cmd "Run"
end)

map("n", "<leader>nf", function ()
  vim.cmd "NewFile"
end)
map("n", "<leader>np", function ()
  vim.cmd "NewProject"
end)

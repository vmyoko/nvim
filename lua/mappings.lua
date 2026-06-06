require "nvchad.mappings"

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

map({ "i", "n", "v" }, "<F5>", function()
  vim.cmd("Debug")
end)

vim.keymap.set({ "i", "n", "v" }, "<S-F5>", '<cmd>Run<CR>')

map({ "n", "t" }, "<C-t>", function()
  vim.cmd "FloatermToggle"
end, {})

map("n", "<C-f>", function()
  vim.cmd(":Telescope file_browser")
end)

map("n", "<F2>", function()
  require "nvchad.lsp.renamer"()
end)

-- Horizontal scrolling
map({ "n", "i", "v" }, "<ScrollWheelLeft>", "5zh", { silent = true })
map({ "n", "i", "v" }, "<ScrollWheelRight>", "5zl", { silent = true })
map({ "n", "i", "v" }, "<S-ScrollWheelUp>", "5zh", { silent = true })
map({ "n", "i", "v" }, "<S-ScrollWheelDown>", "5zl", { silent = true })

-- Mouse menu
map({ "n", "v" }, "<RightMouse>", function()
  require("menu.utils").delete_old_menus()
  vim.cmd.exec '"normal! \\<RightMouse>"'

  local buf = vim.api.nvim_win_get_buf(vim.fn.getmousepos().winid)
  local options = vim.bo[buf].ft == "NvimTree" and "nvimtree" or "default"

  require("menu").open(options, { mouse = true })
end, {})

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

    ["<ESC>"] = cmp.mapping.abort()
  },
}

map("n", "<leader>nf", function ()
  vim.cmd "NewFile"
end)
map("n", "<leader>np", function ()
  vim.cmd "NewProject"
end)

-- OIL.NVIM
map("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- NEOGIT
map("n", "<leader>gs", "<CMD>Neogit<CR>", { desc = "Open Neogit" })

-- DIFFVIEW
map("n", "<leader>gd", "<CMD>DiffviewOpen<CR>", { desc = "Open Diffview" })
map("n", "<leader>gD", "<CMD>DiffviewClose<CR>", { desc = "Close Diffview" })

-- HARPOON
local harpoon = require("harpoon")
map("n", "<leader>a", function() harpoon:list():add() end, { desc = "Harpoon Add" })
map("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon Menu" })
map("n", "<C-1>", function() harpoon:list():select(1) end, { desc = "Harpoon 1" })
map("n", "<C-2>", function() harpoon:list():select(2) end, { desc = "Harpoon 2" })
map("n", "<C-3>", function() harpoon:list():select(3) end, { desc = "Harpoon 3" })
map("n", "<C-4>", function() harpoon:list():select(4) end, { desc = "Harpoon 4" })

-- TROUBLE
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics (Trouble)" })

-- TODO COMMENTS
map("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find TODOs" })

-- TELESCOPE UNDO
map("n", "<leader>fu", "<cmd>Telescope undo<cr>", { desc = "Find Undo History" })

-- PERSISTENCE (Session Management)
map("n", "<leader>qs", function() require("persistence").load() end, { desc = "Restore Session for cwd" })
map("n", "<leader>ql", function() require("persistence").load({ last = true }) end, { desc = "Restore Last Session" })
map("n", "<leader>qd", function() require("persistence").stop() end, { desc = "Stop Session Save" })

-- REFACTORING
map("v", "<leader>re", ":Refactor extract ", { desc = "Extract Function" })
map("v", "<leader>rf", ":Refactor extract_to_file ", { desc = "Extract Function To File" })
map("v", "<leader>rv", ":Refactor extract_var ", { desc = "Extract Variable" })
map({ "n", "v" }, "<leader>ri", ":Refactor inline_var", { desc = "Inline Variable" })

-- NEOVIDE ZOOM
if vim.g.neovide then
  map({ "n", "v", "i" }, "<C-=>", function()
    vim.g.neovide_scale_factor = (vim.g.neovide_scale_factor or 1) + 0.1
  end, { desc = "Zoom In (Neovide)" })
  map({ "n", "v", "i" }, "<C-->", function()
    vim.g.neovide_scale_factor = (vim.g.neovide_scale_factor or 1) - 0.1
  end, { desc = "Zoom Out (Neovide)" })
  map({ "n", "v", "i" }, "<C-0>", function()
    vim.g.neovide_scale_factor = 1.0
  end, { desc = "Reset Zoom (Neovide)" })
end

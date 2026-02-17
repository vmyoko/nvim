vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- 1. Setup Mason itself first
require("mason").setup({
    ui = {
        icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
        }
    }
})

-- 2. Setup mason-tool-installer
-- This plugin handles the "Ensure Installed" for EVERYTHING (LSP, DAP, Linters)
require("mason-tool-installer").setup({
    ensure_installed = {
        -- === LSPs ===
        "gopls",
        "rust-analyzer",
        "csharp-language-server", 
        "marksman",
        "css-variables-language-server",
        "html-lsp",
        "clangd",
        "css-lsp",
        "cssmodules-language-server",
        "golangci-lint-langserver",
        "json-lsp",
        "jsonld-lsp",
        "llm-ls",
        "lua-language-server",
        "markdown-oxide",
        "omnisharp",
        "pyright",
        "python-lsp-server",
        "typescript-language-server", -- Note: This installs the server. In lspconfig setup, refer to it as "ts_ls"
        "home-assistant-language-server", -- Corrected from 'vscode-home-assistant'
        "yaml-language-server",

        -- === Linters & Formatters ===
        "cfn-lint",
        "markdownlint-cli2",
        "clang-format",
        "htmlhint",
        "golangci-lint",
        "cmakelang",
        "csharpier",
        -- "json-repair", -- Note: Check if this exists in Mason, might need manual install or specific naming
        "cmakelint",
        "cpplint",
        "hlint",
        "jsonlint",
        "markdown-toc",
        "markdownlint",
        "mdformat",
        "npm-groovy-lint",
        "pyink",
        "pylint",
        "pylyzer",
        "stylua",
        -- "xcbeautify", -- Note: Usually a Swift tool installed via Brew, might not be in Mason
        "yamlfmt",

        -- === Debug Adapters (DAP) ===
        "codelldb",
        "delve",
        "cpptools",
        "go-debug-adapter",
        "js-debug-adapter",
        "netcoredbg",
    },
    -- Auto-install on startup
    run_on_start = true, 
})

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

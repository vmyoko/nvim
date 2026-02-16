return {
  -- 1. Formatting
  {
    "stevearc/conform.nvim",
    opts = require "configs.conform",
  },

  -- 2. Language Server (LSP)
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
  },

  -- 3. UI: Indent Guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
    config = function()
      require("ibl").setup {
        indent = { char = "│" },
        scope = { enabled = true },
      }
    end,
  },

  -- 4. DEBUGGER BUNDLE (DAP + UI + GDB Adapter)
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "williamboman/mason.nvim",
      "williamboman/mason-nvim-dap.nvim",
      "leoluz/nvim-dap-go",
    },
    config = function()
      local dap = require "dap"
      local dapui = require "dapui"

      require("dap-go").setup()

      dap.adapters.codelldb = {
        type = "executable",
        command = "/home/vinim/.local/share/nvim/mason/bin/codelldb",
      }

      dap.adapters.coreclr = {
        type = "executable",
        command = "/snap/bin/netcoredbg",
      }

      dap.configurations.rust = {
        {
          name = "Debug",
          type = "codelldb",
          request = "launch",
          program = function()
            local exe_path = vim.fn.system "make echo-output-path"
            exe_path = string.gsub(exe_path, "\n", "")

            return exe_path
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          externalConsole = false,
        },
      }

      dap.configurations.cpp = dap.configurations.rust
      dap.configurations.c = dap.configurations.rust

      dap.configurations.go = {
        {
          name = "Debug",
          type = "go",
          request = "launch",
          program = function()
            local exe_path = vim.fn.system "make echo-output-path"
            exe_path = string.gsub(exe_path, "\n", "")

            return exe_path
          end,
          cwd = "${workspaceFolder}",
          stepOnEntry = false,
          externalConsole = false,
        },
      }

      dap.configurations.cs = {
        {
          name = "Debug",
          type = "coreclr",
          request = "launch",
          program = function()
            local exe_path = vim.fn.system "make echo-output-path"
            exe_path = string.gsub(exe_path, "\n", "")

            return exe_path
          end,
          cwd = "${workspaceFolder}",
          stepOnEntry = false,
          externalConsole = false,
        },
      }

      -- Setup UI
      dapui.setup()

      -- Open UI automatically when debug starts
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      -- Cosmetic Signs
      vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "▶️", texthl = "", linehl = "", numhl = "" })

      -- === Adapter: GDB ===
      dap.adapters.gdb = {
        type = "executable",
        command = "gdb",
        args = { "--interpreter=dap" },
      }

      -- Keymaps (Standard DAP controls)
      local keymap = vim.keymap.set
      keymap("n", "<F9>", function()
        dap.toggle_breakpoint()
      end, { desc = "Toggle Breakpoint" })
      keymap("n", "<F10>", function()
        dap.step_over()
      end, { desc = "Step Over" })
      keymap("n", "<F11>", function()
        dap.step_into()
      end, { desc = "Step Into" })
      keymap("n", "<F12>", function()
        dap.step_out()
      end, { desc = "Step Out" })
    end,
  },

  -- 5. MASON (The Package Manager - Installs Everything)
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        -- LSPs
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
        "typescript-language-server",
        "vscode-home-assistant",
        "yaml-language-server",

        -- Linters & Formatters
        "cfn-lint",
        "markdownlint-cli2",
        "clang-format",
        "htmlhint",
        "golangci-lint",
        "cmakelang",
        "csharpier",
        "json-repair",
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
        "xcbeautify",
        "yamlfmt",

        -- Debug Adapters (DAP)
        "codelldb",
        "delve",
        "cpptools",
        "go-debug-adapter",
        "js-debug-adapter",
        "netcoredbg",
      },
    },
  },

  -- 6. MASON DAP (Configures Debuggers - ONLY Debuggers go here)
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = {
      handlers = {},
      ensure_installed = {
        "codelldb",
        "delve",
        "cpptools",
        "go-debug-adapter",
        "js-debug-adapter",
        "netcoredbg",
      },
    },
  },

  -- 5. CMAKE TOOLS (The Project Manager)
  {
    "Civitasv/cmake-tools.nvim",
    lazy = false,
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      local os_config = {}
      if vim.fn.has "unix" == 1 then
        os_config = {
          name = "Cpp Launch",
          type = "gdb",
          request = "launch",
        }
      end

      require("cmake-tools").setup {
        cmake_build_directory = "build",
        cmake_soft_link_compile_commands = true,
        cmake_generate_options = { "-G", "Ninja", "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
        cmake_executor = { name = "quickfix", opts = {} },
        cmake_runner = { name = "terminal", opts = {} },
        cmake_dap_configuration = os_config,
      }
    end,
  },

  -- 6. FILE EXPLORER
  {
    "nvim-tree/nvim-tree.lua",
    opts = {
      renderer = {
        root_folder_label = ":~:s?$?/..?\n",
        indent_markers = { enable = true },
        icons = { show = { folder_arrow = true } },
      },
      sync_root_with_cwd = true,
      respect_buf_cwd = true,
      update_focused_file = { enable = true, update_root = true },
    },
    config = function(_, opts)
      require("nvim-tree").setup(opts)
      -- OPTIMIZED: Only open tree if starting nvim without a file
      vim.api.nvim_create_autocmd({ "VimEnter" }, {
        callback = function(data)
          -- buffer is a directory
          local directory = vim.fn.isdirectory(data.file) == 1
          if not directory and data.file ~= "" then
            return
          end
          require("nvim-tree.api").tree.open()
        end,
      })
    end,
  },

  -- UI Utilities (Minty, Volt, Menu)
  { "nvchad/volt", lazy = false },
  {
    "nvzone/minty",
    cmd = { "Shades", "Huefy" },
    dependencies = { "nvzone/volt" },
  },
  { "nvchad/menu", lazy = true },
  {
    "nvzone/floaterm",
    dependencies = "nvzone/volt",
    opts = {},
    cmd = "FloatermToggle",
  },
  { "MunifTanjim/nui.nvim", lazy = false },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        border = true,
        path_display = { "truncate" },
        sorting_strategy = "ascending",
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.55,
          },
        },
      },
    },
  },

  -- 1. STICKY HEADERS
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    lazy = false,
    event = "BufReadPost",
    config = function()
      require("treesitter-context").setup {
        enable = true,
        throttle = true,
        max_lines = 0,
      }
    end,
  },

  -- 2. THE ERROR SCROLLBAR (Satellite)
  -- Keeping this one as it integrates with Git/LSP better than scrollview
  {
    "lewis6991/satellite.nvim",
    lazy = false,
    event = "BufReadPost",
    config = function()
      require("satellite").setup {
        handlers = {
          diagnostic = { enable = true },
          search = { enable = true },
          gitsigns = { enable = true },
        },
      }
    end,
  },

  -- 3. TRADITIONAL SCROLLBAR (Disabled to avoid conflict with Satellite)
  -- If you prefer this one, comment out "Satellite" above and uncomment this.
  -- {
  --   "dstein64/nvim-scrollview",
  --   lazy = false,
  --   config = function()
  --     require("scrollview").setup({
  --       excluded_filetypes = { "NvimTree", "terminal", "help" },
  --       current_only = true,
  --       horizontal_edge = "bottom",
  --       show_horizontal = true,
  --       always_show = true,
  --       column = 1,
  --     })
  --     vim.api.nvim_set_hl(0, 'ScrollViewHorizontal', { bg = '#61afef', fg = '#61afef' })
  --   end,
  -- },

  -- 4. BETTER FOLDING (UFO)
  {
    "kevinhwang91/nvim-ufo",
    dependencies = "kevinhwang91/promise-async",
    event = "BufReadPost",
    config = function()
      require("ufo").setup()
    end,
  },

  -- 5. AUTOCOMPLETE (Nvim-CMP Overrides)
  {
    "hrsh7th/nvim-cmp",
    opts = function()
      local cmp = require "cmp"
      local conf = require "nvchad.configs.cmp"

      conf.mapping["<CR>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          -- If the menu is open, close it and just do a regular Enter (new line)
          cmp.abort()
        end
        fallback()
      end, { "i", "s" })

      conf.mapping["<Down>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        else
          fallback()
        end
      end, { "i", "s" })

      conf.mapping["<Up>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        else
          fallback()
        end
      end, { "i", "s" })

      conf.mapping["<Tab>"] = cmp.mapping.confirm {
        behavior = cmp.ConfirmBehavior.Replace,
        select = true,
      }
      return conf
    end,
  },

  {
    "Isrothy/neominimap.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    version = "*",
    enabled = true,
    lazy = false,
    keys = {
      "<C-M>",
      "<cmd>Neominimap Toggle<cr>",
    },
    init = function()
      vim.opt.wrap = false -- Minimaps work best without line wrap
      vim.g.neominimap_enabled = true
      vim.opt.sidescrolloff = 36
    end,
  },

  {
    "stevearc/overseer.nvim",
    config = function()
      require("overseer").setup()
    end,
  },
}

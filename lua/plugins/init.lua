return {
  -- 1. Formatting
  {
    "stevearc/conform.nvim",
    opts = require "configs.conform",
  },

  -- 2. Language Server (LSP) Base
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
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

  -- 5. MASON (The Package Manager - Installs LSPs and Formatters)
  {
    "williamboman/mason.nvim",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function()
      -- Inicializa Mason
      require("mason").setup()

      -- Formatadores e ferramentas extras
      require("mason-tool-installer").setup {
        ensure_installed = { "prettier", "clang-format", "stylua" },
        auto_update = false,
        run_on_start = true,
      }

      -- LSPs que você quer garantir instalados
      -- O automatic_enable = true já habilita automaticamente
      require("mason-lspconfig").setup {
        ensure_installed = {
          "clangd",
          "html",
          "cssls",
          "ts_ls",
          "omnisharp",
          "gopls",
          "pyright",
          "marksman",
          "jsonls",
          "lua_ls",
        },
        automatic_enable = true, -- habilita por padrão
      }

      -- Opcional: Fiz isso caso queira configurar ajustes específicos
      -- vim.lsp.config("lua_ls", { settings = { ... } })

      -- Com a API nova integrada no Neovim, não precisa de setup_handlers aqui
    end,
  },

  -- 6. MASON DAP (Configures Debuggers)
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

  -- 7. CMAKE TOOLS (The Project Manager)
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

  -- 8. FILE EXPLORER
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
          local directory = vim.fn.isdirectory(data.file) == 1
          if not directory and data.file ~= "" then
            return
          end
          require("nvim-tree.api").tree.open()
        end,
      })
    end,
  },

  -- 9. UI Utilities (Minty, Volt, Menu)
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

  -- 10. Telescope
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

  -- 11. STICKY HEADERS
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

  -- 12. THE ERROR SCROLLBAR (Satellite)
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

  -- 13. BETTER FOLDING (UFO)
  {
    "kevinhwang91/nvim-ufo",
    dependencies = "kevinhwang91/promise-async",
    event = "BufReadPost",
    config = function()
      require("ufo").setup()
    end,
  },

  -- 14. AUTOCOMPLETE (Nvim-CMP Overrides)
  {
    "hrsh7th/nvim-cmp",
    opts = function()
      local cmp = require "cmp"
      local conf = require "nvchad.configs.cmp"

      conf.mapping["<CR>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
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

  -- 15. NEOMINIMAP
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
      vim.opt.wrap = false
      vim.g.neominimap_enabled = true
      vim.opt.sidescrolloff = 36
    end,
  },

  -- 16. OVERSEER (Task Runner)
  {
    "stevearc/overseer.nvim",
    config = function()
      require("overseer").setup()
    end,
  },

  -- 17. TELESCOPE FILE BROWSER
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
  },
}

local M = {}

M.setup = function()
  local logo = {
    [[    ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗]],
    [[    ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║]],
    [[    ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║]],
    [[    ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║]],
    [[    ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║]],
    [[    ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
  }

  require("dashboard").setup({
    theme = "doom",
    config = {
      header = logo,
      center = {
        { action = "ProjectManager", desc = " Project Manager", icon = " ", key = "p" },
        { action = "NewFile", desc = " New File", icon = " ", key = "n" },
        { action = "Telescope oldfiles", desc = " Recent Files", icon = " ", key = "r" },
        { action = "Telescope find_files", desc = " Find File", icon = " ", key = "f" },
        { action = "Telescope live_grep", desc = " Find Word", icon = "󰩮 ", key = "w" },
        { action = "terminal", desc = " Open Terminal", icon = "󰆍 ", key = "t" },
        { action = "Telescope themes", desc = " Themes", icon = " ", key = "h" },
        { action = "Mason", desc = " Mason", icon = "󰒲 ", key = "m" },
        { action = "Lazy", desc = " Lazy", icon = "󰒲 ", key = "l" },
        { action = "lua vim.cmd('cd ' .. vim.fn.stdpath('config')) require('oil').open()", desc = " Dotfiles", icon = " ", key = "d" },
        { action = "qa", desc = " Quit", icon = " ", key = "q" },
      },
      footer = function()
        local stats = require("lazy").stats()
        local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
        return { "⚡ Neovim loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms" }
      end,
    },
  })
  
  -- Make the dashboard header use NvChad's blue color
  vim.api.nvim_set_hl(0, "DashboardHeader", { link = "Function" })
  vim.api.nvim_set_hl(0, "DashboardCenter", { link = "String" })
  vim.api.nvim_set_hl(0, "DashboardShortcut", { link = "Type" })
  vim.api.nvim_set_hl(0, "DashboardFooter", { link = "Comment" })
end

return M

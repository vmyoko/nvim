require "nvchad.autocmds"

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Only open tree if we opened a file (nvim main.cpp)
    if vim.fn.argc() > 0 then
      require("nvim-tree.api").tree.open()
      vim.cmd "wincmd p" -- Focus the file, not the tree
    else
      -- Open custom dashboard
      if not vim.g.wizard_active then
        vim.defer_fn(function()
          local ok, err = pcall(function() require("configs.custom_dash").open() end)
          if not ok then
            vim.notify("Dash Error: " .. tostring(err), vim.log.levels.ERROR)
          end
        end, 50)
      else
        vim.notify("Wizard active, skipping dash", vim.log.levels.INFO)
      end
    end
  end,
})

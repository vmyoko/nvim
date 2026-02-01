local nvlsp = require "nvchad.configs.lspconfig"
nvlsp.defaults() -- loads lua_ls

local servers = {
  "clangd",
  "pyright",
  "rust_analyzer",
  "gopls",
  "css-lsp",
  "html-lsp",
  "typescript-language-server",
}

for _, lsp in ipairs(servers) do
  vim.lsp.enable(lsp)
end

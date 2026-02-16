local nvlsp = require "nvchad.configs.lspconfig"
nvlsp.defaults() -- loads lua_ls

local servers = {
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
    "pylyzer",
    "pyright",
    "python-lsp-server",
    "stylua",
    "typescript-language-server",
    "vscode-home-assistant",
    "yaml-language-server"
}

for _, lsp in ipairs(servers) do
  vim.lsp.enable(lsp)
end

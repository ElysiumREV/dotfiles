return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim", -- Recommended for managing LSP servers
    "williamboman/mason-lspconfig.nvim", -- Integrates Mason with nvim-lspconfig
  },
  config = function()
    require("mason").setup()
    require("mason-lspconfig").setup({
      -- Optional: List of language servers to install and set up automatically
      ensure_installed = {
        "lua_ls",
        "pyright",
        "ts_ls",
      },
    })

    local lspconfig = require("lspconfig")
    -- Example: Setup for Lua language server
    lspconfig.lua_ls.setup({
      settings = {
        Lua = {
          workspace = { checkThirdParty = false },
          telemetry = { enable = false },
        },
      },
    })

    -- Example: Setup for Pyright language server
    lspconfig.pyright.setup({})

    -- You can add more lspconfig.SERVER_NAME.setup({}) calls for other servers
  end,
}

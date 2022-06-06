# PLOGINS.NVIM

A fast, simple, and elegant Neovim plugin manager written in Lua!

## EXAMPLE
```lua
local upgrade, autoremove = require("plogins").setup {
    ["https://github.com/tpope/vim-commentary.git"] = {},
    ["https://github.com/tpope/vim-repeat.git"] = {},
    ["https://github.com/tpope/vim-rsi.git"] = {},
    ["https://github.com/tpope/vim-sleuth.git"] = {},
    ["https://github.com/tpope/vim-unimpaired.git"] = {},
    ["https://github.com/tpope/vim-vinegar.git"] = {},

    ["https://github.com/tpope/vim-fugitive.git"] = {
        packadd_hook = function()
            vim.api.nvim_set_keymap("n", "<leader>g", "<cmd>Git<CR>", opts)
        end,
    },

    ["https://github.com/nvim-treesitter/nvim-treesitter.git"] = {
        packadd_hook = function()
            require("nvim-treesitter.configs").setup {
                ensure_installed = "all",
                highlight = { enable = true },
                indent = { enable = true },
            }
            vim.opt.foldmethod = "expr"
            vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
        end,
        upgrade_hook = function()
            require("nvim-treesitter.install").update()
        end,
    },

    ["https://github.com/nvim-treesitter/nvim-treesitter-textobjects.git"] = {
        packadd_after = { ["https://github.com/nvim-treesitter/nvim-treesitter.git"] = {} },
        packadd_hook = function()
            require("nvim-treesitter.configs").setup {
                textobjects = {
                    select = {
                        enable = true,
                        lookahead = true,
                        keymaps = {
                            ["af"] = "@function.outer",
                            ["if"] = "@function.inner",
                            ["ac"] = "@class.outer",
                            ["ic"] = "@class.inner",
                        },
                    },
                },
            }
        end,
    },
}

vim.api.nvim_create_user_command("PloginsUpgrade", upgrade, {})
vim.api.nvim_create_user_command("PloginsAutoremove", autoremove, {})
```
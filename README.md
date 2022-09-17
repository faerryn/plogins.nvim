# PLOGINS.NVIM

A fast, simple, and elegant Neovim plugin manager written in Lua!

Warning: plogins.nvim is alpha-quality software. Things could change and break
at a moment's notice!

## FEATURES
- Table-based configuration to utilize the powers of Lua tables.
- Statelessness for reloading your vimrc fearlessly.
- Hooks on packadd and upgrade.
- Ordered loading of plugins to ensure dependencies.
- Non-blocking (asynchronous) git operations through Neovim's built-in LibUV.

## EXAMPLE
```lua
local function manage_plugins()
    local plugins = {
        ["https://github.com/faerryn/plogins.nvim.git"] = {},

        ["https://github.com/tpope/vim-commentary.git"] = {},
        ["https://github.com/tpope/vim-fugitive.git"]   = {},
        ["https://github.com/tpope/vim-repeat.git"]     = {},
        ["https://github.com/tpope/vim-rsi.git"]        = {},
        ["https://github.com/tpope/vim-sleuth.git"]     = {},
        ["https://github.com/tpope/vim-unimpaired.git"] = {},
        ["https://github.com/tpope/vim-vinegar.git"]    = {},

        ["https://github.com/navarasu/onedark.nvim.git"] = {
            packadd_hook = function()
                vim.cmd([[colorscheme onedark]])
            end,
        },

        ["https://github.com/nvim-lualine/lualine.nvim.git"] = {
            packadd_hook = function()
                require("lualine").setup({
                    options = {
                        icons_enabled = false,
                        component_separators = { left = "", right = "" },
                        section_separators   = { left = "", right = "" },
                    },
                    tabline = { lualine_a = { "tabs" } },
                })
            end,
        },

        ["https://github.com/lewis6991/gitsigns.nvim.git"] = {
            packadd_hook = function()
                require("gitsigns").setup()
            end,
        },

        ["https://github.com/nvim-treesitter/nvim-treesitter.git"] = {
            packadd_hook = function()
                require("nvim-treesitter.configs").setup({
                    ensure_installed = "all",
                    highlight = { enable = true },
                    indent    = { enable = true },
                })
                vim.opt.foldmethod = "expr"
                vim.opt.foldexpr   = "nvim_treesitter#foldexpr()"
            end,
            upgrade_hook = function()
                require("nvim-treesitter.install").update()
            end,
        },

        ["https://github.com/nvim-treesitter/nvim-treesitter-textobjects.git"] = {
            packadd_after = { ["https://github.com/nvim-treesitter/nvim-treesitter.git"] = true },
            packadd_hook = function()
                require("nvim-treesitter.configs").setup({
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
                })
            end,
        },
    }

    local manager = require("plogins").manage(plugins)

    vim.api.nvim_create_user_command("PloginsUpgrade",    manager.upgrade,    {})
    vim.api.nvim_create_user_command("PloginsAutoremove", manager.autoremove, {})
end

local plogins_source = "https://github.com/faerryn/plogins.nvim.git"
local plogins_name = plogins_source:gsub("/", "%%")
local plogins_dir = ("%s/site/pack/plogins/opt/%s"):format((vim.fn.stdpath("data")), plogins_name)
if not vim.loop.fs_stat(plogins_dir) then
    vim.loop.spawn("git", { args = { "clone", "--depth", "1", plogins_source, plogins_dir } }, function(code, signal)
        vim.defer_fn(function()
            vim.cmd(("packadd %s"):format(vim.fn.fnameescape(plogins_name)))
            manage_plugins()
        end, 0)
    end)
else
    vim.cmd(("packadd %s"):format(vim.fn.fnameescape(plogins_name)))
    manage_plugins()
end
```

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
local plugins = {
    "https://github.com/faerryn/plogins.nvim.git",

    "https://github.com/tommcdo/vim-lion.git",
    "https://github.com/tpope/vim-commentary.git",

    ["https://github.com/nvim-treesitter/nvim-treesitter.git"] = {
        packadd_hook = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = "all",
                ignore_install = { "ipkg" },
                highlight = { enable = true },
                indent    = { enable = true },
            })
            vim.opt.foldmethod = "expr"
            vim.opt.foldexpr   = "nvim_treesitter#foldexpr()"
        end,
        upgrade_hook = function() require("nvim-treesitter.install").update() end,
    },
}

local plogins_source = "https://github.com/faerryn/plogins.nvim.git"
local plogins_name = plogins_source:gsub("/", "%%")
local plogins_dir = ("%s/site/pack/plogins/opt/%s"):format((vim.fn.stdpath("data")), plogins_name)
local function manage_plugins()
    vim.cmd(("packadd %s"):format(vim.fn.fnameescape(plogins_name)))
    local manager = require("plogins").manage(plugins)
    vim.api.nvim_create_user_command("PloginsUpgrade", manager.upgrade,    {})
    vim.api.nvim_create_user_command("PloginsClean",   manager.autoremove, {})
end
if not vim.loop.fs_stat(plogins_dir) then
    vim.loop.spawn("git", { args = { "clone", "--depth", "1", plogins_source, plogins_dir } },
        vim.schedule_wrap(function(code, signal) manage_plugins() end))
else
    manage_plugins()
end
```

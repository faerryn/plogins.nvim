local M = {}

local function packadd(plogin)
    vim.cmd(("packadd %s"):format(vim.fn.fnameescape(plogin.name)))
    pcall(plogin.packadd_hook)
end

local function helptags(plogin)
    local docdir = plogin.dir .. "/doc"
    if vim.loop.fs_stat(docdir) then
        vim.cmd(("helptags %s"):format(vim.fn.fnameescape(docdir)))
    end
end

local function find_version(plogin)
    return vim.fn.system { "git", "-C", plogin.dir, "rev-parse", "HEAD" }
end

local function subset(a, b)
    for x, _ in pairs(a) do
        if b[x] == nil then
            return false
        end
    end
    return true
end

local function recursively_delete(path)
    local stat = vim.loop.fs_stat(path)
    if stat.type == "directory" then
        local handle = vim.loop.fs_scandir(path)
        for entry in vim.loop.fs_scandir_next, handle do
            recursively_delete(("%s/%s"):format(path, entry))
        end
        vim.loop.fs_rmdir(path)
    else
        vim.loop.fs_unlink(path)
    end
end

function M.setup(plogins)
    local plogins_directory = ("%s/site/pack/plogins/opt"):format(vim.fn.stdpath "data")

    local activated_sources = {}
    local pending_sources = {}

    local function try_activate(plogin)
        if subset(plogin.packadd_after, activated_sources) then
            packadd(plogin)
            activated_sources[plogin.source] = true
            pending_sources[plogin.source] = nil
            return true
        else
            pending_sources[plogin.source] = true
            return false
        end
    end

    for source, plogin in pairs(plogins) do
        plogin.upgrade_hook = plogin.upgrade_hook or function() end
        plogin.packadd_hook = plogin.packadd_hook or function() end
        plogin.packadd_after = plogin.packadd_after or {}

        plogin.name = source:gsub("/", "%%")
        plogin.dir = ("%s/%s"):format(plogins_directory, plogin.name)
        plogin.source = source

        if vim.loop.fs_stat(plogin.dir) then
            try_activate(plogin)
        else
            local handle = nil
            handle = vim.loop.spawn(
                "git",
                { args = { "clone", "--depth", "1", source, plogin.dir } },
                function(code, signal)
                    handle:close()
                    vim.defer_fn(function()
                        helptags(plogin)
                        try_activate(plogin)
                        print(("%s installed"):format(source))
                    end, 0)
                end
            )
        end
    end

    local progress = true
    while progress do
        progress = false
        for source, _ in pairs(pending_sources) do
            progress = try_activate(plogins[source]) or progress
        end
    end

    local function upgrade()
        for source, _ in pairs(activated_sources) do
            local plogin = plogins[source]
            local handle = nil
            local version = find_version(plogin)
            handle = vim.loop.spawn(
                "git",
                { args = { "-C", plogin.dir, "pull", "--depth", "1", "--force", "--rebase" } },
                function(code, signal)
                    handle:close()
                    vim.defer_fn(function()
                        if version ~= find_version(plogin) then
                            helptags(plogin)
                            pcall(plogin.upgrade_hook)
                            print(("%s upgraded"):format(source))
                        end
                    end, 0)
                end
            )
        end
    end

    local function autoremove()
        local handle = vim.loop.fs_scandir(plogins_directory)
        for entry in vim.loop.fs_scandir_next, handle do
            local source = entry:gsub("%%", "/")
            if plogins[source] == nil then
                recursively_delete(("%s/%s"):format(plogins_directory, entry))
                print(("%s removed"):format(source))
            end
        end
    end

    return upgrade, autoremove
end

return M

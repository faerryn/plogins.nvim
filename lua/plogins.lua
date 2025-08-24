local M = {}

local function packadd(details)
    vim.cmd(("packadd %s"):format(vim.fn.fnameescape(details.name)))
    pcall(details.packadd_hook)
end

local function helptags(details)
    local docdir = details.dir .. "/doc"
    if vim.uv.fs_stat(docdir) then
        vim.cmd(("helptags %s"):format(vim.fn.fnameescape(docdir)))
    end
end

local function find_version(details)
    return vim.fn.system { "git", "-C", details.dir, "rev-parse", "HEAD" }
end

local function subset(a, b)
    for x, _ in pairs(a) do
        if b[x] == nil then
            return false
        end
    end
    return true
end

local function scandir(path)
    local entries = {}
    local handle = vim.uv.fs_scandir(path)
    for entry in vim.uv.fs_scandir_next, handle do
        table.insert(entries, entry)
    end
    return entries
end

local function recursively_delete(path)
    local stat = vim.uv.fs_stat(path)
    if stat.type == "directory" then
        for _, entry in ipairs(scandir(path)) do
            recursively_delete(("%s/%s"):format(path, entry))
        end
        vim.uv.fs_rmdir(path)
    else
        vim.uv.fs_unlink(path)
    end
end

function M.manage(plogins)
    local plogins_directory = ("%s/site/pack/plogins/opt"):format(vim.fn.stdpath "data")

    local activated_sources = {}
    local pending_sources = {}

    local function try_activate(details)
        if subset(details.packadd_after, activated_sources) then
            packadd(details)
            activated_sources[details.source] = true
            pending_sources[details.source] = nil
            return true
        else
            pending_sources[details.source] = true
            return false
        end
    end

    canonized_plogins = {}
    for key, value in pairs(plogins or {}) do
        if type(key) == "number" then
            canonized_plogins[value] = {}
        else
            canonized_plogins[key] = value
        end
    end
    plogins = canonized_plogins

    for source, details in pairs(plogins) do
        details.upgrade_hook = details.upgrade_hook or function() end
        details.packadd_hook = details.packadd_hook or function() end
        
        canonized_packadd_after = {}
        for key, value in pairs(details.packadd_after or {}) do
            if type(key) == "number" then
                canonized_packadd_after[value] = true
            else
                canonized_packadd_after[key] = value
            end
        end
        details.packadd_after = canonized_packadd_after

        details.name = source:gsub("/", "%%")
        details.dir = ("%s/%s"):format(plogins_directory, details.name)
        details.source = source

        if vim.uv.fs_stat(details.dir) then
            try_activate(details)
        else
            local handle = nil
            handle = vim.uv.spawn(
                "git",
                { args = { "clone", "--depth", "1", source, details.dir } },
                function(code, signal)
                    handle:close()
                    if code == 0 then
                        vim.defer_fn(function()
                            helptags(details)
                            try_activate(details)
                            print(("%s installed"):format(source))
                        end, 0)
                    else
                        print(("%s failed to install"):format(source))
                    end
                end
            )
        end
    end

    local progress = true
    while progress do
        progress = false
        for source, _ in pairs(pending_sources) do
            if try_activate(plogins[source]) then
                progress = true
            end
        end
    end

    local function upgrade()
        for source, _ in pairs(activated_sources) do
            local details = plogins[source]
            local handle = nil
            local version = find_version(details)
            handle = vim.uv.spawn(
                "git",
                { args = { "-C", details.dir, "pull", "--depth", "1", "--force", "--rebase" } },
                function(code, signal)
                    handle:close()
                    vim.defer_fn(function()
                        if version ~= find_version(details) then
                            helptags(details)
                            pcall(details.upgrade_hook)
                            print(("%s upgraded"):format(source))
                        end
                    end, 0)
                end
            )
        end
    end

    local function autoremove()
        for _, entry in ipairs(scandir(plogins_directory)) do
            local source = entry:gsub("%%", "/")
            if plogins[source] == nil then
                recursively_delete(("%s/%s"):format(plogins_directory, entry))
                print(("%s removed"):format(source))
            end
        end
    end

    return { upgrade = upgrade, autoremove = autoremove }
end

return M

Citizen.CreateThread(function()
    local updatePath = "/DiscordAcePerms" -- your git user/repo path
    local resourceName = "DiscordAcePerms (" .. GetCurrentResourceName() .. ")" -- the resource name

    local function checkVersion(err, responseText, headers)
        local curVersion = LoadResourceFile(GetCurrentResourceName(), "version.txt")
        if not curVersion or curVersion == "" then
            print("\n[" .. resourceName .. "] Could not load local version.txt")
            return
        end

        local remoteVersion = responseText or ""
        if remoteVersion == "" then
            print("\n[" .. resourceName .. "] Could not fetch remote version")
            return
        end

        local curVersionNum = tonumber(curVersion)
        local remoteVersionNum = tonumber(remoteVersion)

        if curVersion ~= remoteVersion and curVersionNum and remoteVersionNum then
            if curVersionNum < remoteVersionNum then
                print("\n###############################")
                print("\n" .. resourceName .. " is outdated, should be:\n" .. remoteVersion .. "\nis:\n" .. curVersion .. "\nplease update it from https://github.com" .. updatePath)
                print("\n###############################")
            elseif curVersionNum > remoteVersionNum then
                print("You somehow skipped a few versions of " .. resourceName .. " or the git went offline, if it's still online I advise you to update...")
            else
                print("\n" .. resourceName .. " is up to date!")
            end
        else
            print("\n" .. resourceName .. " is up to date!")
        end
    end

    PerformHttpRequest("https://raw.githubusercontent.com/DiscordAcePerms/master/version.txt", checkVersion, "GET")
end)
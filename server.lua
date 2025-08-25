---------------------------------
--- Discord ACE Perms by Dead ---
---------------------------------

--- Code ---
local function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function stringsplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    local i = 1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

function ExtractIdentifiers(src)
    local identifiers = {
        steam = "",
        ip = "",
        discord = "",
        license = "",
        xbl = "",
        live = ""
    }

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if string.find(id, "steam") then
            identifiers.steam = id
        elseif string.find(id, "ip") then
            identifiers.ip = id
        elseif string.find(id, "discord") then
            identifiers.discord = id
        elseif string.find(id, "license") then
            identifiers.license = id
        elseif string.find(id, "xbl") then
            identifiers.xbl = id
        elseif string.find(id, "live") then
            identifiers.live = id
        end
    end

    return identifiers
end

local DiscordDetector = {}
local InDiscordDetector = {}
local PermTracker = {}
local roleList = Config.roleList
local debugScript = Config.DebugScript
local permThrottle = {}
local ROLE_CACHE = {}
local prefix = '^9[^5Dead_DiscordAcePerms^9] ^3'

local card = '{"type":"AdaptiveCard","$schema":"http://adaptivecards.io/schemas/adaptive-card.json","version":"1.2","body":[{"type":"Container","items":[{"type":"TextBlock","text":"Welcome to ' .. Config.Server_Name .. '","wrap":true,"fontType":"Default","size":"ExtraLarge","weight":"Bolder","color":"Light"},{"type":"TextBlock","text":"You were not detected in our Discord!","wrap":true,"size":"Large","weight":"Bolder","color":"Light"},{"type":"TextBlock","text":"Please join below, then press play! Have fun!","wrap":true,"color":"Light","size":"Medium"},{"type":"ColumnSet","height":"stretch","minHeight":"100px","bleed":true,"horizontalAlignment":"Center","selectAction":{"type":"Action.OpenUrl"},"columns":[{"type":"Column","width":"stretch","items":[{"type":"ActionSet","actions":[{"type":"Action.OpenUrl","title":"Discord","url":"' .. Config.Discord_Link .. '","style":"positive"}]}]},{"type":"Column","width":"stretch","items":[{"type":"ActionSet","actions":[{"type":"Action.Submit","title":"Play","style":"positive", "id":"played"}]}]},{"type":"Column","width":"stretch","items":[{"type":"ActionSet","actions":[{"type":"Action.OpenUrl","title":"Website","style":"positive","url":"' .. Config.Website_Link .. '"}]}]}]},{"type":"ActionSet","actions":[{"type":"Action.OpenUrl","title":"4R_DiscordAcePerms created by 4R","style":"destructive","iconUrl":"https://i.gyazo.com/c629f37bb1aeed2c1bc1768fdc93bc1a.gif","url":"https://discord.com/invite/WjB5VFz"}]}],"style":"default","bleed":true,"height":"stretch","isVisible":true}]}'

Citizen.CreateThread(function()
    while true do
        for discord, count in pairs(permThrottle) do
            permThrottle[discord] = (permThrottle[discord] - 1)
            if permThrottle[discord] <= 0 then
                permThrottle[discord] = nil
            end
        end
        Wait(1000)
    end
end)

function sendMsg(src, msg)
    TriggerClientEvent('chatMessage', src, prefix .. msg)
end

function sendDbug(msg, eventLocation)
    if debugScript then
        print("[Dead_DiscordAcePerms DEBUG] (" .. eventLocation .. ") " .. msg)
    end
end

function convertRolesToMap(roleIds)
    local roleMap = {}
    for i = 1, #roleIds do
        roleMap[tostring(roleIds[i])] = true
    end
    return roleMap
end

function RegisterPermissions(src, eventLocation)
    local ids = ExtractIdentifiers(src)
    local license = ids.license
    local discordRaw = ids.discord
    local discord = discordRaw and discordRaw:gsub("discord:", "") or nil
    if discord then
        sendDbug("Player " .. GetPlayerName(src) .. " had their Discord identifier found...", eventLocation)
        exports['DeadR_Discord_API']:ClearCache(discord)
        PermTracker[discord] = nil
        local permAdd = "add_principal identifier.discord:" .. discord .. " "
        local roleIDs = exports['Dead_Discord_API']:GetDiscordRoles(src)
        if roleIDs ~= false then
            local ROLE_MAP = convertRolesToMap(roleIDs)
            sendDbug("Player " .. GetPlayerName(src) .. " had a valid roleIDs... Length: " .. tostring(#roleIDs), eventLocation)
            for i = 1, #roleList do
                local discordRoleId = ROLE_CACHE[roleList[i][1]] or exports['Dead_Discord_API']:FetchRoleID(roleList[i][1])
                if discordRoleId then
                    ROLE_CACHE[roleList[i][1]] = discordRoleId
                end
                sendDbug("Checking to add permission: " .. roleList[i][2] .. " => Player " .. GetPlayerName(src) .. " has role " .. tostring(discordRoleId) .. " and it was compared against " .. roleList[i][1], eventLocation)
                if ROLE_MAP[tostring(discordRoleId)] then
                    if Config.Print_Perm_Grants_And_Removals then
                        print("[Dead_DiscordAcePerms] (" .. eventLocation .. ") Added " .. GetPlayerName(src) .. " to role group " .. roleList[i][2])
                    end
                    ExecuteCommand(permAdd .. roleList[i][2])
                    PermTracker[discord] = PermTracker[discord] or {}
                    table.insert(PermTracker[discord], roleList[i][2])
                end
            end
            return true
        else
            sendDbug(GetPlayerName(src) .. " has not gotten permissions because we could not find their roles...", eventLocation)
            return false
        end
    end
    return false
end

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    if not source then return end
    deferrals.defer()
    local src = source
    local ids = ExtractIdentifiers(src)
    local license = ids.license
    local discordRaw = ids.discord
    local discord = discordRaw and discordRaw:gsub("discord:", "") or nil

    if discord then
        if not RegisterPermissions(src, 'playerConnecting') then
            if not InDiscordDetector[license] then
                InDiscordDetector[license] = true
                local clicked = false
                local attempts = 0
                while not clicked and attempts < 5 do
                    deferrals.presentCard(card, function(data, rawData)
                        if data.submitId == 'played' then
                            clicked = true
                            deferrals.done()
                        end
                    end)
                    Citizen.Wait(13000)
                    attempts = attempts + 1
                end
                if not clicked then deferrals.done("Failed to verify Discord after multiple attempts.") end
                return
            end
        else
            TriggerEvent('vMenu:RequestPermissions', src)
        end
    else
        if not DiscordDetector[license] then
            DiscordDetector[license] = true
            print('[Dead_DiscordAcePerms] Discord was not found for player ' .. GetPlayerName(src) .. "...")
            local clicked = false
            local attempts = 0
            while not clicked and attempts < 5 do
                deferrals.presentCard(card, function(data, rawData)
                    if data.submitId == 'played' then
                        clicked = true
                        deferrals.done()
                    end
                end)
                Citizen.Wait(13000)
                attempts = attempts + 1
            end
            if not clicked then deferrals.done("Failed to detect Discord after multiple attempts.") end
            return
        end
    end
    deferrals.done()
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    local ids = ExtractIdentifiers(src)
    local discordRaw = ids.discord
    local discord = discordRaw and discordRaw:gsub("discord:", "") or nil
    local license = ids.license
    if discord and PermTracker[discord] then
        for _, permGroup in ipairs(PermTracker[discord]) do
            ExecuteCommand('remove_principal identifier.discord:' .. discord .. ' ' .. permGroup)
            if Config.Print_Perm_Grants_And_Removals then
                print("[Dead_DiscordAcePerms] (playerDropped) Removed " .. GetPlayerName(src) .. " from role group " .. permGroup)
            end
        end
        PermTracker[discord] = nil
    end
    DiscordDetector[license] = nil
end)

if Config.Allow_Refresh_Command then
    RegisterCommand('refreshPerms', function(src, args, rawCommand)
        if not src then return end
        local ids = ExtractIdentifiers(src)
        local discordRaw = ids.discord
        local discord = discordRaw and discordRaw:gsub("discord:", "") or nil
        if discord then
            if not permThrottle[discord] then
                permThrottle[discord] = Config.Refresh_Throttle
                sendMsg(src, "Your permissions have been refreshed ^2successfully^3...")
                RegisterPermissions(src, 'refreshPerms')
                TriggerEvent('vMenu:RequestPermissions', src)
            else
                sendMsg(src, "^1ERR: Cooldown active. Refresh in ^3" .. permThrottle[discord] .. " ^1seconds...")
            end
        else
            sendMsg(src, "^1ERR: Your discord identifier was not found...")
        end
    end)
end
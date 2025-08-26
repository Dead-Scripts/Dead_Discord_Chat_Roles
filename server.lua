------------------------------------
--- Discord Chat Roles by Dead ----
------------------------------------

-- Top-level variables
prefix = '^9[^5DiscordChatRoles^9] ^3'
inStaffChat = {}
roleList = Config.roleList
allowedColors = Config.allowedColors
allowedRed = Config.allowedRed
allowedEmoji = Config.allowedEmoji
sendBlockMessages = Config.sendBlockMessages
emojis = Config.emojis
roleTracker = {}
roleAccess = {}
chatcolorTracker = {}
availColors = Config.ColorPatterns

-- Helper Functions
function sendMsg(firstline, msg, to) 
    TriggerClientEvent('chat:addMessage', to, {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(93, 93, 93, 0.25); border-radius: 3px;">{0} <br> {1}</div>',
        args = { firstline, msg }
    })
end

function sleep(a) 
    local sec = tonumber(os.clock() + a)
    while (os.clock() < sec) do end
end

local function has_value(tab, val)
    for _, value in ipairs(tab) do
        if value == val then return true end
    end
    return false
end

function stringsplit(inputstr, sep)
    if sep == nil then sep = "%s" end
    local t={}, i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

function get_index(tab, val)
    for i, value in ipairs(tab) do
        if value == val then return i end
    end
    return nil
end

function setContains(set, key)
    return set[key] ~= nil
end

function msg(src, mesg) 
    TriggerClientEvent('chatMessage', src, prefix .. mesg)
end

function msgRaw(src, mesg)
    TriggerClientEvent('chatMessage', src, mesg)
end

-- Chat Color Commands
local function handleChatColorCommand(source, args)
    local theirList, colorList = {}, {}
    for perm, colors in pairs(availColors) do
        if IsPlayerAceAllowed(source, perm) then
            for colorName, colorArr in pairs(colors) do
                table.insert(theirList, colorName)
                table.insert(colorList, colorArr)
            end
        end
    end

    if #args == 0 then
        if #theirList > 0 then
            TriggerClientEvent('chatMessage', source, prefix .. 'You have access to the following Chat-Colors:')
            for i = 1, #theirList do
                local arr = colorList[i]
                local ex, indCount = '', 1
                local example = 'Example'
                for j = 1, #example do
                    if indCount > #arr then indCount = 1 end
                    ex = ex .. arr[indCount] .. example:sub(j,j)
                    indCount = indCount + 1
                end
                TriggerClientEvent('chatMessage', source, '^9[^4' .. i .. '^9] ^0' .. theirList[i] .. " ---> " .. ex)
            end
        else
            TriggerClientEvent('chatMessage', source, prefix .. '^1ERROR: You have no Chat-Colors :( - Consider donating for some :)')
        end
    else
        local sel = tonumber(args[1])
        if sel and sel <= #theirList then
            chatcolorTracker[source] = colorList[sel]
            TriggerClientEvent('chatMessage', source, prefix .. 'You have set your Chat-Color to ^4' .. theirList[sel])
        else
            TriggerClientEvent('chatMessage', source, '^1ERROR: That is not a valid selection...')
        end
    end
end

RegisterCommand('chatcolor', handleChatColorCommand)
RegisterCommand('cc', handleChatColorCommand)

-- Chat Tag Command
RegisterCommand('chattag', function(source, args)
    local steamID = GetPlayerIdentifiers(source)[1]
    local accessChat = roleAccess[steamID]
    if not accessChat then
        msg(source, 'Your Discord was not detected or you have not typed in chat yet...')
        return
    end

    if #args == 0 then
        msg(source, "You have access to the following Chat-Tags:")
        for i = 1, #accessChat do
            msgRaw(source, '^9[^4' .. i .. '^9] ^r' .. roleList[accessChat[i]][2])
        end
        msg(source, "Use /chattag <id> to change your Chat-Tag")
    else
        local sel = tonumber(args[1])
        if sel and accessChat[sel] then
            roleTracker[steamID] = accessChat[sel]
            msg(source, 'Your Chat-Tag has now been set to:^r ' .. roleList[accessChat[sel]][2])
        else
            msg(source, '^1ERROR: This is not a valid Chat-Tag id')
        end
    end
end)

-- Enable/Disable Chat
chatNotEnabled = {}
RegisterNetEvent('DiscordChatRoles:DisableChat')
AddEventHandler('DiscordChatRoles:DisableChat', function(src)
    chatNotEnabled[src] = true
end)

RegisterNetEvent('DiscordChatRoles:EnableChat')
AddEventHandler('DiscordChatRoles:EnableChat', function(src)
    chatNotEnabled[src] = nil
end)

-- ChatMessage Handler
AddEventHandler('chatMessage', function(source, name, message)
    local args = stringsplit(message)
    CancelEvent()
    local src = source

    -- Staff Chat Block
    if has_value(inStaffChat, GetPlayerIdentifiers(src)[1]) and not string.find(args[1], "/") and not chatNotEnabled[src] then
        local staffMsg = "^7[^1StaffChat^7] ^5(^1" .. name .. "^5) ^9" .. message
        TriggerClientEvent('Permissions:CheckPermsClient', -1, staffMsg)
        return
    end

    -- Regular Discord Chat Roles Processing
    local steamID = GetPlayerIdentifiers(src)[1]
    if not string.find(args[1], "/") and setContains(roleTracker, steamID) and not has_value(inStaffChat, steamID) and not chatNotEnabled[src] then
        local roleNum = roleTracker[steamID]
        local roleStr = roleList[roleNum][2]
        local colors = {'^0','^2','^3','^4','^5','^6','^7','^8','^9'}
        local staffColors = {'^1','^8'}
        local hasColors, hasRed, hasEmoji = false, false, false

        for _, c in ipairs(colors) do if string.match(message, "%" .. c) then hasColors = true end end
        for _, c in ipairs(staffColors) do if string.find(message, "%" .. c) then hasRed = true end end
        for label, val in pairs(emojis) do
            if string.find(message, label) then
                hasEmoji = true
                message = message:gsub(label, val)
            end
        end

        local dontSend = false
        if hasColors and not has_value(allowedColors, roleNum) then
            dontSend = true
            TriggerClientEvent('chatMessage', src, "^7[^1DiscordChatRoles^7] ^1You cannot use colored chat since you are not a donator...")
        end
        if hasRed and not has_value(allowedRed, roleNum) then
            dontSend = true
            TriggerClientEvent('chatMessage', src, "^7[^1DiscordChatRoles^7] ^1You cannot use the color RED in chat since you are not staff...")
        end
        if hasEmoji and not has_value(allowedEmoji, roleNum) then
            dontSend = true
            TriggerClientEvent('chatMessage', src, "^7[^1DiscordChatRoles^7] ^1You cannot use emojis :(")
        end

        local theirColor = chatcolorTracker[src]
        local finalMessage = ""
        if theirColor then
            local indCount = 1
            for j = 1, #message do
                if indCount > #theirColor then indCount = 1 end
                finalMessage = finalMessage .. theirColor[indCount] .. message:sub(j,j)
                indCount = indCount + 1
            end
        else
            finalMessage = message
        end

        if not dontSend then
            if sendBlockMessages then
                sendMsg(roleStr .. name .. "^7: ", finalMessage, -1)
            else
                TriggerClientEvent('chatMessage', -1, roleStr .. name .. "^7: " .. finalMessage)
            end
        end
    end

    -- Discord role detection for new users
    if not setContains(roleTracker, GetPlayerIdentifiers(src)[1]) then
        roleTracker[GetPlayerIdentifiers(src)[1]] = 1
        local identifierDiscord
        for _, v in ipairs(GetPlayerIdentifiers(src)) do
            if string.sub(v, 1, 8) == "discord:" then identifierDiscord = v end
        end

        local roleStr, roleNum = roleList[1][2], 1
        local hasAccess = {roleNum}

        if identifierDiscord then
            local roleIDs = exports.Dead_Discord_API:GetDiscordRoles(src)
            if roleIDs then
                for i = 1, #roleList do
                    for j = 1, #roleIDs do
                        if exports.Dead_Discord_API:CheckEqual(roleList[i][1], roleIDs[j]) and i ~= 1 then
                            roleStr = roleList[i][2]
                            table.insert(hasAccess, i)
                            roleNum = i
                        end
                    end
                end
                roleAccess[GetPlayerIdentifiers(src)[1]] = hasAccess
            else
                print(GetPlayerName(src) .. " has not gotten their permissions cause roleIDs == false")
            end
        end
        roleTracker[GetPlayerIdentifiers(src)[1]] = roleNum
    end
end)

-- Debug Event
RegisterNetEvent('Print:PrintDebug')
AddEventHandler('Print:PrintDebug', function(msg)
    print(msg)
    TriggerClientEvent('chatMessage', source, "^7[^1Dead's Scripts^7] ^1DEBUG ^7" .. msg)
end)

-- Staff Chat Commands
local function handleStaffChatCommand(source, args)
    if IsPlayerAceAllowed(source, "StaffChat.Toggle") then
        if #args == 1 and args[1] == "toggle" then
            TriggerClientEvent('DiscordChatRoles:StaffChat:Toggle', source)
            return
        end
        local steamID = GetPlayerIdentifiers(source)[1]
        if not has_value(inStaffChat, steamID) then
            table.insert(inStaffChat, steamID)
            TriggerClientEvent('chatMessage', source, "^7[^1StaffChat^7] ^5StaffChat has been toggled ^2ON")
        else
            table.remove(inStaffChat, get_index(inStaffChat, steamID))
            TriggerClientEvent('chatMessage', source, "^7[^1StaffChat^7] ^5StaffChat has been toggled ^1OFF")
        end
    end
end

RegisterCommand("staffchat", handleStaffChatCommand)
RegisterCommand("sc", handleStaffChatCommand)

-- Remove players from staff chat on drop
AddEventHandler("playerDropped", function()
    local steamID = GetPlayerIdentifiers(source)[1]
    if has_value(inStaffChat, steamID) then
        table.remove(inStaffChat, get_index(inStaffChat, steamID))
    end
end)

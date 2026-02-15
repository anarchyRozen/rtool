rtool2 = "#0066ffR#ffcc00t#33cc33o#ff6666O#cc0000L #FFFFFF| "
outputChatBox ( "#F5CF27✨ #0066ffReplacement #ff6666Tool#FFFFFF"..versionRtool.. " #ffffff| [#33cc33/rhelp#ffffff]", root, 255, 255, 255, true )
-- outputChatBox (" #FFFFFF↳ [/rhelp]", root, 255, 0, 0, true )

--Mentions (>shared.lua)

math.randomseed(getTickCount())

addEventHandler("onPlayerChat", root, function(msg, msgType)
    if msgType ~= 0 then return end
    local mentionsMap = {}
    local baseColor = "#FFDDB2"

    local coloredMsg = msg:gsub("(@%S+)", function(at)
        local token = at:sub(2)
        if token:lower() == "todos" or token:lower() == "everyone" then
            for _, p in ipairs(getElementsByType("player")) do
                mentionsMap[p] = true
            end
            local rc = string.format("#%06x", math.random(0, 0xFFFFFF))
            return rc .. "@everyone" .. baseColor
        else
            for _, p in ipairs(getElementsByType("player")) do
                local name = getPlayerName(p)
                local cleanName = name:gsub("#%x%x%x%x%x%x", "")
                if cleanName:lower():find(token:lower(), 1, true) then
                    mentionsMap[p] = true
                    local rc = string.format("#%06x", math.random(0, 0xFFFFFF))
                    return rc .. "@" .. cleanName .. baseColor
                end
            end
        end
        return at
    end)

    for _, p in ipairs(getElementsByType("player")) do
        outputChatBox("#FFFFFF" .. getPlayerName(source) .. ": " .. baseColor .. coloredMsg, p, nil, nil, nil, true)
    end

    for p, _ in pairs(mentionsMap) do
        if isElement(p) then
            triggerClientEvent(p, "mentionSound", resourceRoot) -- > shared.lua
        end
    end

    cancelEvent()
end)

--Dynamic FPS Util (<display_c.lua)

addEvent("updateFPSLimit", true)
addEventHandler("updateFPSLimit", root, function(FPSLimit)
	if type(FPSLimit) ~= "number" then outputChatBox("not number "..FPSLimit) return end
	setFPSLimit(FPSLimit)
end)

-- CMD (>cmder.lua)

addEvent("cmdResHandler", true)
addEventHandler("cmdResHandler", root, function(cmdType, resName)
if resName and cmdType ~= nil then
        -- outputChatBox("cmdtype: "..cmdType)
    local resource = getResourceFromName(resName)
        if cmdType == "start" then

            local started = startResource(resource)

            if started then
                outputChatBox(rtool.."Started Resource: #656cf2".. resName, root, 255, 255, 255, true)
                else
                outputChatBox(rtool.."Resource not found: #656cf2".. resName, root, 255, 255, 255, true)
            end
        elseif cmdType == "restart" then

            local restarted = restartResource(resource)

            if restarted then
                outputChatBox(rtool.."Restarted Resource: #656cf2".. resName, root, 255, 255, 255, true)
                else
                outputChatBox(rtool.."Resource not found: #656cf2".. resName, root, 255, 255, 255, true)
            end
        elseif cmdType == "stop" then

            local stop = stopResource(resource)

            if stop then
                outputChatBox(rtool.."Stopped Resource: #656cf2".. resName, root, 255, 255, 255, true)
                else
                outputChatBox(rtool.."Resource not found: #656cf2".. resName, root, 255, 255, 255, true)
            end
        end
    else
        if cmdType == "debug" then
        setPlayerScriptDebugLevel(source, 3)
        end
    end
end)
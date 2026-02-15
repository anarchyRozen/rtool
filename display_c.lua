-- ==========================================================
-- Metrics or Display Xdé
-- ==========================================================

-- g
local screenWidth, screenHeight = guiGetScreenSize() 
local textFont = "default-bold"
local updateInterval = 50 

-- Variables (do not change)
local rainbowColors = {255, 0, 0} 
local rainbowStep = 5 -- Speed of rainbow text
local isVisible = true
local frameCount = 0
local lastTime = getTickCount() 
local currentFPS = 0 

--Dynamic Fps
local LimitTest = 51
local LimitEditor = 100

--LOD
local drawDistance = 325


-- Global variables for /nofix, and /nosref status [MOVED TO SHARED]
--nofixEnabled = false [MOVED TO WARPS]
--nosrefEnabled = false [MOVED TO WARPS] 
-- local variables for metrics stuff /etog, /visfx
local displayEnabled = true
local visualEffectsEnabled = true

function displayUIHandler(command, args)
    if command == "etog" then
        isVisible = not isVisible
        outputChatBox(rtool.."#FFFFFFDisplay: " .. (isVisible and "#33cc33ON" or "#ff6666OFF"), 90, 32, 162, true)
    elseif command == "visfx" then
        visualEffectsEnabled = not visualEffectsEnabled
        outputChatBox(rtool.."#FFFFFFSpeedometer FX: " .. (visualEffectsEnabled and "#33cc33ON" or "#ff6666OFF"), 90, 32, 162, true)
	elseif command == "rlod" then
        if not args or args == "" then
            executeCommandHandler("rlod")
        else
            executeCommandHandler("rlod", unpack(args))
        end
    elseif command == "dynamicfps" then
        executeCommandHandler("dynamicfps")
    end
end


--Rainbow text 
function updateRainbowColor()
    if rainbowColors[1] > 0 and rainbowColors[3] == 0 then
        rainbowColors[1] = math.max(rainbowColors[1] - rainbowStep, 0)
        rainbowColors[2] = math.min(rainbowColors[2] + rainbowStep, 255)
    elseif rainbowColors[2] > 0 and rainbowColors[1] == 0 then
        rainbowColors[2] = math.max(rainbowColors[2] - rainbowStep, 0)
        rainbowColors[3] = math.min(rainbowColors[3] + rainbowStep, 255)
    elseif rainbowColors[3] > 0 and rainbowColors[2] == 0 then
        rainbowColors[3] = math.max(rainbowColors[3] - rainbowStep, 0)
        rainbowColors[1] = math.min(rainbowColors[1] + rainbowStep, 255)
    end
end

--Dynamic FPS (>util_s.lua)

function customFPSDynamic(_, fpsEditor, fpsTest)
    if not fpsTest then
        dynamicFPS = not dynamicFPS
        outputChatBox(rtool.."Dynamic FPS: " ..(dynamicFPS and "#33cc33ON" or "#ff6666OFF"), 90, 32, 162, true)
        if dynamicFPS then
            outputChatBox("  #FFFFFF↳ You can change the values using:", 90, 32, 162, true)
             outputChatBox("    #FFFFFF↳ '/dynamicfps <fpsEditor> <fpsTest>' ", 90, 32, 162, true)
        end
    else
        local editorFPS = tonumber(fpsEditor)
        local testFPS = tonumber(fpsTest)

        if not editorFPS or not testFPS then
            outputChatBox(rtool.."Usage: /dynamicfps <fpsEditor> <fpsTest> ", 90, 32, 162, true)
            return
        end
            LimitEditor = editorFPS 
            LimitTest = testFPS
            outputChatBox(rtool.."Dynamic FPS set to: #ffcc00EDITOR - #33cc33"..LimitEditor.." #ffffff| #ffcc00TEST - #33cc33"..LimitTest, 90, 32, 162, true)
    end
end
addCommandHandler("dynamicfps", customFPSDynamic) 

function editorEvents(resource)
    if not dynamicFPS then return end
	if eventName == "onEditorSuspended" then
        local FPSLimit = tonumber(LimitTest)
        triggerServerEvent("updateFPSLimit", localPlayer, FPSLimit)

	elseif eventName == "onEditorResumed" then
        local FPSLimit = tonumber(LimitEditor)
        triggerServerEvent("updateFPSLimit", localPlayer, FPSLimit)
	end
end

for _,editorEventsList in ipairs({ "onEditorSuspended", "onEditorResumed"}) do
	addEvent(editorEventsList)
	addEventHandler(editorEventsList, root, editorEvents)
end

addEventHandler( "onClientResourceStop", getRootElement( ),
    function ( stoppedRes )
        local resourceName = getResourceName( stoppedRes )
        if resourceName == "editor" then 
            local FPSLimit = LimitTest
            triggerServerEvent("updateFPSLimit", localPlayer, FPSLimit)
    end
end)

-- FPS
function calculateFPS()
    frameCount = frameCount + 1
    local currentTime = getTickCount()
    if currentTime - lastTime >= 1000 then
        currentFPS = frameCount
        frameCount = 0
        lastTime = currentTime
    end
end
addEventHandler("onClientPreRender", root, calculateFPS)

-- FPS COLOR BASED ON LIMIT
function getFPSColor(fps)
    local fpsLimit = getFPSLimit() or 60
    local percentage = math.min(fps / fpsLimit, 1)
    local red = math.min(255, math.max(0, 255 * (1 - percentage)))
    local green = math.min(255, math.max(0, 255 * percentage))
    return tocolor(red, green, 0, 255)
end

-- Outlined text
function drawOutlinedText(text, x, y, color, scale, font, alignX, alignY)
    local outlineColor = tocolor(0, 0, 0, 255)
    dxDrawText(text, x - 1, y - 1, x - 1, y - 1, outlineColor, scale, font, alignX, alignY, false, false, false, true)
    dxDrawText(text, x + 1, y - 1, x + 1, y - 1, outlineColor, scale, font, alignX, alignY, false, false, false, true)
    dxDrawText(text, x - 1, y + 1, x - 1, y + 1, outlineColor, scale, font, alignX, alignY, false, false, false, true)
    dxDrawText(text, x + 1, y + 1, x + 1, y + 1, outlineColor, scale, font, alignX, alignY, false, false, false, true)
    dxDrawText(text, x, y, x, y, color, scale, font, alignX, alignY, false, false, false, true)
end

-- HUD
function drawHUD()
    if not isVisible then return end

    local ping = getPlayerPing(localPlayer)

    local textFPS = tostring(currentFPS) .. " FPS"
    local textPing = tostring(ping) .. " PING"

    local combinedText = textFPS .. " | " .. textPing

    local staticColor = tocolor(255, 255, 255, 255)

    local textWidth = dxGetTextWidth(combinedText, 2, textFont)
    local x = screenWidth - textWidth - 1
    local y = screenHeight - 30

    drawOutlinedText(textFPS, x, y, getFPSColor(currentFPS), 1.5, textFont, "left", "top")
    drawOutlinedText(" | ", x + dxGetTextWidth(textFPS, 1.5, textFont), y, staticColor, 1.5, textFont, "left", "top")
    drawOutlinedText(textPing, x + dxGetTextWidth(textFPS .. " | ", 1.5, textFont), y, getRainbowColor(100), 1.5, textFont, "left", "top")
end

-- Command to toggle HUD 
function toggleHUD()
    isVisible = not isVisible
    --outputChatBox("HUD " .. (isVisible and "enabled" or "disabled") .. ".", 255, 255, 255)
end
addCommandHandler("etog", toggleHUD)

addEventHandler("onClientRender", root, function()
    updateRainbowColor()
    -- calculateFPS()
    drawHUD()
end)


-- ==========================================================
-- Speedometer, HP & Nitro
-- ==========================================================

--again this because I mixed two scripts and cant be bothered to change it
--local sx, sy = guiGetScreenSize()

--[[
addCommandHandler("etog", function()
    displayEnabled = not displayEnabled
	outputChatBox(rtool.."#FFFFFFDisplay: " .. (displayEnabled and "#33cc33ON" or "#ff6666OFF"), 90, 32, 162, true)
    --outputChatBox("Display " .. (displayEnabled and "enabled" or "disabled"), 255, 255, 0)
end)]]

-- bordered text
function drawBorderedText(text, x, y, x2, y2, color, scale, font, alignX, alignY)
    local borderColor = tocolor(0, 0, 0, 255)
    local offsets = {
        {-1, -1}, {-1, 0}, {-1, 1},
        {0, -1},           {0, 1},
        {1, -1}, {1, 0}, {1, 1},
    }
    for _, offset in ipairs(offsets) do
        dxDrawText(text, x + offset[1], y + offset[2], x2 + offset[1], y2 + offset[2], borderColor, scale, font, alignX, alignY)
    end
    dxDrawText(text, x, y, x2, y2, color, scale, font, alignX, alignY)
end

-- function getRainbowColor(speed)
--     local tick = getTickCount() / 1000
--     local frequency = (speed or 50) / 115 * 2 -- de 0 a 5Hz
--     local r = math.sin(tick * frequency * 2 * math.pi) * 127 + 128
--     local g = math.sin(tick * frequency * 2 * math.pi + 2 * math.pi / 3) * 127 + 128
--     local b = math.sin(tick * frequency * 2 * math.pi + 4 * math.pi / 3) * 127 + 128
--     return tocolor(r, g, b, 255)
-- end

--crazy

-- Comando para alternar los efectos visuales
addCommandHandler("visfx", function()
    visualEffectsEnabled = not visualEffectsEnabled
	outputChatBox(rtool.."#FFFFFFSpeedometer FX: " .. (visualEffectsEnabled and "#33cc33ON" or "#ff6666OFF"), 90, 32, 162, true)
end)

function getRainbowColor(speed)
    local tick = getTickCount() / 1000
    local minSpeed, maxSpeed = 450, 500
    local clamped = math.max(0, math.min(1, (speed - minSpeed) / (maxSpeed - minSpeed)))
    local frequency = 0.02 + clamped * 9  -- de 1 Hz a 10 Hz

    local r = math.sin(tick * frequency * 2 * math.pi) * 127 + 128
    local g = math.sin(tick * frequency * 2 * math.pi + 2 * math.pi / 3) * 127 + 128
    local b = math.sin(tick * frequency * 2 * math.pi + 4 * math.pi / 3) * 127 + 128
    return tocolor(r, g, b, 255)
end

addEventHandler("onClientRender", root, function()
    if not isVisible then return end

    local player = getLocalPlayer()
    local vehicle = getPedOccupiedVehicle(player)

    if vehicle then
        local vx, vy, vz = getElementVelocity(vehicle)
        local speed = math.sqrt(vx^2 + vy^2 + vz^2) * 180

        -- dynamic height 
        local baseFontSize = 1.5
        local maxFontSize = 3.0
        local fontScale = baseFontSize + ((math.min(speed, 230) / 230) * (maxFontSize - baseFontSize))

        local baseYOffset = 20
        local dynamicHeight = fontScale * 20  
        local yOffset = baseYOffset + dynamicHeight + 5  -- 5px de espacio

        local shakeX, shakeY = 0, 0
        if visualEffectsEnabled and speed >= 100 then
            local shake = ((math.min(speed, 230) - 100) / 130) * 5
            shakeX = math.random(-shake, shake)
            shakeY = math.random(-shake, shake)
        end

        local numberColor = visualEffectsEnabled and getRainbowColor(speed) or tocolor(255, 255, 255, 255)

        -- 
        local speedText = string.format("%.0f", speed)
        drawBorderedText(speedText, sx - 120 + shakeX, baseYOffset + shakeY, sx - 20 + shakeX, baseYOffset + 20 + shakeY, numberColor, fontScale, "default-bold", "right", "top")

        --
        dxDrawText(" km/h", sx - 120, baseYOffset + dynamicHeight - 10, sx - 20, baseYOffset + dynamicHeight + 10, tocolor(255,255,255,255), 1.5, "default-bold", "right", "top", false, false, false, true)

        local health = getElementHealth(vehicle)
        local healthPercent = math.max(0, math.min(100, (health - 250) / 7.5))
        local r = math.min(255, 255 * (1 - healthPercent / 100))
        local g = math.min(255, 255 * (healthPercent / 100))
        local healthText = string.format("%.0f%%", healthPercent)
        if nofixEnabled then
            healthText = healthText .. " ✔"
        end
        drawBorderedText(healthText, sx - 120, yOffset + 15, sx - 20, yOffset + 20, tocolor(r, g, 0, 255), 1.5, "default-bold", "right")

        local nitro = getVehicleNitroLevel(vehicle)
        if nitro then
            local nitroPercent = nitro * 100
            local b = math.min(150, 255 * (nitroPercent / 100))
            local w = math.min(255, 255 * (1 - nitroPercent / 100))
            local nitroText = string.format("%.0f%%", nitroPercent)
            if nosrefEnabled then
                nitroText = nitroText .. " ✔"
            end
            drawBorderedText(nitroText, sx - 120, yOffset + 40, sx - 20, yOffset + 50, tocolor(255 - b, 255 - b, 255, 255), 1.5, "default-bold", "right")
        end
    end
end)

--setTimer(outputChatBox, 50, 1, "#321654Use #ffffff/rlod [1-300] #321654to refresh objects draw distance!", 255, 125, 0, true)

--Draw distance / LOD

addCommandHandler("rlod",
function(command, arg1)
    drawDistance = tonumber(arg1) or 325

    if drawDistance < 1 then drawDistance = 1 end
    -- if drawDistance > 300 then drawDistance = 300 end

    outputChatBox(rtool.."#FFFFFFObjects draw distance successfully changed to #33cc33" .. drawDistance .. "#FFFFFF!", 90, 32, 162, true)

    for _, object in ipairs(getElementsByType("object")) do
        if isElement(object) then
            local objectID = getElementModel(object)
            engineSetModelLODDistance(objectID, drawDistance)
        end
    end
end)

function objectDynamicLOD()
    if getElementType(source) == "object" then
        local newObjectID = getElementModel(source)
        local currentLOD = engineGetModelLODDistance(newObjectID)
        if currentLOD ~= drawDistance then
            -- outputChatBox("Added lod "..newObjectID)
            engineSetModelLODDistance(newObjectID, drawDistance)
        end
    end
end
addEventHandler("onElementCreate", root, objectDynamicLOD)

--Universal interface

addEventHandler("onClientResourceStart", resourceRoot, function()
    if type(registerUIModule) == "function" then
        registerUIModule("Display", {
            color = tocolor(155, 91, 217, 255),
            options = {
                {label = "Toggle Speed Visual FX", command = "visfx"},
				{label = "Toggle HUD", command = "etog"},
				{label = "Toggle Dynamic FPS", command = "dynamicfps"},
                {label = "rlod", command = "rlod", hideUI = true, args = true},
            },
            callback = function(command, args)
                displayUIHandler(command, args)
            end
        })
    end
end)

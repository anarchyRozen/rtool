local modules, moduleOrder, recentInput = {}, {}, {}
local currentModuleIndex, optionIndex, maxRecents = 1, 1, 10
local inputBuffer = ""
local typingMode, moduleSelectMode, uiReady = false, false, false
--local univUI = false -- global variable now

local uiKeys = {
    toggleMenu = "g",   --double click
    closeMenu = "tab",
    nextOption = "mouse_wheel_down",
    prevOption = "mouse_wheel_up",
	nextOptionAlt = "lctrl",
	prevOptionAlt = "lalt",
    confirm = "space",
	confirmAlt = "mouse1",
    switchModule = "lshift",
    switchModuleAlt = "mouse2",
    prevInput = "mouse4",
    prevInputAlt = "arrow_r"
}

local doublePressThreshold = 300
local lastTogglePress = 0

local sx, sy = guiGetScreenSize()
local maxVisible = 9
local scrollOffset = 0
local targetScrollOffset = 0
local animationSpeed = 0.15
local lastTick = getTickCount()

-- ========================
-- Registro
-- ========================

function validateModule(name)
    local mod = modules[name]
    if not mod then return false end
    if type(mod.options) ~= "table" or #mod.options == 0 then return false end
    if mod.callback and type(mod.callback) ~= "function" then return false end
    if mod.resource and getResourceState(mod.resource) ~= "running" then return false end
    return true
end

function registerUIModule(name, def)
    if not def or type(def.options) ~= "table" then
        outputDebugString("[RtoOL] Error loading module: "..tostring(name))
        return
    end
    modules[name] = def
    rebuildUIModules()
    outputDebugString("[RtoOL] Module loaded: "..name)
end

function rebuildUIModules()
    moduleOrder = {}

    for name in pairs(modules) do
        if validateModule(name) then
            table.insert(moduleOrder, name)
        else
            modules[name] = nil
            table.remove(moduleOrder, name)
            outputDebugString("[RtoOL] Module removed: "..name)
        end
    end

    if currentModuleIndex > #moduleOrder then
        currentModuleIndex = 1
    end
end

addEventHandler("onClientResourceStop", root, function()
    rebuildUIModules()
end)

-- ========================
-- Util
-- ========================

function pushRecentInput(moduleName, value)
    if value == "" then return end

    recentInput[moduleName] = recentInput[moduleName] or { list = {}, index = 0 }
    local data = recentInput[moduleName]

    -- evitar duplicar consecutivos
    if data.list[1] == value then return end

    table.insert(data.list, 1, value)

    if #data.list > maxRecents then
        table.remove(data.list)
    end

    data.index = 0
end

function getNextRecentInput(moduleName)
    local data = recentInput[moduleName]
    if not data or #data.list == 0 then return nil end
    return data.list[(data.index % #data.list) + 1]
end

-- ========================
-- Navegacion
-- ========================

addEventHandler("onClientKey", root, function(button, press)
    if not univUI then return end
    for _, key in pairs(uiKeys) do
        if button == key then return end
    end
    if button == "backspace" then return end
    cancelEvent()
end)


addEventHandler("onClientCharacter", root, function(char)
    if not univUI or not typingMode then return end
    inputBuffer = inputBuffer .. char
end)

bindKey("backspace", "down", function()
    if not univUI or not typingMode then return end
    inputBuffer = inputBuffer:sub(1, -2)
end)

function confirmHandler()
    if not univUI then return end
    local moduleName = moduleOrder[currentModuleIndex]
    local data = recentInput[moduleName]
    local mod = modules[moduleName]
    if not mod then return end
    local opt = mod.options[optionIndex]
    if not opt then return end

    -- outputDebugString("callback type: "..type(mod.callback))
    if type(mod.callback) == "function" then
        if opt.args then
            -- TO DO: permitir múltiples argumentos separados por espacios
            local args = {}
            for word in inputBuffer:gmatch("%S+") do
                table.insert(args, word)
            end
            mod.callback(opt.command, args)
        else
            mod.callback(opt.command, nil)
        end
    else -- Si no existe callback, tratar como modulo externo usando eventos.
        local args = {}
            for word in inputBuffer:gmatch("%S+") do
                table.insert(args, word)
            end
        triggerEvent("externalModule", root, moduleName, opt.command, args)
    end

    if opt.hideUI then
        univUI = false
    end

    local usedInput = inputBuffer
    if usedInput ~= "" then
        pushRecentInput(moduleName, usedInput)
    end

    -- data.index = 0
    typingMode = false
    inputBuffer = ""
end
bindKey(uiKeys.confirm, "down", confirmHandler)
bindKey(uiKeys.confirmAlt, "down", confirmHandler)
addEvent("externalModule", true)


function nextOptionHandler()
    if not univUI then return end
    local mod = modules[moduleOrder[currentModuleIndex]]
    if not mod then return end
    local listSize = moduleSelectMode and #moduleOrder or #mod.options
    optionIndex = optionIndex % listSize + 1
    -- optionIndex = optionIndex % #mod.options + 1
    if recentInput[moduleName] then
        recentInput[moduleName].index = 0
    end
    inputBuffer = ""
end
bindKey(uiKeys.nextOption, "down", nextOptionHandler)
bindKey(uiKeys.nextOptionAlt, "down", nextOptionHandler)

function prevOptionHandler()
    if not univUI then return end
    local mod = modules[moduleOrder[currentModuleIndex]]
    if not mod then return end
    local listSize = moduleSelectMode and #moduleOrder or #mod.options
    optionIndex = (optionIndex - 2) % listSize + 1
    -- optionIndex = (optionIndex - 2) % #mod.options + 1
    if recentInput[moduleName] then
        recentInput[moduleName].index = 0
    end
    inputBuffer = ""
end
bindKey(uiKeys.prevOption, "down", prevOptionHandler)
bindKey(uiKeys.prevOptionAlt, "down", prevOptionHandler)

bindKey(uiKeys.switchModule, "down", function()
    if not univUI then return end
    local current = currentModuleIndex
    currentModuleIndex = currentModuleIndex % #moduleOrder + 1
    moduleTimer = setTimer ( function()
        if getKeyState(uiKeys.switchModule) then
		    -- outputChatBox ( "5 second delay text!" )
            currentModuleIndex = current
            moduleSelectMode = true
            optionIndex = currentModuleIndex
        end
	end, 300, 1 )
    optionIndex = 1
end)

bindKey(uiKeys.switchModule, "up", function()
    if not univUI then return end
    if isTimer ( moduleTimer ) then killTimer ( moduleTimer ) end
        if moduleSelectMode then
            currentModuleIndex = optionIndex
            optionIndex = 1
        end
    moduleSelectMode = false
end)


bindKey(uiKeys.switchModuleAlt, "down", function()
    if not univUI then return end
    currentModuleIndex = (currentModuleIndex - 2) % #moduleOrder + 1
    -- currentModuleIndex = currentModuleIndex % #moduleOrder - 1
    optionIndex = 1
end)

bindKey(uiKeys.closeMenu, "down", function()
    if univUI then
        univUI = false
        typingMode = false
        inputBuffer = ""
    end
end)

-- Doble click para abrir
bindKey(uiKeys.toggleMenu, "down", function()
    local now = getTickCount()
    if now - lastTogglePress < doublePressThreshold then
        if not univUI then univUI = true end
        -- optionIndex = 1
        typingMode = false
        inputBuffer = ""
    end
    lastTogglePress = now
end)

function previewRecent()
    if not univUI or not typingMode then return end

    local moduleName = moduleOrder[currentModuleIndex]
    local data = recentInput[moduleName]
    if not data or #data.list == 0 then return end

    data.index = data.index + 1
    if data.index > #data.list then
        data.index = 1
    end

    inputBuffer = data.list[data.index]
end
bindKey(uiKeys.prevInput, "down", previewRecent)
bindKey(uiKeys.prevInputAlt, "down", previewRecent)


local function drawOutlinedText(text, x, y, w, h, color, scale, font, alignX, alignY)
    local shadowColor = tocolor(0, 0, 0, 255)
    dxDrawText(text, x-1, y-1, w-1, h-1, shadowColor, scale, font, alignX, alignY)
    dxDrawText(text, x+1, y-1, w+1, h-1, shadowColor, scale, font, alignX, alignY)
    dxDrawText(text, x-1, y+1, w-1, h+1, shadowColor, scale, font, alignX, alignY)
    dxDrawText(text, x+1, y+1, w+1, h+1, shadowColor, scale, font, alignX, alignY)
    dxDrawText(text, x, y, w, h, color, scale, font, alignX, alignY)
end

-- ========================
-- Interfaz
-- ========================
local refX, refY = 2560, 1440

addEventHandler("onClientRender", root, function()
    if not univUI then return end

    local moduleName = moduleOrder[currentModuleIndex]
    local mod = modules[moduleName]
    if not mod then return end
    
    local sx, sy = guiGetScreenSize()
    local scaleX, scaleY = sx / refX, sy / refY
    local globalScale = math.min(scaleX, scaleY)
    
    -- Posiciones / tamaños escalados
    local baseX, baseY = sx * 0.50, sy * 0.55
    local lineHeight = 35 * globalScale
    local scale = 2.4 * globalScale
    
    local half = math.floor(maxVisible / 2)
    targetScrollOffset = (optionIndex - 1) * lineHeight
    
    local list = moduleSelectMode and moduleOrder or mod.options
    local currentTick = getTickCount()
    local deltaTime = (currentTick - lastTick) / 1000.0
    lastTick = currentTick
    scrollOffset = scrollOffset + (targetScrollOffset - scrollOffset) * animationSpeed * deltaTime * 120


    if moduleSelectMode then
        drawOutlinedText("[SELECT]", baseX - (100 * scaleX), baseY-(160 * scaleY), baseX - (20 * scaleX), baseY, tocolor(255,255,255,255), 1.5 * globalScale, "pricedown", "right", "top")
    else
        drawOutlinedText(currentModuleIndex.."/"..#moduleOrder, baseX + (300 * scaleX), baseY-(200 * scaleY), baseX - (20 * scaleX), baseY,tocolor(204, 204, 204,255), 1.5 * globalScale, "pricedown", "right", "top")
        drawOutlinedText("["..moduleName.."]", baseX - (100 * scaleX), baseY-(160 * scaleY), baseX - (20 * scaleX), baseY, mod.color or tocolor(255,255,255,255), 1.5 * globalScale, "pricedown", "right", "top")
    end
    dxDrawText("CHANGE MODULE: "..string.upper(uiKeys.switchModule), baseX - (250 * scaleX), baseY-(110 * scaleY), baseX+(400 * scaleX), baseY, tocolor(255,255,255,150), 1.5 * globalScale, "default", "left", "top")
    dxDrawText(string.upper(uiKeys.nextOptionAlt).."▼ / ▲"..string.upper(uiKeys.prevOptionAlt).." | MOUSE WHEEL", baseX - (325 * scaleX), baseY-(90 * scaleY), baseX+(400 * scaleX), baseY, tocolor(255,255,255,150), 1.5 * globalScale, "default", "left", "top")
    dxDrawText("CONFIRM: "..string.upper(uiKeys.confirm).." / "..string.upper(uiKeys.confirmAlt), baseX - (260 * scaleX), baseY-(70 * scaleY), baseX+(400 * scaleX), baseY, tocolor(255,255,255,150), 1.5 * globalScale, "default", "left", "top")
    dxDrawText("CLOSE: "..string.upper(uiKeys.closeMenu), baseX - (130 * scaleX), baseY-(50 * scaleY), baseX+(400 * scaleX), baseY, tocolor(255,255,255,150), 1.5 * globalScale, "default", "left", "top")
    if moduleSelectMode then
        for i, name in ipairs(moduleOrder) do
            local y = baseY + ((i - optionIndex) * lineHeight) - (scrollOffset % lineHeight)
            if y > sy*0.1 and y < sy*0.9 then
                local color = (i == optionIndex) and tocolor(255,255,255,255) or tocolor(200,200,200,180)
                
                drawOutlinedText(name, baseX, y - (300 * scaleY), baseX + (300 * scaleX), y + lineHeight, color, scale, "default-bold", "left", "center")
            end
        end

    else
        for i, opt in ipairs(mod.options) do
            local y = baseY + ((i - optionIndex) * lineHeight) - (scrollOffset % lineHeight)
            if y > sy*0.1 and y < sy*0.9 then
                local color = (i == optionIndex) and (mod.color or tocolor(255,255,255,255)) or tocolor(200,200,200,180)

                local label = opt.label
                local preview = nil

                if opt.args and i == optionIndex then
                    typingMode = true

                    local moduleName = moduleOrder[currentModuleIndex]
                    local data = recentInput[moduleName]
                    
                    if data then
                        preview = getNextRecentInput(moduleName)
                    end
                    
                    if inputBuffer ~= "" then
                        label = label .. ": " .. inputBuffer
                    else
                        label = label .. ": _"
                    end
                end

                drawOutlinedText(label, baseX, y - (300 * scaleY), baseX, y + lineHeight, color, scale, "default-bold", "left", "center")
                -- drawOutlinedText(label.. (preview and " ->"..preview or ""), baseX, y - (300 * scaleY), baseX, y + lineHeight, color, scale, "default-bold", "left", "center")
                
                if preview then
                    local w = dxGetTextWidth(label, scale, "default-bold")
                    dxDrawText("(>  " .. preview .. ")", baseX + w + (10*scaleX), y - (300 * scaleY), baseX + w + (800 * scaleX), y + lineHeight, tocolor(255, 255, 255, 150), scale * 0.9, "default", "left", "center")
                end
            end
        end
    end
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    uiReady = true
end)

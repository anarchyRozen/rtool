--Keys
--local KEY_RECORD = "c"

local isVisible = false
local isRunning = false
local isPaused = false
local startTime = 0
local elapsedTime = 0
local mode = true -- true: auto, false: manual (default)
local keyPressTime = 0
local doublePressThreshold = 300
local lastCPress = 0

local pendingInjectedTime = nil

sx, sy = guiGetScreenSize()

local timeMarkers = {} -- {element=markerElement, label="00:10:00", timeMs=10000}
local tdsEnabled = false
local tdsInterval = 20000 

local xmlFilePath = "usertool.xml"
-- local xmlRootNode

addEventHandler("onClientResourceStart", resourceRoot, function()
    if type(registerUIModule) == "function" then
        registerUIModule("Khronos", {
            color = tocolor(51, 204, 51, 255),
            options = {
				{label = "Toggle Khronos", command = "toggle"},
				{label = "Record Time", command = "recordc", hideUI = true},
				{label = "Toggle Time Displays", command = "tds"},
				{label = "List Saved Markers", command = "clist"},
				{label = "Load Time Markers", command = "load", args = true, hideUI = true},
                {label = "Save Time Markers", command = "save", args = true, hideUI = true},
                {label = "Switch Mode", command = "mode"},
                {label = "Clear Displays", command = "tds_clear"},
                {label = "Set Display Interval (e.g. 1m, 30s)", command = "tds_interval", args = true},
                {label = "Inject time (e.g. 1m30s)", command = "croti", args = true},
                {label = "Restart Timer", command = "restart"},
            },
            callback = chronoUIHandler
        })
    else
        outputDebugString("[chrono_c] Error: registerUIModule no disponible")
    end
end)


--SAVE / LOAD TIMES 
local timesNode

function initChronosXML()
    local _, group = loadUsertoolGroup("times")
    timesNode = group
end
addEventHandler("onClientResourceStart", resourceRoot, initChronosXML)

function chronoUIHandler(command, args)
    if command == "restart" then
        resetTimer()
		
	elseif command == "recordc" then
		startTimer()

	elseif command == "clist" then
		listTimes()

    elseif command == "save" then
        ensureXML()
        local name = args and args[1] or ""
        if name == "" then
            outputChatBox(rtool.."Usage: save [name]", 200,200,255,true)
        elseif tostring(name):find("^%d") then
            outputChatBox(rtool.."#FF0000ERROR! #FFFFFFTimes name cannot start with a number", 255, 100, 100, true)
        else
            savetimeDs(name)
        end

    elseif command == "load" then
        ensureXML()
        local name = args and args[1] or ""
        if name == "" then
            outputChatBox(rtool.."Usage: load [name]", 200,200,255,true)
        else
            loadTimeDs(name)
        end

    elseif command == "mode" then
        mode = not mode
        outputChatBox(rtool.."Mode "..(mode and "#33cc33MANUAL" or "#33cc33AUTO"), 200,200,255,true)

    elseif command == "toggle" then
             isVisible = not isVisible
    outputChatBox(rtool.."Khronos "..(isVisible and "#33cc33ON" or "#ff6666OFF"), 200,200,255,true)

    elseif command == "tds" then
        tdsEnabled = not tdsEnabled
        outputChatBox(rtool.."Time displays "..(tdsEnabled and "#33cc33ON" or "#ff6666OFF"), 200,200,255,true)

    elseif command == "tds_clear" then
        clearAllMarkers()
        outputChatBox(rtool.."All time displays cleared", 200,200,255,true)
    elseif command =="croti" then
        local timeStr = args[1]
        timeInject(_, timeStr)
    elseif command == "tds_interval" then
        local raw = args and args[1] or ""
        if raw == "" then
            outputChatBox(rtool.."Usage: interval [1m/30s/500ms]", 200,200,255,true)
            return
        end
        local num = tonumber(raw:match("%d+"))
        if not num then
            outputChatBox(rtool.."Invalid value. Example: 30s, 1m, 500ms", 200,200,255,true)
            return
        end
        if raw:find("m") then
            tdsInterval = num * 60000
        elseif raw:find("s") then
            tdsInterval = num * 1000
        elseif raw:find("ms") then
            tdsInterval = num
        end
        outputChatBox(rtool.."Marker interval set to #33cc33"..raw, 200,200,255,true)
    end
end


bindKey("w", "down", 
	function() 
	if univUI then return end
		if not mode then startTimer() 
	end 
end)
bindKey("s", "down", 
	function() 
	if univUI then return end
		if not mode then startTimer() 
	end 
end)

local refX, refY = 2560, 1440
addEventHandler("onClientRender", root, function()
    local screenW, screenH = guiGetScreenSize()
    local scaleX, scaleY = screenW / refX, screenH / refY
    local globalScale = math.min(scaleX, scaleY)

    if tdsEnabled then
        for _, marker in ipairs(timeMarkers) do
            if isElement(marker.element) then
                local x, y, z = getElementPosition(marker.element)
                local sx, sy = getScreenFromWorldPosition(x, y, z + 0.75, 0.05)
                if sx and sy then
                    local text = "⏱ " .. marker.label
                    dxDrawText(text, sx+1, sy+1, sx+1, sy+1, tocolor(0,0,0,255), 2.2 * globalScale, "default-bold", "center", "bottom")
                    dxDrawText(text, sx, sy, sx, sy, tocolor(255,255,255,255), 2.2 * globalScale, "default-bold", "center", "bottom")
                end
            end
        end
    end

    if isVisible and isPedInVehicle(localPlayer) then
        local currentTime = getTickCount()
        if isRunning and not isPaused then
            if isRewinding then
                -- Ajustar velocidad
                local steps = getKeyState("q") and fastRewindSpeed or rewindSpeed
                local delta = (currentTime - keyPressTime) * steps
                elapsedTime = math.max(0, elapsedTime - delta)
                removeMarkersAfter(elapsedTime)
            else
                elapsedTime = elapsedTime + (currentTime - keyPressTime)
            end
            keyPressTime = currentTime
        end

        local ms = string.format("%03d", elapsedTime % 1000)
        local totalSeconds = math.floor(elapsedTime / 1000)
        local minutes = string.format("%02d", math.floor(totalSeconds / 60))
        local seconds = string.format("%02d", totalSeconds % 60)
        local timeString = minutes .. ":" .. seconds .. ":" .. string.sub(ms, 1, 2)

        local posX = screenW * 0.92
        local posY = screenH * 0.20

        if isPaused then
            dxDrawText("▐▐", posX - (100 * scaleX), posY, nil, nil, tocolor(255, 255, 255, 220), 3.5 * globalScale, "default-bold")
        end
        if isRewinding and not isPaused then
            dxDrawText("◀ ◀", posX - (100 * scaleX), posY, nil, nil, tocolor(255, 255, 255, 220), 3.5 * globalScale, "default-bold")
        end

        dxDrawText(timeString, posX, posY, nil, nil, tocolor(255, 255, 255, 255), 3.5 * globalScale, "default-bold")
    end
end)



function startTimer()
    if not isRunning then
        isRunning = true
        isPaused = false
		clearAllMarkers()
        keyPressTime = getTickCount()
        if pendingInjectedTime then
            elapsedTime = pendingInjectedTime
            pendingInjectedTime = nil
        end
    end
end

function togglePauseOrRestart()
    if not isVisible or not isPedInVehicle(localPlayer) then return end
    local now = getTickCount()
    if now - lastCPress < doublePressThreshold then
        resetTimer()
        return
    end
    lastCPress = now

    if isRunning then
        isPaused = not isPaused
        if not isPaused then
            keyPressTime = getTickCount()
        end
    else
        startTimer()
    end
end
bindKey(KEY_RECORD, "down", togglePauseOrRestart)

function resetTimer()
    if elapsedTime > 1000 then
        local ms = string.format("%03d", elapsedTime % 1000)
        local totalSeconds = math.floor(elapsedTime / 1000)
        local minutes = string.format("%02d", math.floor(totalSeconds / 60))
        local seconds = string.format("%02d", totalSeconds % 60)
        local lastTimeStr = minutes .. ":" .. seconds .. ":" .. string.sub(ms, 1, 2)
        outputChatBox(rtool.."Last time: #33cc33" .. lastTimeStr, 200, 200, 255, true)
    end
    elapsedTime = 0
    isRunning = false
    isPaused = false
    --clearAllMarkers()
end

local rewindOffset = 5.0 -- tolerancia para borrar markers en rewind

function tryCreateTimeMarker()
    if not isVisible or not isPedInVehicle(localPlayer) then return end
    if not isRunning or isPaused then return end

    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh then return end
    local x,y,z = getElementPosition(veh)

    if isRewinding then
        for i = #timeMarkers, 1, -1 do
            local m = timeMarkers[i]
            if isElement(m.element) then
                local mx,my,mz = getElementPosition(m.element)
                local dx,dy,dz = x-mx, y-my, z-mz
                if dx*dx + dy*dy + dz*dz <= rewindOffset*rewindOffset then
                    destroyElement(m.element)
                    table.remove(timeMarkers, i)
                    break 
                end
            end
        end
        return
    end

    -- normal no rewind
    local currentMultiple = math.floor(elapsedTime / tdsInterval)
    local exists = false
    for _, m in ipairs(timeMarkers) do
        if math.floor(m.timeMs / tdsInterval) == currentMultiple then
            exists = true
            break
        end
    end

    if not exists and elapsedTime >= (currentMultiple * tdsInterval) then
        local exactTime = currentMultiple * tdsInterval
        local ms = string.format("%03d", exactTime % 1000)
        local totalSeconds = math.floor(exactTime / 1000)
        local minutes = string.format("%02d", math.floor(totalSeconds / 60))
        local seconds = string.format("%02d", totalSeconds % 60)
        local timeLabel = minutes .. ":" .. seconds .. ":" .. string.sub(ms, 1, 2)

        local marker = createMarker(x, y, z - 1, "corona", 0, 0, 0, 0)
        table.insert(timeMarkers, {element = marker, label = timeLabel, timeMs = exactTime})
    end
end
addEventHandler("onClientRender", root, tryCreateTimeMarker)
--setTimer(tryCreateTimeMarker, 50, 0)

function removeMarkersAfter(timeMs)
    for i = #timeMarkers, 1, -1 do
        if timeMarkers[i].timeMs > timeMs then
            if isElement(timeMarkers[i].element) then
                destroyElement(timeMarkers[i].element)
            end
            table.remove(timeMarkers, i)
        end
    end
end


function clearAllMarkers()
    for _, marker in ipairs(timeMarkers) do
        if isElement(marker.element) then destroyElement(marker.element) end
    end
    timeMarkers = {}
end

function savetimeDs(name)
    if not name or name == "" then
        outputChatBox(rtool.."Usage: /cro save [name]",255,255,255,true)
        return
    end

    initChronosXML()

    local old = xmlFindChild(timesNode, name, 0)
    if old then xmlDestroyNode(old) end

    local node = xmlCreateChild(timesNode, name)

    for _, m in ipairs(timeMarkers) do
        local e = xmlCreateChild(node, "marker")
        xmlNodeSetAttribute(e, "time", m.timeMs)
        local x, y, z = getElementPosition(m.element)
        xmlNodeSetAttribute(e, "x", x)
        xmlNodeSetAttribute(e, "y", y)
        xmlNodeSetAttribute(e, "z", z)
        xmlNodeSetAttribute(e, "label", m.label)
    end

    xmlSaveFile(ensureUsertoolRoot())
end


function loadTimeDs(name)
    initChronosXML()

    local node = xmlFindChild(timesNode, name, 0)
    if not node then
        outputChatBox(rtool.."No data for '"..name.."'",255,150,150,true)
        return
    end

    clearAllMarkers()
    timeMarkers = {}

    for _, c in ipairs(xmlNodeGetChildren(node)) do
        if xmlNodeGetName(c) == "marker" then
            local x = tonumber(xmlNodeGetAttribute(c,"x"))
            local y = tonumber(xmlNodeGetAttribute(c,"y"))
            local z = tonumber(xmlNodeGetAttribute(c,"z"))
            local t = tonumber(xmlNodeGetAttribute(c,"time"))
            local label = xmlNodeGetAttribute(c,"label")

            local marker = createMarker(x, y, z - 1, "corona", 0, 0, 0, 0)
            table.insert(timeMarkers, {element=marker, label=label, timeMs=t})
        end
    end
end


-- Inject time
function timeInject(_, timeStr)
    if not timeStr then
        outputChatBox(rtool.."Usage: /croti 2m10s05ms", 200, 200, 255, true)
        return
    end
    local m = tonumber(timeStr:match("(%d+)m") or 0)
    local s = tonumber(timeStr:match("(%d+)s") or 0)
    local ms = tonumber(timeStr:match("(%d+)ms") or 0)

    if s >= 60 or ms >= 100 then
        outputChatBox(rtool.."Invalid time: seconds < 60, ms < 100", 200, 200, 255, true)
        return
    end

    local newTime = (m * 60000) + (s * 1000) + (ms * 10)
    if isRunning then
        elapsedTime = newTime
        keyPressTime = getTickCount()
        outputChatBox(rtool.."Time updated while running", 200, 200, 255, true)
    else
        pendingInjectedTime = newTime
        outputChatBox(rtool.."Time set, will apply on start", 200, 200, 255, true)
    end
end
addCommandHandler("croti", timeInject)

function listTimes()
	ensureXML()
    if not timesNode then 
        outputChatBox(rtool.."#FF0000 ERROR: #FFFFFFNo markers save file loaded", 115, 46, 255, true)
        return 
    end

    local lists = xmlNodeGetChildren(timesNode)
    if #lists == 0 then
        outputChatBox(rtool.."#FFFFFFNo saved markers found.", 115, 46, 255, true)
        return
    end

    outputChatBox(rtool.."#FFFFFFTime markers found ("..#lists.."):", 115, 46, 255, true)
    for i, listNode in ipairs(lists) do
        local listName = xmlNodeGetName(listNode)
        local count = #xmlNodeGetChildren(listNode)
        outputChatBox(i..". #33cc33"..listName.."#FFFFFF - "..count.." Markers", 0, 102, 255, true)
    end
end
addCommandHandler("clist", listTimes)

addCommandHandler("cmds", function(_, arg)
    if arg ~= "kro" then return end
       outputChatBox("----------Khronos----------", 255, 255, 255, true)
    local function help(msg)
        outputChatBox(rtool.."#FFFFFF" .. msg, 90, 32, 162, true)
    end
    help("[ /cro ] - Toggle Khronos")
	help("[ /cro manual] #9991A2Toggle Manual Mode #33cc33(DEFAULT)")
	help("[ C ] #9991A2Start on Manual Mode")
    help("[ /cro auto ] #9991A2Toggle Auto start mode")
	help("[ W/S ] #9991A2Start on Auto mode")
	help("[ /cro restart ] #9991A2Restart timer")
	help("[ C (twice) ] #9991A2Restart timer")
	help("[ /croti [m/s/ms] ] #9991A2Inject Start Time")
	help("[ /crotds ] #9991A2Toggle 3D times")
	help("[ /crotds [m/s/ms] ] #9991A2Set marker interval")
	help("[ /crotds clear ] #9991A2Clear all time markers")
	help("[ /crosave [name] ] #9991A2Save times")
	help("[ /croload [name] ] #9991A2Load times")
	
	
end)
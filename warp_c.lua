--[[ KEYS
local keyShowList = "lshift"
local keyUp = "arrow_u"
local keyDown = "arrow_d"
local KEY_REWIND = "backspace"
local KEY_FAST_REWIND = "q"

local SAVEWARP_KEY = "4"
local SAVEWARP_CMD = "sw"

local LOADWARP_KEY = "5"
local LOADWARP_CMD = "lw"

local DELETEWARP_KEY = "3"
local DELETEWARP_CMD = "dw"
]]

-- WARP VARIABLES
local warps = {}
local selectedWarp = nil
local localSerial = getPlayerSerial(localPlayer)
local showAll = false
local previewing = false
local hudMode = 1 -- 1 = Always Visible, 2 = Dynamic, 3 = Disabled
local visiblePrev = true

-- local warpSaveFileName = "usertool.xml"
-- local warpSaveFilePath = warpSaveFileName
-- local warpSaveRoot

-- REWIND VARIABLES AND SETTINGS
local recData = {}
--local isRewinding = false --Moved as a global variable
--local rewindSpeed = 1     --Same
--local fastRewindSpeed = 4 --Same
local recordingMode = false --This is made for when I record with TAS, so the rewind features don't overlap but don't mind it if you dont use TAS.


local warpSaveRoot

function initWarpSaveFile()
    local _, group = loadUsertoolGroup("warps")
    warpSaveRoot = group
end

addEventHandler("onClientResourceStart", resourceRoot, initWarpSaveFile)

addEventHandler("onClientResourceStart", resourceRoot, function()
    if type(registerUIModule) == "function" then
        registerUIModule("Warps", {
            color = tocolor(0, 134, 230, 255), -- Naranja
            options = {
                {label = "Toggle Auto-Repair", command = "nofix", hideUI = true},
                {label = "Toggle Unlimited Nitro", command = "nosref", hideUI = true},
                {label = "List Warps", command = "wlist", args = true},
                {label = "Load Warps", command = "wl", args = true},
                {label = "Save Warps", command = "ws", args = true},
                {label = "Classic Mode", command = "classic"},
                {label = "Change HUD Mode", command = "whud"},
            },
            callback = warpsUIHandler
        })
    else
        outputDebugString("[Warps] Error: registerUIModule no disponible")
    end
end)

function warpsUIHandler(command, arg)
    if command == "wlist" then
        if not arg or arg == "" then
            listWarps()
        else
            executeCommandHandler("wlist", unpack(arg))
        end
    elseif command == "wl" then
        if not arg or arg == "" then
            outputChatBox(rtool.."#FFFFFFUsage: '#a578ffLoad Warps [name]#FFFFFF'", 115, 46, 255, true)
        else
            executeCommandHandler("wl", unpack(arg))
        end

    elseif command == "ws" then
        if not arg or arg == "" then
            outputChatBox(rtool.."#FFFFFFUsage: '#a578ffSave Warps [name]#FFFFFF'", 115, 46, 255, true)
        else
            executeCommandHandler("ws", unpack(arg))
        end

    elseif command == "classic" then
        executeCommandHandler("classic")

    elseif command == "whud" then
        executeCommandHandler("whud")

    elseif command == "nofix" then
       executeCommandHandler("nofix")

    elseif command == "nosref" then
       executeCommandHandler("nosref")
    end
end


-- ===========================
-- INTERFAZ ty chatgpt for this one, though mine was smaller code wise lol, but the animations are COOL! (ig)
-- ===========================
local refX, refY = 2560, 1440

local scrollOffset = 0
local targetScrollOffset = 0
local animSpeed = 0.18
local lastTick = getTickCount()

local COLOR_SELECTED = {255, 204, 0}
local COLOR_GRAD_A   = {0, 102, 255}
local COLOR_GRAD_B   = {204, 0, 0}
local COLOR_BG_GRAY  = {10, 10, 10}
local COLOR_LOAD     = {0, 102, 255}
local COLOR_FLASH_OK = {65, 158, 0}
local COLOR_KO       = {255, 255, 255}

local PANEL_W_BASE = 80
local LINE_H_BASE  = 36
local TEXT_SCALE_BASE = 1.65

-- Estados por warp
local uiWarpState, koGhosts, lastSelected = {}, {}, nil

-- Easing helpers
function easeOutExpo(t) if t >= 1 then return 1 end return 1 - (2 ^ (-10 * t)) end
function easeOutFlash(t) return t^0.3 end
function easeInOutQuad(t) if t < 0.5 then return 2*t*t else return -1 + (4 - 2*t)*t end end
function lerp(a,b,t) return a + (b - a) * t end
function lerpColor(c1,c2,t) return lerp(c1[1],c2[1],t), lerp(c1[2],c2[2],t), lerp(c1[3],c2[3],t) end

function ensureWarpState(i)
    if not uiWarpState[i] then uiWarpState[i] = {createT = 0, previewT = 0, auraT = 0, loadT = 0} end
    return uiWarpState[i]
end

function ui_onCreate(i) ensureWarpState(i).createT = getTickCount() end
function ui_onLoad(i) ensureWarpState(i).loadT = getTickCount() end
function ui_onPreviewStart() local now = getTickCount() for i=1,#warps do ensureWarpState(i).previewT = now end end
function ui_onDelete(i,label)
    local ghost = { startT = getTickCount(), idx = i, label = label or ("{"..i.."}"), life = 1500 }
    table.insert(koGhosts, ghost)
end

addEventHandler("onClientRender", root, function()
    if hudMode == 3 then return end
    if hudMode == 2 and not visiblePrev then return end

    if not getPedOccupiedVehicle(localPlayer) or #warps == 0 then return end

    local sx, sy = guiGetScreenSize()
    local scaleX, scaleY = sx / refX, sy / refY
    local globalScale = math.min(scaleX, scaleY)

    local PANEL_W = PANEL_W_BASE * scaleX
    local LINE_H  = LINE_H_BASE * scaleY
    local TEXT_SCALE = TEXT_SCALE_BASE * globalScale

    local baseX = sx - PANEL_W - (4 * scaleX)
    local centerY = sy * 0.5
    local maxVisible, half = 13, 6

    -- cambio de selección -> aura
    if lastSelected ~= selectedWarp then
        if selectedWarp then ensureWarpState(selectedWarp).auraT = getTickCount() end
        lastSelected = selectedWarp
    end

    selectedWarp = selectedWarp or 1
    targetScrollOffset = (selectedWarp - 1) * LINE_H

    local now, dt = getTickCount(), (getTickCount() - lastTick) / 1000
    lastTick = now
    scrollOffset = scrollOffset + (targetScrollOffset - scrollOffset) * animSpeed * dt * 60

    local fromIdx, toIdx = math.max(1, selectedWarp - half), math.min(#warps, selectedWarp + half)

    -- KO ghosts
    for gi = #koGhosts,1,-1 do
        local g = koGhosts[gi]
        local t = (now - g.startT) / g.life
        if t >= 1 then table.remove(koGhosts, gi)
        else
            local y = centerY + ((g.idx - selectedWarp) * LINE_H) - (scrollOffset % LINE_H) - LINE_H/2
            local progress = easeOutExpo(math.min(1, t*1.3))
            local expand = PANEL_W * progress
            local alpha = 255 * (1 - t * progress)

            dxDrawRectangle(baseX - expand, y + 5, PANEL_W + (expand*1.3), LINE_H - 5, tocolor(COLOR_KO[1], COLOR_KO[2], COLOR_KO[3], alpha / 0.8))
            dxDrawText(g.label, baseX, y, baseX+PANEL_W, y+LINE_H+6, tocolor(255,255,255, alpha), TEXT_SCALE, "default-bold-small","center","center")
        end
    end

    -- Warps
    for i = fromIdx, toIdx do
        local y = centerY + ((i - selectedWarp) * LINE_H) - (scrollOffset % LINE_H) - LINE_H/2
        local st = ensureWarpState(i)
        local dist = math.abs(i - selectedWarp)

        -- flashes
        if st.createT > 0 then
            local ct = (now - st.createT) / 800
            if ct < 1 then
                local a = math.floor(220 * (1 - easeInOutQuad(ct)))
                dxDrawRectangle(baseX, y+8, PANEL_W, LINE_H - 5, tocolor(COLOR_FLASH_OK[1], COLOR_FLASH_OK[2], COLOR_FLASH_OK[3], a))
            else st.createT = 0 end
        end

        if st.loadT > 0 then
            local ct = (now - st.loadT) / 800
            if ct < 1 then
                local a = math.floor(220 * (1 - easeInOutQuad(ct)))
                dxDrawRectangle(baseX, y, PANEL_W, LINE_H+6, tocolor(COLOR_LOAD[1], COLOR_LOAD[2], COLOR_LOAD[3], a))
            else st.loadT = 0 end
        end

        -- aura selección
        if st.auraT > 0 and previewing then
            local at = (now - st.auraT) / 600
            if at < 1 then
                local size = PANEL_W * 0.5 * easeOutExpo(at)
                local alpha = 200 * (1 - at)
                dxDrawRectangle(baseX - size/2, y-2, PANEL_W + size, LINE_H+10, tocolor(10, 10, 10, alpha))
            else st.auraT = 0 end
        end

        if previewing and i == selectedWarp then
            dxDrawRectangle(baseX, y, PANEL_W, LINE_H+6, tocolor(COLOR_BG_GRAY[1], COLOR_BG_GRAY[2], COLOR_BG_GRAY[3], 200))
        end

        local r,g,b, aTxt
        if i == selectedWarp then
            r,g,b, aTxt = COLOR_SELECTED[1], COLOR_SELECTED[2], COLOR_SELECTED[3], 255
        else
            r,g,b = lerpColor(COLOR_GRAD_A, COLOR_GRAD_B, math.min(1, dist/half))
            if previewing then
                aTxt = 255 - dist*40
            else
                aTxt = math.max(0, 100 - dist*30)
            end
            -- aTxt = 245 - dist*40
        end
        dxDrawText("{"..i.."}", baseX, y, baseX+PANEL_W, y+LINE_H+6, tocolor(r,g,b,aTxt), TEXT_SCALE, "default-bold-small","center","center")
    end
end)



-- GUARDAR WARP
function saveWarp()
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh then return end

    local x, y, z = getElementPosition(veh)
    local rx, ry, rz = getElementRotation(veh)
    local vx, vy, vz = getElementVelocity(veh)
    local tvx, tvy, tvz = getElementAngularVelocity(veh)
    local health = getElementHealth(veh)
    local model = getElementModel(veh)

    -- Nitro
    local nitro = false
    local nitroCount = 0
    local nitroActive = false

    for _, upgrade in ipairs(getVehicleUpgrades(veh)) do
        if upgrade == 1010 then
            nitro = true
            nitroCount = getVehicleNitroLevel and getVehicleNitroLevel(veh) or 1
            nitroActive = isVehicleNitroActivated and isVehicleNitroActivated(veh) or false
            break
        end
    end

    local newWarp = {
        pos = {x, y, z},
        rot = {rx, ry, rz},
        vel = {vx, vy, vz},
        turn = {tvx, tvy, tvz},
        health = health,
        model = model,
        nitro = nitro,
        nitroCount = nitroCount,
        nitroActive = nitroActive,
        cam = {getCameraMatrix()},
        serial = localSerial
    }

    if getKeyState("rshift") and selectedWarp then
        table.insert(warps, selectedWarp + 1, newWarp)
        selectedWarp = selectedWarp + 1
		ui_onCreate(selectedWarp)
    else
        table.insert(warps, newWarp)
        selectedWarp = #warps
		ui_onCreate(selectedWarp)

    end
	--outputDebugString("[Warps] Enviando warp al servidor ("..tostring(getPlayerName(localPlayer))..")")
    triggerServerEvent("onPlayerCreateWarp", localPlayer, newWarp)
end

--SYNC MODEL
addEvent("onPlayerForceVehicleModel", true)
addEventHandler("onPlayerForceVehicleModel", root, function(serial, model)
    for _, p in ipairs(getElementsByType("player")) do
        if getPlayerSerial(p) == serial then
            local veh = getPedOccupiedVehicle(p)
            if isElement(veh) then
                setElementModel(veh, model)
            end
        end
    end
end)

-- APLICAR WARP
function applyWarp(index, skipMotion)
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh or not warps[index] or warps[index].serial ~= localSerial then return end

    local warp = warps[index]

    setElementModel(veh, warp.model or getElementModel(veh))
    setElementHealth(veh, warp.health or 1000)
    setElementPosition(veh, unpack(warp.pos))
    setElementRotation(veh, unpack(warp.rot))

    -- Camara DEFUNCT RIP.
    --if warp.cam and warp.cam[1] then
       -- setCameraMatrix(unpack(warp.cam))
   -- end

    removeVehicleUpgrade(veh, 1010) -- Removing just in case

    if warp.nitro then
        addVehicleUpgrade(veh, 1010)

        if warp.nitroActive and setVehicleNitroActivated then
			setVehicleNitroActivated(veh, true)
		end

		if setVehicleNitroLevel and warp.nitroCount then
			setVehicleNitroLevel(veh, warp.nitroCount)
		end
    end

    -- velocidad sin preview
    if not skipMotion then
        setElementVelocity(veh, unpack(warp.vel))
        setElementAngularVelocity(veh, unpack(warp.turn))
    end
    if classicMode then 
		selectedWarp = #warps
    else
		selectedWarp = index
	end
end



-- CARGAR WARP
function loadWarp(index)
    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh then return end
	
    selectedWarp = index
	ui_onLoad(selectedWarp)
    local warp = warps[index]
    if not warp then return end

    applyWarp(index, true) -- aplica todo menos vel
	triggerServerEvent("onPlayerRequestVehicleModel", localPlayer, warp.model)
    setElementFrozen(veh, true)

    -- Freezxe delay
    setTimer(function()
        if not isElement(veh) then return end
        setElementFrozen(veh, false)
        setCameraTarget(unpack(warp.cam))

        setTimer(function()
            if isElement(veh) then
                setElementVelocity(veh, unpack(warp.vel))
                setElementAngularVelocity(veh, unpack(warp.turn))
				setCameraTarget(localPlayer)
            end
        end, 50, 1)
    end, 250, 1)
end

-- ELIMINAR WARPS
function deleteWarp(n)
    n = n or 1
    if getKeyState("rshift") and selectedWarp then
        for i = 1, n do
            if warps[selectedWarp] then
                -- UI: KO del seleccionado
                ui_onDelete(selectedWarp, "{"..selectedWarp.."}")
                table.remove(warps, selectedWarp)
                if selectedWarp > #warps then selectedWarp = #warps end
                if selectedWarp < 1 then selectedWarp = nil end
            end
        end
    else
        for i = 1, n do
            local idx = #warps
            if warps[idx] then
                -- UI: KO del último
                ui_onDelete(idx, "{"..idx.."}")
                table.remove(warps)
            end
        end
        selectedWarp = #warps
        if selectedWarp == 0 then selectedWarp = nil end
    end
    triggerServerEvent("onPlayerDeleteWarp", localPlayer, n)
end


function deleteAllWarps()
    warps = {}
    selectedWarp = nil
	triggerServerEvent("onPlayerDeleteWarp", localPlayer, "all")
end

function deleteWarpRange(from, to)
    for i = to, from, -1 do
        if warps[i] then
            ui_onDelete(i, "{"..i.."}")
            table.remove(warps, i)
        end
    end
    selectedWarp = #warps
    if selectedWarp == 0 then selectedWarp = nil end

    triggerServerEvent("onPlayerDeleteWarp", localPlayer, {from = from, to = to})
end

-- COMANDOS

-- addCommandHandler("recordmode", function()
--     if not recordingMode then
-- 	recordingMode = true
-- 	outputChatBox(rtool.."#FFFFFFRewind #ff6666OFF ", 115, 46, 255, true)
-- 	else 
-- 	recordingMode = false
-- 	outputChatBox(rtool.."#FFFFFFRewind #33cc33ON ", 115, 46, 255, true)
-- 	end
-- end)


addCommandHandler(SAVEWARP_CMD, function()
    if getPedOccupiedVehicle(localPlayer) then 
		saveWarp() 
		--triggerServerEvent("onPlayerCreateWarp", localPlayer, newWarp)
	end
end)

--[[
addCommandHandler(LOADWARP_CMD, function(_, id)
    if not getPedOccupiedVehicle(localPlayer) then return end

    if id then
        id = tonumber(id)
        if id and warps[id] then
            loadWarp(id)
            return
        end
    end
	
    if #warps > 0 then
        loadWarp(selectedWarp or #warps)
    else
        outputChatBox(rtool.."#FF0000ERROR: #FFFFFFNo warps loaded.", 115,46,255,true)
    end
end)
]]
addCommandHandler("lwp", function(_, targetName)
    if not targetName or targetName == "" then
        outputChatBox(rtool.."#FFFFFFUsage: #a578ff/lwp [player]", 115,46,255,true)
        return
    end
    triggerServerEvent("onPlayerRequestAllWarps", localPlayer, targetName)
end)

addCommandHandler("classic", function(_, targetName)
    classicMode = not classicMode
    recordingMode = not recordingMode
		outputChatBox(rtool.."#FFFFFFRewind, Preview and Warp selection "..(classicMode and "#ff6666OFF" or "#33cc33ON" ), 115,46,255,true)
end)


addCommandHandler(LOADWARP_CMD, function(_, arg1, arg2)
    if not getPedOccupiedVehicle(localPlayer) then return end

    if arg1 and tonumber(arg1) then
        local id = tonumber(arg1)
        if warps[id] then
            loadWarp(id)
        else
            outputChatBox(rtool.."#FF0000ERROR: #FFFFFFWarp index not found ("..id..")", 115,46,255,true)
        end
        return
    end

    if arg1 and not tonumber(arg1) then
        local targetName = arg1
        local warpIndex = arg2 and tonumber(arg2) or nil
        triggerServerEvent("onPlayerRequestWarpIndex", localPlayer, targetName, warpIndex)
        return
    end

    if #warps > 0 then
        loadWarp(selectedWarp or #warps)
    else
        outputChatBox(rtool.."#FF0000ERROR: #FFFFFFNo warps loaded.", 115,46,255,true)
    end
end)

function warpDeleteCmd(cmd, amount) 
    if not getPedOccupiedVehicle(localPlayer) then return end

    if not amount then
        local usingShift = getKeyState("rshift")

        deleteWarp(1)

        if usingShift then
            outputChatBox(rtool.."#FFFFFFDeleted selected warp", 115, 46, 255, true)
        else
            outputChatBox(rtool.."#FFFFFFDeleted last warp", 115, 46, 255, true)
        end
        return
    end

    if amount == "all" then
        outputChatBox(rtool.."#FFFFFFDeleted "..#warps.." warps", 115, 46, 255, true)
        deleteAllWarps()
        return
    end

    -- Detectar intervalos
    local from, to = amount:match("^(%d+)%-(%d+)$")

    if from and to then
        from, to = tonumber(from), tonumber(to)
        if from > to then from, to = to, from end

        if not warps then warps = {} end 
        
        from = math.max(1, from)
        to   = math.min(#warps, to)

        if from > to then return end

        deleteWarpRange(from, to)

        outputChatBox(rtool.."#FFFFFFDeleted warps from #33cc33#"..from.." — #"..to,
            115, 46, 255, true)
        return
    end

    if tonumber(amount) > #warps then
        amount = #warps
    end

    local numToDel = tonumber(amount) or 1 
        deleteWarp(numToDel)
        outputChatBox(rtool.."#FFFFFFDeleted last "..numToDel.." warp(s)", 115, 46, 255, true)
end
addCommandHandler(DELETEWARP_CMD, warpDeleteCmd)

--[[
addCommandHandler("dwall", function()
    if getPedOccupiedVehicle(localPlayer) then
		outputChatBox("{#9991A2RwARP#732EFF} #FFFFFFDeleted "..#warps.. " warps", 115, 46, 255, true)
        deleteAllWarps()
    end
end)
]]

-- NAVEGACIon 
function SHOW_LIST_DOWN()
	if classicMode then return end
	if univUI then return end
    if not getPedOccupiedVehicle(localPlayer) or isRewinding then return end
    showAll = true
    previewing = true
    ui_onPreviewStart()

    if hudMode == 2 then visiblePrev = true end

    if warps[selectedWarp] then
        --Con esto se cargará el warp seleccionado sin haber cambiado de warp. Puede ser molesto.
        -- applyWarp(selectedWarp, true)
        setElementFrozen(getPedOccupiedVehicle(localPlayer), true)
    end
end

function SHOW_LIST_UP()
	if classicMode then return end 
	if univUI then return end
    showAll = false
    previewing = false

    if hudMode == 2 then visiblePrev = false end

    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh or not warps[selectedWarp] then return end

    local warp = warps[selectedWarp]
    applyWarp(selectedWarp, true)
    setElementFrozen(veh, true)

    setTimer(function()
        if not isElement(veh) then return end
        setElementFrozen(veh, false)
        setCameraTarget(localPlayer)

        setTimer(function()
            if isElement(veh) then
                setElementVelocity(veh, unpack(warp.vel))
                setElementAngularVelocity(veh, unpack(warp.turn))
            end
        end, 50, 1)
    end, 250, 1)
end


bindKey(keyUp, "down", function()
    if not showAll or #warps == 0 then return end
    selectedWarp = selectedWarp - 1
    if selectedWarp < 1 then
        selectedWarp = #warps
    end
    applyWarp(selectedWarp, true)
    setElementFrozen(getPedOccupiedVehicle(localPlayer), true)
end)

bindKey(keyDown, "down", function()
    if not showAll or #warps == 0 then return end
    selectedWarp = selectedWarp + 1
    if selectedWarp > #warps then
        selectedWarp = 1
    end
    applyWarp(selectedWarp, true)
    setElementFrozen(getPedOccupiedVehicle(localPlayer), true)
end)

-- HUD mode

addEvent("onReceiveMisc", true)
addEventHandler("onReceiveMisc", root, function(savedHud, savedFix, savedNos)
    if savedHud and tonumber(savedHud) then
        hudMode = tonumber(savedHud)
        if hudMode == 1 then
            visiblePrev = true
        else
            visiblePrev = false
        end
    end
    if savedFix then
        nofixEnabled = (savedFix == true or savedFix == "true")
    end
    if savedNos then
        nosrefEnabled = (savedNos == true or savedNos == "true")
    end
end)

addCommandHandler("whud", function()
    hudMode = hudMode + 1
    if hudMode > 3 then hudMode = 1 end

    if hudMode == 1 then
        visiblePrev = true
        outputChatBox(rtool.."#FFFFFFWarps HUD mode: #33cc33Always Visible", 115, 46, 255, true)
    elseif hudMode == 2 then
        visiblePrev = false
        outputChatBox(rtool.."#FFFFFFWarps HUD mode: #FFCC00Dynamic", 115, 46, 255, true)
    else
        visiblePrev = false
        outputChatBox(rtool.."#FFFFFFWarps HUD mode: #FF3333Hidden", 115, 46, 255, true)
    end

    triggerServerEvent("onClientUpdateHudMode", localPlayer, hudMode)
end)

--SAVE

addCommandHandler("ws", function(_, name)
    if not name or name == "" then
        outputChatBox(rtool.."#FFFFFFUsage: '#a578ff/ws [name]#FFFFFF'", 115,46,255,true)
        return
    end
    if tostring(name):find("^%d") then
        outputChatBox(rtool.."#FF0000ERROR! #FFFFFFWarps name cannot start with a number", 255, 100, 100, true)
        return
    end

    local root, warpSaveRoot = loadUsertoolGroup("warps")

    local oldNode = xmlFindChild(warpSaveRoot, name, 0)
    if oldNode then xmlDestroyNode(oldNode) end

    local newNode = xmlCreateChild(warpSaveRoot, name)

    for _, data in ipairs(warps) do
        local entry = xmlCreateChild(newNode, "warp")

        -- Atributos originales
        for k, v in pairs({
            px=data.pos[1], py=data.pos[2], pz=data.pos[3],
            rx=data.rot[1], ry=data.rot[2], rz=data.rot[3],
            vx=data.vel[1], vy=data.vel[2], vz=data.vel[3],
            tvx=data.turn[1], tvy=data.turn[2], tvz=data.turn[3],
            health=data.health or 1000,
            model=data.model or 411,
            nitro=(data.nitro and 1 or 0),
            nitroCount=data.nitroCount or 1,
            nitroActive=tostring(data.nitroActive)
        }) do
            xmlNodeSetAttribute(entry, k, tostring(v))
        end

        if data.cam then
            xmlNodeSetAttribute(entry, "camx", tostring(data.cam[1]))
            xmlNodeSetAttribute(entry, "camy", tostring(data.cam[2]))
            xmlNodeSetAttribute(entry, "camz", tostring(data.cam[3]))
            xmlNodeSetAttribute(entry, "lookx", tostring(data.cam[4]))
            xmlNodeSetAttribute(entry, "looky", tostring(data.cam[5]))
            xmlNodeSetAttribute(entry, "lookz", tostring(data.cam[6]))
        end
    end

    xmlSaveFile(root)
    outputChatBox(rtool.."#FFFFFF"..#warps.." Warps saved as '#33cc33"..name.."#FFFFFF'",115,46,255,true)
end)


addCommandHandler("wl", function(_, name)
    initWarpSaveFile()
    if not name or name == "" then
	  
		outputChatBox(rtool.."#FFFFFFUsage: '#a578ff/wl [name]#FFFFFF'", 115, 46, 255, true)
        return
    end
    if not warpSaveRoot then return end

    local node = xmlFindChild(warpSaveRoot, name, 0)
    if not node then
	    outputChatBox(rtool.."#FF0000 ERROR: #FFFFFFWarp index not found '#a578ff"..name.."#FFFFFF'", 115, 46, 255, true)
        return
    end

    warps = {}
    selectedWarp = 1

    for _, child in ipairs(xmlNodeGetChildren(node)) do
        local nitroRaw = tonumber(xmlNodeGetAttribute(child, "nitro")) or 0
        local nitro = nitroRaw > 0

        table.insert(warps, {
            pos = {
                tonumber(xmlNodeGetAttribute(child, "px")) or 0,
                tonumber(xmlNodeGetAttribute(child, "py")) or 0,
                tonumber(xmlNodeGetAttribute(child, "pz")) or 0,
            },
            rot = {
                tonumber(xmlNodeGetAttribute(child, "rx")) or 0,
                tonumber(xmlNodeGetAttribute(child, "ry")) or 0,
                tonumber(xmlNodeGetAttribute(child, "rz")) or 0,
            },
            vel = {
                tonumber(xmlNodeGetAttribute(child, "vx")) or 0,
                tonumber(xmlNodeGetAttribute(child, "vy")) or 0,
                tonumber(xmlNodeGetAttribute(child, "vz")) or 0,
            },
            turn = {
                tonumber(xmlNodeGetAttribute(child, "tvx")) or 0,
                tonumber(xmlNodeGetAttribute(child, "tvy")) or 0,
                tonumber(xmlNodeGetAttribute(child, "tvz")) or 0,
            },
            health = tonumber(xmlNodeGetAttribute(child, "health")) or 1000,
            model = tonumber(xmlNodeGetAttribute(child, "model")) or 411, -- 411 como fallback
            nitro = nitro,
            nitroCount = tonumber(xmlNodeGetAttribute(child, "nitroCount")) or 1,
            nitroActive = xmlNodeGetAttribute(child, "nitroActive") == "true",
            serial = localSerial,
            cam = (xmlNodeGetAttribute(child, "camx") and {
                tonumber(xmlNodeGetAttribute(child, "camx")) or 0,
                tonumber(xmlNodeGetAttribute(child, "camy")) or 0,
                tonumber(xmlNodeGetAttribute(child, "camz")) or 0,
                tonumber(xmlNodeGetAttribute(child, "lookx")) or 0,
                tonumber(xmlNodeGetAttribute(child, "looky")) or 0,
                tonumber(xmlNodeGetAttribute(child, "lookz")) or 0
            } or nil)
        })
    end

	outputChatBox(rtool.."#FFFFFF"..#warps.." Warps loaded from '#33cc33"..name.."#FFFFFF'", 115, 46, 255, true)
		if #warps > 0 then
		triggerServerEvent("onPlayerDeleteWarp", localPlayer, "all") -- limpia lo anterior
		for _, warp in ipairs(warps) do
			triggerServerEvent("onPlayerCreateWarp", localPlayer, warp)
		end
		--outputDebugString("[Warps] Enviados "..#warps.." warps cargados del archivo al servidor.")
	end
end)

function deleteWarpList(_, name)
    if not warpSaveRoot then
        outputChatBox(rtool.."#FF0000 ERROR: #FFFFFFNo warp save file loaded", 115, 46, 255, true)
        return
    end

    if not name or name == "" then
        outputChatBox(rtool.."#FFFFFFUsage: '#a578ff/wd [name]#FFFFFF'", 115, 46, 255, true)
        return
    end

    local node = xmlFindChild(warpSaveRoot, name, 0)
    if not node then
        outputChatBox(rtool.."#FF0000 ERROR: #FFFFFFWarp list '#a578ff"..name.."#FFFFFF' not found.", 115, 46, 255, true)
        return
    end
	
    xmlDestroyNode(node)
    xmlSaveFile(warpSaveRoot)
    outputChatBox(rtool.."#FFFFFFDeleted warp list '#a578ff"..name.."#FF0000'.", 115, 46, 255, true)

    local remaining = #xmlNodeGetChildren(warpSaveRoot)
    outputChatBox(rtool.."#FFFFFFRemaining warp lists: #33cc33"..remaining, 115, 46, 255, true)
end
addCommandHandler("wd", deleteWarpList)



function listWarps(_, pageArg)
    if not warpSaveRoot then 
        outputChatBox(rtool.."#FF0000 ERROR: #FFFFFFNo warp save file loaded", 115, 46, 255, true)
        return 
    end
	
	local maxResults = 10
    local lists = xmlNodeGetChildren(warpSaveRoot)
    local totalLists = #lists
    if totalLists == 0 then
        outputChatBox(rtool.."#FFFFFFNo saved warp lists found.", 115, 46, 255, true)
        return
    end

    local totalPages = math.ceil(totalLists / maxResults)
    local currentPage = tonumber(pageArg) or 1
    if currentPage < 1 then currentPage = 1 end
    if currentPage > totalPages then currentPage = totalPages end

    local startIndex = (currentPage - 1) * maxResults + 1
    local endIndex = math.min(startIndex + maxResults - 1, totalLists)

    outputChatBox(rtool.."#FFFFFFWarps ("..totalLists.." total) — Page "..currentPage.."/"..totalPages..":", 115, 46, 255, true)

    for i = startIndex, endIndex do
        local listNode = lists[i]
        if listNode then
            local listName = xmlNodeGetName(listNode)
            local count = #xmlNodeGetChildren(listNode)
            outputChatBox(i..". #33cc33"..listName.."#FFFFFF - "..count.." Warps", 0, 102, 255, true)
        end
    end
end
addCommandHandler("wlist", listWarps)

---REWIND

addEventHandler("onClientRender", root, function()
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle or getElementData(localPlayer, "race.spectating") then return end

    local x, y, z = getElementPosition(vehicle)
    local rx, ry, rz = getElementRotation(vehicle)
    local vx, vy, vz = getElementVelocity(vehicle)
    local vtx, vty, vtz = getElementAngularVelocity(vehicle)
    local health = getElementHealth(vehicle)
    local nitroActive = isVehicleNitroActivated(vehicle)
    local nitroLevel = getVehicleNitroLevel(vehicle)
    local model = getElementModel(vehicle)
    local cx, cy, cz, clx, cly, clz = getCameraMatrix()

    local frame = {
        pos = {x, y, z},
        rot = {rx, ry, rz},
        vel = {vx, vy, vz},
        angVel = {vtx, vty, vtz},
        health = health,
        nitroActive = nitroActive,
        nitroLevel = nitroLevel,
        model = model,
        cam = {cx, cy, cz, clx, cly, clz}
    }

    if not isRewinding then
        table.insert(recData, frame)
    end
end)

addEventHandler("onClientRender", root, function()
    if recordingMode then return end
    if not isRewinding then return end
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle then return end

    local steps = getKeyState(KEY_FAST_REWIND) and fastRewindSpeed or rewindSpeed

    for i = 1, steps do
        local frame = recData[#recData]
        if not frame then endRewind() return end

        setElementPosition(vehicle, unpack(frame.pos))
        setElementRotation(vehicle, unpack(frame.rot))
        setElementHealth(vehicle, frame.health)
        setElementVelocity(vehicle, 0, 0, 0)
        setElementAngularVelocity(vehicle, 0, 0, 0)
		setElementModel(vehicle, frame.model)

        if frame.nitroLevel and frame.nitroLevel > 0 then
            addVehicleUpgrade(vehicle, 1010)
            setVehicleNitroLevel(vehicle, frame.nitroLevel)
            setVehicleNitroActivated(vehicle, frame.nitroActive == true)
        else
            removeVehicleUpgrade(vehicle, 1010)
        end

        if frame.cam[1] and frame.cam[2] and frame.cam[3] then
            setCameraMatrix(unpack(frame.cam))
        end

        table.remove(recData)
    end
end)

function startRewind()
    local vehicle = getPedOccupiedVehicle(localPlayer)
	if recordingMode then return end
	if univUI then return end
    if not vehicle or getElementData(localPlayer, "race.spectating") then return end
    isRewinding = true
    setElementFrozen(vehicle, true)
end
bindKey(KEY_REWIND, "down", startRewind)

function endRewind()
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle then return end
    setElementFrozen(vehicle, false)
    setCameraTarget(localPlayer)

    local last = recData[#recData]
    if last then
        setElementVelocity(vehicle, unpack(last.vel))
        setElementAngularVelocity(vehicle, unpack(last.angVel))
    end

    isRewinding = false
end

bindKey(KEY_REWIND, "up", endRewind)

addEvent("onClientMapStarting", true)
addEventHandler("onClientMapStarting", root, function()
    recData = {}
end)

addEvent("onClientMapStopping", true)
addEventHandler("onClientMapStopping", root, function()
    recData = {}
    if isRewinding then endRewind() end
end)

addEvent("onReceivePlayerWarps", true)
addEventHandler("onReceivePlayerWarps", root, function(receivedWarps, fromPlayer)
    if not receivedWarps then
        outputChatBox(rtool.."#FF0000ERROR: #FFFFFFNo warps found for that player.", 115,46,255,true)
        return
    end

    local isSelf = false
    if fromPlayer and isElement(fromPlayer) then
        isSelf = (fromPlayer == localPlayer)
    end

    warps = {}

    if not isSelf then
        triggerServerEvent("onPlayerDeleteWarp", localPlayer, "all")
    end

    if isSelf then
		if hudMode == 1 then
			WarpsHudDisplay = "#33cc33/whud"
		elseif hudMode == 2 then
			WarpsHudDisplay = "#FFCC00/whud"
		elseif hudMode == 3 then
			WarpsHudDisplay = "#FF3333/whud"
		end
			if nofixEnabled then
				NoFixMode = "#33cc33/nofix"
				else
				NoFixMode = "#9991A2/nofix"
			end
			if nosrefEnabled then 
				NosMode = "#2757F5/nosref"
				else
				NosMode = "#9991A2/nosref"
			end
		outputChatBox(rtool.."Restored '#33cc33"..#receivedWarps.."#FFFFFF' warps | " ..WarpsHudDisplay.. "#FFFFFF | "..NoFixMode.."#FFFFFF • "..NosMode, 115,46,255,true)
    else
        local name = fromPlayer and getPlayerName(fromPlayer) or "another player"
        name = name:gsub("#%x%x%x%x%x%x", "") -- eliminar color codes
        outputChatBox(rtool.."#33cc33"..#receivedWarps.."#FFFFFF warps loaded from "..name..".", 115,46,255,true)
    end

    for _, w in ipairs(receivedWarps) do
        w.serial = localSerial
        table.insert(warps, w)

        if not isSelf then
            triggerServerEvent("onPlayerCreateWarp", localPlayer, w)
        end
    end

    selectedWarp = #warps

    --outputDebugString("[Warps] " .. (isSelf and "Restored" or "Imported") .. " " .. tostring(#receivedWarps) .. " warps. isSelf=" .. tostring(isSelf))
end)

--[[DEBUG
addCommandHandler("wsend", function(_, targetName)
    if not targetName or targetName == "" then
        outputChatBox("/wsend [playerName]", 115, 46, 255, true)
        return
    end

    if not warps or #warps == 0 then
        outputChatBox("no warps", 115, 46, 255, true)
        return
    end

    triggerServerEvent("onRequestWarpSend", localPlayer, targetName, warps)
end)
]]

--[[
addCommandHandler("testshare", function()
    triggerServerEvent("onPlayerRequestAllWarps", localPlayer, getPlayerName(localPlayer))
end)
]]


addEvent("onReceiveSingleWarp", true)
addEventHandler("onReceiveSingleWarp", root, function(warp, requestedIndex, fromPlayer)
    if not warp then
        outputChatBox(rtool.."#FF0000ERROR: #FFFFFFWrong player or index.", 115,46,255,true)
        return
    end

    warp.serial = localSerial
    table.insert(warps, warp)
    ui_onCreate(#warps)
    selectedWarp = #warps

    triggerServerEvent("onPlayerCreateWarp", localPlayer, warp)

    local shownIndex = requestedIndex or "?"
	local name = fromPlayer and getPlayerName(fromPlayer) or "another player"
        name = name:gsub("#%x%x%x%x%x%x", "") -- eliminar color codes
        --outputChatBox(rtool.."#33cc33"..#receivedWarps.."#FFFFFF warps loaded from "..name..".", 115,46,255,true)
    outputChatBox(rtool.."Imported warp #33cc33#"..shownIndex.."#FFFFFF from #ffcc00"..name, 115,46,255,true)
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    warps = {}
    selectedWarp = nil
    --outputDebugString("[Warps] Limpieza por restart.")
end)

--------------------------
-- || MUTATORS
--------------------------

addCommandHandler("nofix", function()
	local vehicle = getPedOccupiedVehicle(localPlayer)
    nofixEnabled = not nofixEnabled
	outputChatBox(rtool.."#FFFFFFNo fix mode: " .. (nofixEnabled and "#33cc33ON" or "#ff6666OFF"), 90, 32, 162, true)
	if nofixEnabled then
		setVehicleDoorsUndamageable(vehicle, true)
		setVehicleDamageProof(vehicle, true)
	else
		setVehicleDoorsUndamageable(vehicle, false)
		setVehicleDamageProof(vehicle, false)
	
	end
    --outputChatBox("No fix mode " .. (nofixEnabled and "enabled" or "disabled"), 255, 255, 0)
	triggerServerEvent("onClientUpdateMutators", localPlayer, nofixEnabled, nosrefEnabled)
end)

addCommandHandler("nosref", function()
    nosrefEnabled = not nosrefEnabled
	outputChatBox(rtool.."#FFFFFFUnlimited Nitro: " .. (nosrefEnabled and "#33cc33ON" or "#ff6666OFF"), 90, 32, 162, true)
    --outputChatBox("Unlimited Nitro " .. (nosrefEnabled and "enabled" or "disabled"), 255, 255, 0)
	triggerServerEvent("onClientUpdateMutators", localPlayer, nofixEnabled, nosrefEnabled)
end)


addEventHandler("onClientPreRender", root, function()
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if vehicle then
        if nofixEnabled then
            fixVehicle(vehicle)
			
			setVehicleDoorState(vehicle, 1, 0)
			setVehicleDoorState(vehicle, 2, 0)
			setVehicleDoorState(vehicle, 3, 0)
			setVehicleDoorState(vehicle, 4, 0)
			setVehicleDoorState(vehicle, 5, 0)
			
			setVehiclePanelState(vehicle, 0, 0)
			setVehiclePanelState(vehicle, 1, 0)
			setVehiclePanelState(vehicle, 2, 0)
			setVehiclePanelState(vehicle, 3, 0)
			setVehiclePanelState(vehicle, 4, 0)
			setVehiclePanelState(vehicle, 5, 0)
			setVehiclePanelState(vehicle, 6, 0)
        end
        if nosrefEnabled then
            if not isVehicleNitroActivated(vehicle) then
                addVehicleUpgrade(vehicle, 1010)
            end
            setVehicleNitroLevel(vehicle, 1.0)
        end
    end
end)

--------------------------
-- || SNAPPING
--------------------------

function getSpawnPoint()
    local spawns = getElementsByType("spawnpoint")
    if not spawns or #spawns == 0 then return nil end
    for _, spawn in ipairs(spawns) do
        if isElement(spawn) then
            local sx, sy, sz = getElementPosition(spawn)
            local rotx, roty, rotz = getElementRotation(spawn)
            if not rotx or not roty or not rotz then
                rotx, roty, rotz = 0, 0, 0 
            end
            return sx, sy, sz, rotx, roty, rotz

        end
    end
    return nil
    
end
function getHunterPickup()
    local pickups = getElementsByType("racepickup")
    if not pickups or #pickups == 0 then return nil end
    for _, pickup in ipairs(pickups) do
        -- outputChatBox("Pickup Found, vehicleID:" ..tostring(exports.edf:edfGetElementProperty(pickup, "vehicleID")))
        if isElement(pickup) and exports.edf:edfGetElementProperty(pickup, "vehicle") == 425 then
            local sx, sy, sz = getElementPosition(pickup)
            return sx, sy, sz

        end
    end
    return nil
    
end

local ogx, ogy, ogz -- Original Pos

function Snap(cmd, location, arg2)
    local x, y, z, lookatX, lookatY, lookatZ
    local rx, ry, rz
    local avoidCarSnap = false

    if location then
        local part = string.lower(location)
        local foundPlayer
        for _, p in ipairs(getElementsByType("player")) do
            local cleanName = string.gsub(getPlayerName(p), "#%x%x%x%x%x%x", "")
            if string.find(string.lower(cleanName), part, 1, true) then
                foundPlayer = p
                break
            end
        end
        
        if foundPlayer then
            x, y, z = getElementPosition(foundPlayer)
            lookatX, lookatY, lookatZ = x, y, z
            location = "#FFFFFFplayer: #ffcc00"..string.gsub(getPlayerName(foundPlayer), "#%x%x%x%x%x%x", "")
            avoidCarSnap = true
        else
            if location == "sf" or location == "sanfierro" then
                location = "San Fierro"
                x, y, z = -1942.71, 883, 115
                lookatX, lookatY, lookatZ = -2664.71, 654.76, 100.0
            elseif location == "lv" or location == "lasventuras" then
                location = "Las Venturas"
                x, y, z = 2093.7236328125, 1775.2917480469, 16
                lookatX, lookatY, lookatZ = 2410.82, 1970.66, 100.0
            elseif location == "ls" or location == "lossantos" then
                location = "Los Santos"
                x, y, z = 2470.19, -1671.19, 18
                lookatX, lookatY, lookatZ = 2470.19, -1671.19, 100.0
            elseif location == "spawn" then
                location = "Spawn Point"
                local sx, sy, sz, rotx, roty, rotz = getSpawnPoint()
                if not sx then
                    outputChatBox(rtool.."#FF0000 ERROR: #FFFFFFNo spawn point found.", 115, 46, 255, true)
                    return
                end
                x, y, z = sx, sy, sz
                rx, ry, rz = rotx, roty, rotz
                lookatX, lookatY, lookatZ = sx, sy, sz
                avoidCarSnap = true
            elseif location == "hunter" then
                location = "Hunter"
                local sx, sy, sz = getHunterPickup()
                if not sx then
                    outputChatBox(rtool.."#FF0000 ERROR: #FFFFFFHunter pickup not found.", 115, 46, 255, true)
                    return
                end
                x, y, z = sx, sy, sz
            elseif location == "warp" then
                if not arg2 then
                    if #warps == 0 then
                        outputChatBox(rtool.."#FF0000 ERROR: #FFFFFFNo warps found.", 115, 46, 255, true)
                        return
                    end
                    local lastWarp = warps[#warps]
                    x, y, z = lastWarp.pos[1], lastWarp.pos[2], lastWarp.pos[3]
                    lookatX, lookatY, lookatZ = x, y, z
                    location = "Last Warp"
                    avoidCarSnap = true
                else
                    local idx = tonumber(arg2)
                    if not idx or not warps[idx] then
                        outputChatBox(rtool.."#FF0000 ERROR: #FFFFFFWarp index not found.", 115, 46, 255, true)
                        return
                    end
                    local w = warps[idx]
                    x, y, z = w.pos[1], w.pos[2], w.pos[3]
                    lookatX, lookatY, lookatZ = x, y, z
                    location = "Warp #"..idx
                    avoidCarSnap = true
                end
            elseif location == "back" then
                if ogx then
                    x, y, z = ogx, ogy, ogz
                    lookatX, lookatY, lookatZ = ogx, ogy, ogz
                    location = "Old Position"
                else
                    outputChatBox(rtool.."#FF0000 ERROR: #FFFFFFNowhere to snap back.", 115, 46, 255, true)
                    return
                end
            else
                return
            end
        end
    end

    if location then
        ogx, ogy, ogz = getElementPosition(localPlayer)
        if not isPedInVehicle(localPlayer) then
            setCameraMatrix(x, y, z + 8, lookatX, lookatY, lookatZ) 
            outputChatBox(rtool.."Camera snapped to #33cc33"..location, 0, 102, 255, true)

        elseif  isPedInVehicle(localPlayer) and avoidCarSnap == false then
            local vehicle = getPedOccupiedVehicle(localPlayer)
            setElementPosition(vehicle, x, y, z + 10)
            outputChatBox(rtool.."Car snapped to #33cc33"..location, 0, 102, 255, true)

        else
            outputChatBox(rtool.."Use warps for that BRUH.", 0, 102, 255, true)
        end
    else
        outputChatBox(rtool.."Usage: #a578ff/snap [#FFFFFF sf/lv/ls/spawn/warp/player/back #a578ff]", 0, 102, 255, true)
        outputChatBox(" #FFFFFF↳ '#a578ff/snap warp [number]#ffffff' Last warp or warp number. ", 0, 102, 255, true)
        outputChatBox("  #FFFFFF↳ For players use '#a578ff/snap [name or part of name]#ffffff'  ", 0, 102, 255, true) 
    end
end
addCommandHandler("snap", Snap)

-- function WarpStart()
	bindKey(SAVEWARP_KEY, "down", SAVEWARP_CMD)
	bindKey(LOADWARP_KEY, "down", LOADWARP_CMD)
	bindKey(DELETEWARP_KEY, "down", DELETEWARP_CMD)
	bindKey(keyShowList, "up", SHOW_LIST_UP)
	bindKey(keyShowList, "down", SHOW_LIST_DOWN)

-- end
-- addEventHandler("onClientResourceStart", resourceRoot, WarpStart);

-- HELP / CMDS
addCommandHandler("cmds", function(_, arg)
    if arg ~= "warp" then return end
    outputChatBox("---------- Warp ----------", 255, 255, 255, true)
    function help(msg)
        outputChatBox(rtool .. "#FFFFFF" .. msg, 115, 46, 255, true)
    end

    -- Warps
    help("[ /sw ] #9991A2Create warp")
    help("[ /lw <id> ] #9991A2Load warp by ID (or last if none)")
	help("[ /lw <player> <id> ] #9991A2Import warp from another player")
    help("[ /dw <n>/all ] #9991A2Delete last N warps or all")
    help("[ /ws <name> ] #9991A2Save warps to list")
    help("[ /wl <name> ] #9991A2Load warps from list")
    help("[ /wlist <page> ] #9991A2Show saved warp lists")
    help("[ /whud ] #9991A2Toggle warp HUD visibility")
    help("[ /lwp <player>] #9991A2Import warps from another player")

    -- Navigation
    help("[ LSHIFT ] #9991A2Hold: show warp list preview")
    help("[ ↑ / ↓ ] #9991A2Navigate warps (when preview active)")

    -- Rewind
    help("[ BACKSPACE ] #9991A2Hold: rewind vehicle")
    help("[ Q + BACKSPACE ] #9991A2Fast rewind")
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    triggerServerEvent("onWarpClientReady", localPlayer)
end)
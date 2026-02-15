-- warp_s.lua

local playerWarps = {}       -- [serial] = { warp1, warp2, ... }
local playerSerialMap = {}   -- [player] = serial
local playerHudMode = {}     -- [serial] = number
local playerNofixMode = {}	 -- [serial] = string
local playerNosrefMode = {}  -- [serial] = string

local SAVE_FILE = "warps_data.xml"

local function saveWarpsToFile()
    local rootNode = xmlCreateFile(SAVE_FILE, "warps")
    if not rootNode then
        outputDebugString("[Warps_s] ERROR al crear archivo XML de warps", 1)
        return
    end

    for serial, warps in pairs(playerWarps) do
        local playerNode = xmlCreateChild(rootNode, "player")
		xmlNodeSetAttribute(playerNode, "serial", serial)
			if playerHudMode[serial] and tostring(playerNofixMode[serial]) and tostring(playerNosrefMode[serial]) then
				xmlNodeSetAttribute(playerNode, "hudMode", tostring(playerHudMode[serial]))
				xmlNodeSetAttribute(playerNode, "nofixEnabled", tostring(playerNofixMode[serial]))
				xmlNodeSetAttribute(playerNode, "nosrefEnabled", tostring(playerNosrefMode[serial]))
			end

        for _, w in ipairs(warps) do
            local node = xmlCreateChild(playerNode, "warp")
            if w.pos then
                xmlNodeSetAttribute(node, "px", w.pos[1] or 0)
                xmlNodeSetAttribute(node, "py", w.pos[2] or 0)
                xmlNodeSetAttribute(node, "pz", w.pos[3] or 0)
            end
            if w.rot then
                xmlNodeSetAttribute(node, "rx", w.rot[1] or 0)
                xmlNodeSetAttribute(node, "ry", w.rot[2] or 0)
                xmlNodeSetAttribute(node, "rz", w.rot[3] or 0)
            end
            if w.vel then
                xmlNodeSetAttribute(node, "vx", w.vel[1] or 0)
                xmlNodeSetAttribute(node, "vy", w.vel[2] or 0)
                xmlNodeSetAttribute(node, "vz", w.vel[3] or 0)
            end
            if w.turn then
                xmlNodeSetAttribute(node, "tvx", w.turn[1] or 0)
                xmlNodeSetAttribute(node, "tvy", w.turn[2] or 0)
                xmlNodeSetAttribute(node, "tvz", w.turn[3] or 0)
            end
            xmlNodeSetAttribute(node, "health", w.health or 1000)
            xmlNodeSetAttribute(node, "model", w.model or 411)
            xmlNodeSetAttribute(node, "nitro", tostring(w.nitro and 1 or 0))
            xmlNodeSetAttribute(node, "nitroCount", w.nitroCount or 1)
            xmlNodeSetAttribute(node, "nitroActive", tostring(w.nitroActive or false))

            if w.cam then
                xmlNodeSetAttribute(node, "camx", w.cam[1] or 0)
                xmlNodeSetAttribute(node, "camy", w.cam[2] or 0)
                xmlNodeSetAttribute(node, "camz", w.cam[3] or 0)
                xmlNodeSetAttribute(node, "lookx", w.cam[4] or 0)
                xmlNodeSetAttribute(node, "looky", w.cam[5] or 0)
                xmlNodeSetAttribute(node, "lookz", w.cam[6] or 0)
            end
        end
    end

    xmlSaveFile(rootNode)
    xmlUnloadFile(rootNode)
    --outputDebugString("[Warps_s] Warps guardados en " .. SAVE_FILE)
end

local function loadWarpsFromFile()
    if not fileExists(SAVE_FILE) then
        --outputDebugString("[Warps_s] No hay archivo XML de warps, creando.")
        return
    end

    local rootNode = xmlLoadFile(SAVE_FILE)
    if not rootNode then
        outputDebugString("[Warps_s] ERROR al abrir archivo XML de warps", 1)
        return
    end

    playerWarps = {}

    for _, playerNode in ipairs(xmlNodeGetChildren(rootNode)) do
        local serial = xmlNodeGetAttribute(playerNode, "serial")
		local hudAttr = tonumber(xmlNodeGetAttribute(playerNode, "hudMode")) or 1
		local noFix = xmlNodeGetAttribute(playerNode, "nofixEnabled") or false
		local nosRef = xmlNodeGetAttribute(playerNode, "nosrefEnabled") or false
		playerHudMode[serial] = hudAttr
		playerNofixMode[serial] = noFix 
		playerNosrefMode[serial] = nosRef
        playerWarps[serial] = {}

        for _, warpNode in ipairs(xmlNodeGetChildren(playerNode)) do
            table.insert(playerWarps[serial], {
                pos = {
                    tonumber(xmlNodeGetAttribute(warpNode, "px")) or 0,
                    tonumber(xmlNodeGetAttribute(warpNode, "py")) or 0,
                    tonumber(xmlNodeGetAttribute(warpNode, "pz")) or 0,
                },
                rot = {
                    tonumber(xmlNodeGetAttribute(warpNode, "rx")) or 0,
                    tonumber(xmlNodeGetAttribute(warpNode, "ry")) or 0,
                    tonumber(xmlNodeGetAttribute(warpNode, "rz")) or 0,
                },
                vel = {
                    tonumber(xmlNodeGetAttribute(warpNode, "vx")) or 0,
                    tonumber(xmlNodeGetAttribute(warpNode, "vy")) or 0,
                    tonumber(xmlNodeGetAttribute(warpNode, "vz")) or 0,
                },
                turn = {
                    tonumber(xmlNodeGetAttribute(warpNode, "tvx")) or 0,
                    tonumber(xmlNodeGetAttribute(warpNode, "tvy")) or 0,
                    tonumber(xmlNodeGetAttribute(warpNode, "tvz")) or 0,
                },
                health = tonumber(xmlNodeGetAttribute(warpNode, "health")) or 1000,
                model = tonumber(xmlNodeGetAttribute(warpNode, "model")) or 411,
                nitro = (tonumber(xmlNodeGetAttribute(warpNode, "nitro")) or 0) > 0,
                nitroCount = tonumber(xmlNodeGetAttribute(warpNode, "nitroCount")) or 1,
                nitroActive = xmlNodeGetAttribute(warpNode, "nitroActive") == "true",
                cam = {
                    tonumber(xmlNodeGetAttribute(warpNode, "camx")) or 0,
                    tonumber(xmlNodeGetAttribute(warpNode, "camy")) or 0,
                    tonumber(xmlNodeGetAttribute(warpNode, "camz")) or 0,
                    tonumber(xmlNodeGetAttribute(warpNode, "lookx")) or 0,
                    tonumber(xmlNodeGetAttribute(warpNode, "looky")) or 0,
                    tonumber(xmlNodeGetAttribute(warpNode, "lookz")) or 0
                }
            })
        end
    end

    xmlUnloadFile(rootNode)
    --outputDebugString("[warp_s] Warps cargados desde " .. SAVE_FILE)
end

addEventHandler("onResourceStart", resourceRoot, function()
    loadWarpsFromFile()
end)

local function stripColorCodes(name)
    return name and name:gsub("#%x%x%x%x%x%x", "") or name
end

addEvent("onPlayerCreateWarp", true)
addEventHandler("onPlayerCreateWarp", root, function(warpData)
    if not warpData or type(warpData) ~= "table" then return end
    local serial = playerSerialMap[client] or getPlayerSerial(client)
    playerWarps[serial] = playerWarps[serial] or {}
    table.insert(playerWarps[serial], warpData)
    --outputDebugString("[warp_s] Warp recibido de " .. getPlayerName(client) .. " (serial " .. serial .. ") total: " .. #playerWarps[serial])
end)

addEvent("onPlayerDeleteWarp", true)
addEventHandler("onPlayerDeleteWarp", root, function(count)
    local serial = playerSerialMap[client] or getPlayerSerial(client)
    if not playerWarps[serial] then return end
    if type(count) == "table" then
    -- rango
    local f, t = count.from, count.to
        for i = t, f, -1 do
            table.remove(playerWarps[serial], i)
        end
    return    
    elseif count == "all" then
        playerWarps[serial] = {}
    else
        for i = 1, (count or 1) do
            table.remove(playerWarps[serial])
        end
    end
end)

addEvent("onPlayerRequestVehicleModel", true)
addEventHandler("onPlayerRequestVehicleModel", root, function(newModel)
    if not client or not isElement(client) then return end
    local veh = getPedOccupiedVehicle(client)
    if not veh then return end

    -- Cambiar el modelo del vehículo EN EL SERVIDOR
    setElementModel(veh, tonumber(newModel))
end)

--[[
addEvent("onPlayerSyncVehicleModel", true)
addEventHandler("onPlayerSyncVehicleModel", root, function(model)
	for _, p in ipairs(getElementsByType("player")) do
			if getPlayerSerial(p) == serial then
				local veh = getPedOccupiedVehicle(p)
				if isElement(veh) then
					setElementModel(veh, model)
					triggerClientEvent("onPlayerForceVehicleModel", root, serial, model)
				end
			end
		end
end)
]]

addEventHandler("onPlayerQuit", root, function()
    playerSerialMap[source] = nil
    -- playerWarps[serial] se mantiene persistente
end)

addEvent("onPlayerRequestAllWarps", true)
addEventHandler("onPlayerRequestAllWarps", root, function(targetName)
    local requester = client
    local cleanName = stripColorCodes(targetName):lower()

    for pl, serial in pairs(playerSerialMap) do
        local name = stripColorCodes(getPlayerName(pl)):lower()
        if name:find(cleanName, 1, false) then
            local warps = playerWarps[serial]
            if warps and #warps > 0 then
                triggerClientEvent(requester, "onReceivePlayerWarps", requester, warps, pl)
                --outputDebugString("[warp_s] " .. getPlayerName(requester) .. " tomo " .. #warps .. " warps de " .. getPlayerName(pl))
                return
            end
        end
    end

    triggerClientEvent(requester, "onReceivePlayerWarps", requester, nil)
end)

addEvent("onPlayerRequestWarpIndex", true)
addEventHandler("onPlayerRequestWarpIndex", root, function(targetName, index)
    local requester = client
    local cleanName = stripColorCodes(targetName):lower()

    for pl, serial in pairs(playerSerialMap) do
        local name = stripColorCodes(getPlayerName(pl)):lower()
        if name:find(cleanName, 1, true) then
            local warps = playerWarps[serial]
            if warps and #warps > 0 then
                local warpIndex = tonumber(index)
                if not warpIndex or warpIndex < 1 or warpIndex > #warps then
                    warpIndex = #warps
                end

                local warp = warps[warpIndex]
                triggerClientEvent(requester, "onReceiveSingleWarp", requester, warp, warpIndex, pl)
                --outputDebugString("[warp_s] " .. getPlayerName(requester) .. " obtuvo warp #" .. warpIndex .. " de " .. getPlayerName(pl))
                return
            end
        end
    end

    triggerClientEvent(requester, "onReceiveSingleWarp", requester, nil)
end)

--Reasingnar cereales y warps
function REASSIGN()
    local retries = 0
    local maxRetries = 5
    local timer

    timer = setTimer(function()
        retries = retries + 1
        local allReady = true

        for _, pl in ipairs(getElementsByType("player")) do
            if isElement(pl) then
                local serial = getPlayerSerial(pl)
                playerSerialMap[pl] = serial
				
				if #playerWarps[serial] >= 1 then return end 
                if playerWarps[serial] and #playerWarps[serial] > 0 then
                    local success = triggerClientEvent(pl, "onReceivePlayerWarps", pl, playerWarps[serial], pl)
                    if success then
                        --outputDebugString("[Warps_s] Enviados " .. #playerWarps[serial] .. " warps a " .. getPlayerName(pl))
                    else
                        --outputDebugString("[Warps_s] Falló al enviar waprs de " .. getPlayerName(pl) .. " (intento " .. retries .. ")")
                        allReady = false
                    end
                else
                    --outputDebugString("[Warps_s] Registrado jugador sin warps previos: " .. getPlayerName(pl))
                end
            end
        end

        if allReady or retries >= maxRetries then
            if allReady then
                --outputDebugString("[Warps_s] Todos los warps enviados correctamente.")
            else
                --outputDebugString("[Warps_s] Timer detenido tras " .. retries .. " intentos.")
            end
            killTimer(timer)
        end
    end, 750, 0)
end

addEventHandler("onResourceStart", resourceRoot, REASSIGN)

addEvent("onWarpClientReady", true)
addEventHandler("onWarpClientReady", root, function()
    local pl = client
    if not isElement(pl) then return end
    local serial = getPlayerSerial(pl)
    playerSerialMap[pl] = serial
	
	if playerHudMode[serial] and playerNofixMode[serial] and playerNosrefMode[serial] then
		triggerClientEvent(pl, "onReceiveMisc", pl, playerHudMode[serial], playerNofixMode[serial], playerNosrefMode[serial])
	end
	
    if playerWarps[serial] and #playerWarps[serial] > 0 then
        local success = triggerClientEvent(pl, "onReceivePlayerWarps", pl, playerWarps[serial], pl)
        if success then
            --outputDebugString("[warp_s] Rejoin: Enviados " .. #playerWarps[serial] .. " warps a " .. getPlayerName(pl))
        else
            --outputDebugString("[warp_s] Listo cliente pero fallo triggerClientEvent para " .. getPlayerName(pl))
        end
    else
        --outputDebugString("[warp_s] Cliente listo: sin warps previos para " .. getPlayerName(pl))
    end

end)

addEvent("onClientUpdateHudMode", true)
addEventHandler("onClientUpdateHudMode", root, function(newHudMode)
    local serial = playerSerialMap[client] or getPlayerSerial(client)
    playerHudMode[serial] = tonumber(newHudMode) or 1
end)


addEvent("onClientUpdateMutators", true)
addEventHandler("onClientUpdateMutators", root, function(nofixMode, nosrefMode)
    local serial = playerSerialMap[client] or getPlayerSerial(client)
    playerNofixMode[serial] = nofixMode or false
    playerNosrefMode[serial] = nosrefMode or false
end)


addEventHandler("onResourceStop", resourceRoot, function()
    for pl, _ in pairs(playerSerialMap) do
        if not isElement(pl) then
            playerSerialMap[pl] = nil
        end
    end
	saveWarpsToFile()
end)

--DEBUG
addEvent("onRequestWarpSend", true)
addEventHandler("onRequestWarpSend", root, function(targetName, warpData)
    local sender = client
    if not isElement(sender) or not targetName or not warpData then return end
    local cleanTarget = targetName:gsub("#%x%x%x%x%x%x", ""):lower()
    local targetPlayer = nil

    for _, pl in ipairs(getElementsByType("player")) do
        local cleanName = getPlayerName(pl):gsub("#%x%x%x%x%x%x", ""):lower()
        if cleanName:find(cleanTarget, 1, true) then
            targetPlayer = pl
            break
        end
    end

    if not targetPlayer then
        outputChatBox(rtool.. " #FF0000Player not found: #FFFFFF"..targetName, sender, 255, 46, 255, true)
        return
    end

    triggerClientEvent(targetPlayer, "onReceivePlayerWarps", sender, warpData, sender)

    local senderName = getPlayerName(sender):gsub("#%x%x%x%x%x%x", "")
    local targetNameClean = getPlayerName(targetPlayer):gsub("#%x%x%x%x%x%x", "")

    outputChatBox("ENVIARWAPRS"..targetNameClean, sender, 255, 46, 255, true)
    outputChatBox("TE ENVÍE MIS WARPS SIN CONSENTIMIENTO atte "..senderName, targetPlayer, 255, 46, 255, true)
end)

addCommandHandler("deb", function(player)
    outputChatBox("=== SOPA DE CEREALES ===", player)
    local total = 0
    for serial, warps in pairs(playerWarps) do
        outputChatBox(serial .. ": " .. tostring(#warps), player)
        total = total + #warps
    end
    outputChatBox("Total warps: " .. total, player)
    saveWarpsToFile()
end)
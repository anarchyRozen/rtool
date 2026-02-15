local captureInterval = 1000 -- less is more smooth track, but this enough. Under 1000 is overkill.
local xmlFilePath = "usertool.xml"
local refX, refY = 2560, 1440  
local screenW, screenH = guiGetScreenSize()
local scaleX, scaleY = screenW / refX, screenH / refY
local globalScale = math.min(scaleX, scaleY)
local boxW, boxH = 500 * scaleX, 500 * scaleY
local margin = 200 * globalScale


local clusterRadius = 200 
local maxClusterStep = 1200^2 

local trackModels = {
    [3458]=true, [8558]=true, [8557]=true,
    [8838]=true, [6959]=true, [7657]=true, [18450]=true
}

local circuitVisible = true
local recording = false
local rewinding = false
local lastCapture = 0
local circuitPoints = {}
local nearestIndex = nil
local hoverIndex = nil
-- local xmlRootNode
local circuitScale = 5

local cursorForced = false 

local circuitsNode

function ensureXML()
    local _, group = loadUsertoolGroup("circuits")
    circuitsNode = group
end

addEventHandler("onClientResourceStart", resourceRoot, ensureXML)
--GENERATE MAP.
function generateCircuitFromObjects(clusterRadius)
    circuitPoints = {}
    local objs = getElementsByType("object")
    local clusters = {}

    for _, obj in ipairs(objs) do
        local model = getElementModel(obj)
        if trackModels[model] then
            local x,y,z = getElementPosition(obj)
            local added = false
            for _, cluster in ipairs(clusters) do
                local dx,dy,dz = x-cluster.cx, y-cluster.cy, z-cluster.cz
                if dx*dx+dy*dy+dz*dz <= clusterRadius*clusterRadius then
                    cluster.sumx = cluster.sumx + x
                    cluster.sumy = cluster.sumy + y
                    cluster.sumz = cluster.sumz + z
                    cluster.count = cluster.count + 1
                    cluster.cx = cluster.sumx/cluster.count
                    cluster.cy = cluster.sumy/cluster.count
                    cluster.cz = cluster.sumz/cluster.count
                    added = true
                    break
                end
            end
            if not added then
                table.insert(clusters, {
                    sumx=x, sumy=y, sumz=z,
                    count=1, cx=x, cy=y, cz=z
                })
            end
        end
    end

    local rawPoints = {}
    for _, c in ipairs(clusters) do
        table.insert(rawPoints, {x=c.cx, y=c.cy, z=c.cz})
    end

    -- orden secuencial
    local ignored = 0
    if #rawPoints > 0 then
        local ordered = {}
        local used = {}
        local current = 1
        table.insert(ordered, rawPoints[current])
        used[current] = true

        while #ordered < #rawPoints do
            local nearest, minDist = nil, math.huge
            for i, p in ipairs(rawPoints) do
                if not used[i] then
                    local dx = ordered[#ordered].x - p.x
                    local dy = ordered[#ordered].y - p.y
                    local dz = ordered[#ordered].z - p.z
                    local d = dx*dx + dy*dy + dz*dz
                    if d < minDist then
                        minDist, nearest = d, i
                    end
                end
            end

            if nearest and minDist <= maxClusterStep then
                table.insert(ordered, rawPoints[nearest])
                used[nearest] = true
            else
                -- ignore far clusters
                if nearest then
                    used[nearest] = true
                    ignored = ignored + 1
                else
                    break
                end
            end
        end

        circuitPoints = ordered
    end

    outputChatBox(rtool.."Generated circuit with "..#circuitPoints.." clusters. Ignored "..ignored.." outliers.", 200,200,255,true)
end


--hold MOUSE2 to be able to move around the circuit while playing (not ideal)
bindKey("mouse2", "down", function()
    if isPedInVehicle(localPlayer) and circuitVisible and #circuitPoints > 0 then
        showCursor(true)
        cursorForced = true
    end
end)

bindKey("mouse2", "up", function()
    if cursorForced then
        showCursor(false)
        cursorForced = false
    end
end)

--IMPORT WARPS
local warpsFilePath = "rtool_warps.xml"

function importWarps(name)
    if not name or name == "" then
        outputChatBox(rtool.."Usage: /map import [warps-name]", 200,200,255,true)
        return
    end

    if not fileExists(warpsFilePath) then
        outputChatBox(rtool.."Warps file not found ("..warpsFilePath..")", 255,100,100,true)
        return
    end

    local xml = xmlLoadFile(warpsFilePath)
    if not xml then
        outputChatBox(rtool.."Failed to load warps file", 255,100,100,true)
        return
    end

    local node = xmlFindChild(xml, name, 0)
    if not node then
        outputChatBox(rtool.."No warps found for '"..name.."'", 255,100,100,true)
        xmlUnloadFile(xml)
        return
    end

    local imported = 0
    circuitPoints = {} -- reemplaza circuito actual
    for _, warp in ipairs(xmlNodeGetChildren(node)) do
        if xmlNodeGetName(warp) == "warp" then
            local px = tonumber(xmlNodeGetAttribute(warp, "px"))
            local py = tonumber(xmlNodeGetAttribute(warp, "py"))
            local pz = tonumber(xmlNodeGetAttribute(warp, "pz"))
            if px and py and pz then
                table.insert(circuitPoints, {x=px, y=py, z=pz})
                imported = imported + 1
            end
        end
    end

    xmlUnloadFile(xml)

    if imported > 0 then
        outputChatBox(rtool.."Imported "..imported.." warps into circuit from '#33cc33"..name.."#FFFFFF'", 200,200,255,true)
    else
        outputChatBox(rtool.."No valid positions found in '"..name.."'", 255,100,100,true)
    end
end

function previewUIHandler(command, args)
    if command == "record" then
        executeCommandHandler("rmap", "record")
    elseif command == "show" then
        executeCommandHandler("rmap", "show")
	elseif command == "plist" then
        listCircuits()
    elseif command == "clear" then
        executeCommandHandler("rmap", "clear")
    elseif command == "save" then
        executeCommandHandler("rmap", "save "..(args and args[1] or ""))
    elseif command == "load" then
        executeCommandHandler("rmap", "load "..(args and args[1] or ""))
    elseif command == "import" then
        executeCommandHandler("rmap", "import "..(args and args[1] or ""))
    elseif command == "generate" then
        local str = ""
        if args then str = table.concat(args, " ") end
        executeCommandHandler("rmap", "generate "..str)
    elseif command == "smooth" then
        executeCommandHandler("rmap", "smooth "..(args and args[1] or ""))
    elseif command == "zoom" then
        executeCommandHandler("rmap", "zoom "..(args and args[1] or ""))
    end
end


--Cmds old
addCommandHandler("rmap", function(_, arg1, arg2, arg3)
    if arg1 == "record" then
        if not recording and isPedInVehicle(localPlayer) then
            circuitPoints = {}
            recording = true
            lastCapture = getTickCount()
            outputChatBox(rtool.."Recording started.", 200, 200, 255, true)
        elseif not isPedInVehicle(localPlayer) then
			outputChatBox(rtool.."You need to be in a vehicle to start recording.", 200, 200, 255, true)
		else
            recording = false
            outputChatBox(rtool.."Recording stopped ("..#circuitPoints.." pts).", 200, 200, 255, true)
        end
    elseif arg1 == "show" then
        circuitVisible = not circuitVisible
        if circuitVisible then
            outputChatBox(rtool.."Circuit visible.", 200, 200, 255, true)
        else
            outputChatBox(rtool.."Circuit hidden.", 200, 200, 255, true)
        end
    elseif arg1 == "clear" then
        circuitPoints = {}
        outputChatBox(rtool.."Circuit cleared.", 200, 200, 255, true)
    elseif arg1 == "save" then
		if not arg2 then
		outputChatBox(rtool.."Usage: /rmap save [name]", 200, 200, 255, true)
		return end
        if tostring(arg2):find("^%d") then
        outputChatBox(rtool.."#FF0000ERROR! #FFFFFFCircuit name cannot start with a number", 255, 100, 100, true)
        return end
        saveCircuit(arg2)
    elseif arg1 == "load" then
		if not arg2 then
		outputChatBox(rtool.."Usage: /rmap load [name]", 200, 200, 255, true)
		return end
        loadCircuit(arg2)
    elseif arg1 == "import" then
		if not arg2 then
		outputChatBox(rtool.."Usage: /rmap import [warpIndexName]", 200, 200, 255, true)
		return end
        importWarps(arg2)
	elseif arg1 == "generate" then
		if not arg2 then
		outputChatBox(rtool.."Usage: /rmap generate [radius] [smooth factor]", 200, 200, 255, true)
		return end
        generateCircuitFromObjects(arg2)
		if arg3 then
		smoothCircuit(arg3)
		end
	elseif arg1 == "smooth" then
		if not arg2 then
		outputChatBox(rtool.."Usage: /rmap smooth [factor]", 200, 200, 255, true)
		return end
        smoothCircuit(arg2)
    elseif arg1 == "zoom" then
        local val = tonumber(arg2)
        if val and val > 0 then
            circuitScale = val
            outputChatBox(rtool.."Circuit zoom set to #33cc33"..val, 200, 200, 255, true)
        else
            outputChatBox(rtool.."Usage: /rmap zoom [num (default 5)]", 200, 200, 255, true)
        end
    else
        outputChatBox(rtool.."Usage: /rmap record | generate [radius]", 200, 200, 255, true)
		outputChatBox(rtool.."Usage: /rmap show | clear | save | load | zoom [n]", 200, 200, 255, true)
		
    end
end)


-- CAPTURA DE PUNTOS
local rewindOffset = 5.0 -- tolerancia para borrar puntos en rewind

function updateCircuit()
    if not recording or not isPedInVehicle(localPlayer) then return end

    local veh = getPedOccupiedVehicle(localPlayer)
    if not veh then return end
    local x,y,z = getElementPosition(veh)

    if isRewinding then
		--outputChatBox("rewind on")
        for i = #circuitPoints, 1, -1 do
            local p = circuitPoints[i]
            local dx,dy,dz = x-p.x, y-p.y, z-p.z
            if dx*dx + dy*dy + dz*dz <= rewindOffset*rewindOffset then
                table.remove(circuitPoints, i)
                break -- important., only 1 per frame
            end
        end
        return
    end

    -- Captura normal de puntos (si no está en rewind)
    local now = getTickCount()
    if now - lastCapture >= captureInterval then
        table.insert(circuitPoints, {x=x,y=y,z=z})
        lastCapture = now
    end
end
addEventHandler("onClientRender", root, updateCircuit)

-- Rewind integration (unnecesary now? idk)
addEvent("onClientRewindStateChange", true)
addEventHandler("onClientRewindStateChange", root, function(state)
    if state == "start" then
        rewinding = true
    elseif state == "stop" then
        rewinding = false
        lastCapture = getTickCount()
    end
end)


-- RENDER DEL CIRCUITO
addEventHandler("onClientRender", root, function()
    if not circuitVisible or #circuitPoints < 2 then return end

    -- Calcular bounding box
    local minX, maxX, minY, maxY, minZ, maxZ = circuitPoints[1].x, circuitPoints[1].x, circuitPoints[1].y, circuitPoints[1].y, circuitPoints[1].z, circuitPoints[1].z
    for _, p in ipairs(circuitPoints) do
        if p.x < minX then minX = p.x end
        if p.x > maxX then maxX = p.x end
        if p.y < minY then minY = p.y end
        if p.y > maxY then maxY = p.y end
        if p.z < minZ then minZ = p.z end
        if p.z > maxZ then maxZ = p.z end
    end
    local rangeX, rangeY, rangeZ = maxX-minX, maxY-minY, maxZ-minZ
    local diffZ = math.max(1, rangeZ)

    local autoScale = math.min((boxW-margin*2)/math.max(1,rangeX), (boxH-margin*2)/math.max(1,rangeY))
    local finalScale = autoScale * circuitScale
    local centerX, centerY = (minX+maxX)/2, (minY+maxY)/2

    local baseX = screenW - boxW/2 - margin
    local baseY = screenH - boxH/2 - margin

    -- Líneas
    for i=1, #circuitPoints-1 do
        local a, b = circuitPoints[i], circuitPoints[i+1]
        local ratioA = (a.z-minZ)/diffZ
        local ratioB = (b.z-minZ)/diffZ
        local colorA = tocolor(255*ratioA, 100, 255*(1-ratioA), 200)
        local colorB = tocolor(255*ratioB, 100, 255*(1-ratioB), 200)

        local sx1 = baseX + (a.x-centerX)*finalScale
        local sy1 = baseY + (a.y-centerY)*finalScale
        local sx2 = baseX + (b.x-centerX)*finalScale
        local sy2 = baseY + (b.y-centerY)*finalScale
        dxDrawLine(sx1, sy1, sx2, sy2, colorA, 2)
        dxDrawLine(sx1, sy1, sx2, sy2, colorB, 2)
    end

    -- Jugador
    --if isPedInVehicle(localPlayer) then
        local px,py,pz = getElementPosition(localPlayer)
        nearestIndex = getNearestPointIndex(px,py,pz)
        if nearestIndex then
            local pt = circuitPoints[nearestIndex]
            local sx = baseX + (pt.x-centerX)*finalScale
            local sy = baseY + (pt.y-centerY)*finalScale
            dxDrawCircle(sx, sy, 6, 0, 360, tocolor(255,255,0,255), tocolor(255,255,0,255), 3)
        end
    --end

    -- Hover con el mouse
    local cx,cy = getCursorPosition()
    if cx and cy then
        cx,cy = cx*screenW, cy*screenH

        -- calcular area real del circuito
        local halfW = rangeX*finalScale/2
        local halfH = rangeY*finalScale/2
        local minSX, maxSX = baseX-halfW, baseX+halfW
        local minSY, maxSY = baseY-halfH, baseY+halfH

        if cx > minSX and cx < maxSX and cy > minSY and cy < maxSY then
            local nearest, dist = nil, math.huge
            for i, p in ipairs(circuitPoints) do
                local sx = baseX + (p.x-centerX)*finalScale
                local sy = baseY + (p.y-centerY)*finalScale
                local d = (cx-sx)^2+(cy-sy)^2
                if d < dist then
                    dist, nearest = d, i
                end
            end
            hoverIndex = nearest
            if hoverIndex then
                local pt = circuitPoints[hoverIndex]
                local sx = baseX + (pt.x-centerX)*finalScale
                local sy = baseY + (pt.y-centerY)*finalScale
                dxDrawCircle(sx, sy, 8, 0, 360, tocolor(0,150,255,255), tocolor(0,150,255,255), 3)
            end
        else
            hoverIndex = nil
        end
    end
end)

-- Suavizado de circuito
function smoothCircuit(arg2, arg3)
	local factor = arg2 or arg3 or nil
    if #circuitPoints<3 then return end
    local newPts={}
    for i=1,#circuitPoints do
        local sx,sy,sz=0,0,0
        local count=0
        for j=i-factor,i+factor do
            if circuitPoints[j] then
                sx=sx+circuitPoints[j].x
                sy=sy+circuitPoints[j].y
                sz=sz+circuitPoints[j].z
                count=count+1
            end
        end
        table.insert(newPts,{x=sx/count,y=sy/count,z=sz/count})
    end
    circuitPoints=newPts
    outputChatBox(rtool.."Circuit smoothed with factor "..factor,200,200,255,true)
end

function getNearestPointIndex(px, py, pz)
    local minDist, idx = math.huge, nil
    for i, p in ipairs(circuitPoints) do
        local dist = (px-p.x)^2 + (py-p.y)^2 + (pz-p.z)^2
        if dist < minDist then
            minDist, idx = dist, i
        end
    end
    return idx
end

-- Click en el circuito
addEventHandler("onClientClick", root, function(btn, state, cx, cy)
	if not circuitVisible or #circuitPoints < 2 then return end
    if btn ~= "left" or state ~= "down" or not hoverIndex then return end
    local pt = circuitPoints[hoverIndex]
    if not pt then return end

    if isPedInVehicle(localPlayer) then
        local veh = getPedOccupiedVehicle(localPlayer)
        if veh then
            setElementPosition(veh, pt.x, pt.y, pt.z+1)
            outputChatBox(rtool.."Vehicle moved to circuit point", 200,200,255,true)
        end
    elseif getResourceFromName("editor_main") and getResourceState(getResourceFromName("editor_main")) == "running" then
        setCameraMatrix(pt.x, pt.y-10, pt.z+5, pt.x, pt.y, pt.z) -- versión simplificada autosnap
        outputChatBox(rtool.."Camera snapped to circuit point", 200,200,255,true)
    end
end)

-- Guardar / cargar

function saveCircuit(name)
    ensureXML()

    local old = xmlFindChild(circuitsNode, name, 0)
    if old then xmlDestroyNode(old) end

    local node = xmlCreateChild(circuitsNode, name)

    for _, p in ipairs(circuitPoints) do
        local entry = xmlCreateChild(node, "point")
        xmlNodeSetAttribute(entry, "x", p.x)
        xmlNodeSetAttribute(entry, "y", p.y)
        xmlNodeSetAttribute(entry, "z", p.z)
    end

    xmlSaveFile(ensureUsertoolRoot())
end

function loadCircuit(name)
    ensureXML()

    local node = xmlFindChild(circuitsNode, name, 0)
    if not node then
        outputChatBox(rtool.."No circuit '"..name.."'",255,200,200,true)
        return
    end

    circuitPoints = {}

    for _, c in ipairs(xmlNodeGetChildren(node)) do
        if xmlNodeGetName(c) == "point" then
            table.insert(circuitPoints, {
                x=tonumber(xmlNodeGetAttribute(c,"x")),
                y=tonumber(xmlNodeGetAttribute(c,"y")),
                z=tonumber(xmlNodeGetAttribute(c,"z"))
            })
        end
    end
end


function listCircuits()
	ensureXML()
    if not circuitsNode then 
        outputChatBox(rtool.."#FF0000 ERROR: #FFFFFFNo circuit save file loaded", 115, 46, 255, true)
        return 
    end

    local lists = xmlNodeGetChildren(circuitsNode)
    if #lists == 0 then
        outputChatBox(rtool.."#FFFFFFNo saved circuits found.", 115, 46, 255, true)
        return
    end

    outputChatBox(rtool.."#FFFFFFCircuits found ("..#lists.."):", 115, 46, 255, true)
    for i, listNode in ipairs(lists) do
        local listName = xmlNodeGetName(listNode)
        local count = #xmlNodeGetChildren(listNode)
        outputChatBox(i..". #33cc33"..listName.."#FFFFFF - "..count.." Points", 0, 102, 255, true)
    end
end
addCommandHandler("plist", listCircuits)


addEventHandler("onClientResourceStart", resourceRoot, function()
    if type(registerUIModule) == "function" then
        registerUIModule("Preview", {
            color = tocolor(217, 169, 91, 255),
            options = {
                {label = "Record Circuit", command = "record", hideUI = true},
                {label = "Show Circuit", command = "show"},
				{label = "List Saved Circuits", command = "plist"},
                {label = "Load Circuit", command = "load", args = true, hideUI = true},
				{label = "Save Circuit", command = "save", args = true, hideUI = true},
                {label = "Import Warps", command = "import", args = true, hideUI = true},
                {label = "Generate Circuit", command = "generate", args = true},
                {label = "Smooth Circuit", command = "smooth", args = true},
				{label = "Clear Circuit", command = "clear"},
                {label = "Zoom Circuit", command = "zoom", args = true},
            },
            callback = function(command, args)
                previewUIHandler(command, args)
            end
        })
    end
end)

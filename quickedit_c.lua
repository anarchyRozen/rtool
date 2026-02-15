local editorResource = "editor_main"
-- local quickEditMode = false --global
local qeon, qeoff = dxCreateTexture("img/qeon.png"), dxCreateTexture("img/qeoff.png")

local originalRot, originalScale, originalModel = {}, 1, nil
local selectedObj = nil
local drawText = ""
local applyMessageTime, applyMessageDuration = 0, 2000
local quickRedoHistoryLimit = 20
local showXYZLines, lastShiftState, redoAdd, fakeClone, offsetEditing, loadedLists = true, false, false, false, false, false
local offsetStartPos = nil

--TO DO: Preview size / type marker. block keys cuando se escribe en col OURRRR. Ya por último añadir quick redo support

-- Variables for UI 
local axisOrderObject = {"MODEL", "SCALE", "DOUBLESIDE", "COLLISIONS", "X", "Y", "Z", "ZERO", "OFFSET", "CLONE"}
local axisOrderRacepickup = {"REPAIR", "NITRO", "VEHICLE", "CLONE"}
local axisOrderMarker = {"SIZE", "TYPE", "COLOUR", "CLONE"}
local markerTypeSelectionActive = false
local markerTypeIndex = 1
local markerTypes = {"arrow", "checkpoint", "corona", "cylinder", "ring"}
local editingAxis, axisIndex, scrollOffset, targetScrollOfset, animationSpeed, lastAxisUsed, lastModeIndex = 1, 1, 0, 0, 0.15, nil, nil
local maxVisible = 6 -- Max amount of visible 'AXISES' at a time
local lastTick = getTickCount()
local refX, refY = 2560, 1440
local sx, sy = guiGetScreenSize()
local scaleX, scaleY = sx / refX, sy / refY
local globalScale = math.min(scaleX, scaleY)
local quickRedoHistory = {}
local quickRedoFadeStart = getTickCount()
local quickRedoFadeDuration = 5000

local quickRedoSavesFile = "usertool.xml"
local quickRedoSaves = {}
local quickRedoMenuActive = false
local quickRedoMenuIndex = 1
local quickRedoMenuVisibleLists = {}

local axisColors = {
    NITRO = tocolor(39, 180, 245, alpha),
    REPAIR = tocolor(49, 245, 39, alpha),
    VEHICLE = tocolor(245, 204, 39, alpha),
    X = tocolor(227, 27, 70, alpha),
    Y = tocolor(27, 227, 32, alpha),
    Z = tocolor(27, 117, 227, alpha),
    ZERO = tocolor(227, 184, 27, alpha),
    SCALE = tocolor(0, 200, 255, alpha),
    SIZE = tocolor(0, 200, 255, alpha),
    DOUBLESIDE = tocolor(180, 0, 255, alpha),
    MODEL = tocolor(255, 165, 0, alpha),
    TYPE = tocolor(255, 165, 0, alpha),
    COLLISIONS = tocolor(255, 100, 100, alpha),
    COLOUR = tocolor(255, 100, 100, alpha),
	OFFSET = tocolor(139, 87, 255, alpha),
	CLONE = tocolor(94, 137, 255, alpha)
}

function isOffsetLockActive()
    return (editingAxis == "OFFSET" and offsetEditing)
end

addCommandHandler("fakeclone", function()
    fakeClone = not fakeClone
    outputChatBox(rtool .. "Clone Dummy: " .. (fakeClone and "#33cc33ON" or "#ff6666OFF"), 200, 200, 255, true)
end)

local function deg2rad(d) return d * math.pi / 180 end

function getPositionFromElementOffset(m,offX,offY,offZ)
    local m = m  -- Get the matrix
    local x = offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1]  -- Apply transform
    local y = offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2]
    local z = offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]
    return x, y, z                               -- Return the transformed point
end

function getSelectedEditorObject()
    if getResourceFromName(editorResource) then
        return exports[editorResource]:getSelectedElement()
    end
    return nil
end

function supportedElement(element)
if not element then return false end
    local etype = getElementType(element)
    if (etype == "marker" or etype == "object" or etype == "racepickup" or etype == "checkpoint") then
        return true
    else
        return false
    end
end

function getAxisList(element)
    if isElement(element) then
        local etype = getElementType(element)
        if etype == "object" then
            return axisOrderObject
        elseif etype == "marker" or etype == "checkpoint" then
            return axisOrderMarker
        elseif etype == "racepickup" then
            return axisOrderRacepickup
        end
    end
end

local redoAddStarted = false

function addQuickRedoAction(data)
    quickRedoFadeStart = getTickCount()

    if not RedoAdd then
        quickRedoHistory = {}
        redoAddStarted = false
    else
        if not redoAddStarted then
            quickRedoHistory = {}
            redoAddStarted = true
        end
    end

    if type(data.value) == "string" then
        local expr = data.value:match("^[%+%-]%d+$")
        if expr then
            data.expression = expr
            data.value = nil
        end
    end
	if quickRedoHistoryLimit - 1 == #quickRedoHistory then 
		outputChatBox(rtool.."You have reached the limit of Redo actions #ffcc00" ..#quickRedoHistory + 1 .. "/" ..quickRedoHistoryLimit, 200, 200, 255, true)
		outputChatBox("#FFFFFFBuy more storage at..", 200, 200, 255, true) 
		outputChatBox("#FFFFFFjk, change '#33cc33quickRedoHistoryLimit#FFFFFF' in '#0066ffquickedit_c.lua#FFFFFF'", 200, 200, 255, true)
	end

    table.insert(quickRedoHistory, data)
end

------------------------
-- QUICK REDO PRESETS
------------------------

function savePresets()
    local root, listsNode = loadUsertoolGroup("lists")

    -- Limpiar listas existentes
    for _, n in ipairs(xmlNodeGetChildren(listsNode)) do
        xmlDestroyNode(n)
    end

    for name, list in pairs(quickRedoSaves) do
        local node = xmlCreateChild(listsNode, "list")
        xmlNodeSetAttribute(node, "name", name)
        xmlNodeSetAttribute(node, "count", tostring(#list))

        for _, action in ipairs(list) do
            local actNode = xmlCreateChild(node, "action")
            xmlNodeSetValue(actNode, toJSON(action, true))
        end

        if list._ids then
            local idsNode = xmlCreateChild(node, "ids")
            xmlNodeSetValue(idsNode, table.concat(list._ids, ","))
        end
    end

    xmlSaveFile(root)
end

function loadPresets()
    local _, listsNode = loadUsertoolGroup("lists")
    quickRedoSaves = {}
    loadedLists = true

    for _, node in ipairs(xmlNodeGetChildren(listsNode)) do
        local name = xmlNodeGetAttribute(node, "name")
        quickRedoSaves[name] = {}

        for _, child in ipairs(xmlNodeGetChildren(node)) do
            local tag = xmlNodeGetName(child)

            if tag == "action" then
                local data = fromJSON(xmlNodeGetValue(child))
                if data then table.insert(quickRedoSaves[name], data) end
            elseif tag == "ids" then
                local ids = {}
                for id in xmlNodeGetValue(child):gmatch("%d+") do
                    table.insert(ids, tonumber(id))
                end
                quickRedoSaves[name]._ids = ids
            end
        end
    end
end

addEventHandler("onClientResourceStart", resourceRoot, loadPresets)

function getModelPresets(model)
    local matches = {}
    for name, list in pairs(quickRedoSaves) do
        if list._ids then
            for _, id in ipairs(list._ids) do
                if id == model then
                    table.insert(matches, { name = name, count = #list })
                    break
                end
            end
        end
    end
    return matches
end

------------------------
-- START AXIS
------------------------

function startAxisEdit(axis)
selectedObj = getSelectedEditorObject()
if not isElement(selectedObj) then return end
local etype = getElementType(selectedObj)

if not supportedElement(selectedObj) then return end
    editingAxis, lastAxisUsed, lastModeIndex = axis, axis, axisIndex
    inputBuffer = ""
    quickRedoMenuActive = false
    markerTypeSelectionActive = false
    if etype == "marker" or etype == "checkpoint" then
        if axis == "SIZE" then
            local size = exports.edf:edfGetElementProperty(selectedObj, "size") or "1.0"
            drawText = "SIZE: " .. tostring(size)
        elseif axis == "TYPE" then
            local mtype = exports.edf:edfGetElementProperty(selectedObj, "type") or markerTypes[1]
            markerTypeIndex = 1
            for i, t in ipairs(markerTypes) do
                if t == mtype then markerTypeIndex = i break end
            end
            if markerTypeSelectionActive then
                drawText = "TYPE: " .. markerTypes[markerTypeIndex] .. " (< "..KEY_NEXT_AXIS.."/"..KEY_PREV_AXIS.." >)"
            else
                drawText = "TYPE: " .. markerTypes[markerTypeIndex] .. " ("..string.upper(KEY_CONFIRM)..")"
            end
            -- markerTypeSelectionActive = true
        elseif axis == "COLOUR" then
            if etype == "marker" then
                local color = exports.edf:edfGetElementProperty(selectedObj, "color")
                local r, g, b = unpack(color)
                local hex = string.format("%.2X%.2X%.2X", r, g, b)
                drawText = "COLOUR: " .. hex
            else
                local color = exports.edf:edfGetElementProperty(selectedObj, "color")
                drawText = "COLOUR: " .. color
            end
        elseif axis == "CLONE" then drawText = (fakeClone and "FAKE CLONE" or "CLONE")
        end
        typingMode = true
        return

    elseif etype == "racepickup" then
        if axis == "NITRO" then
            drawText = "NITRO"
        elseif axis == "REPAIR" then
            drawText = "REPAIR"   
        elseif axis == "VEHICLE" then
            local vehicleID = exports.edf:edfGetElementProperty(selectedObj, "vehicle") or "522"
            drawText = "VEHICLE: " .. tostring(vehicleID).. " ["..getVehicleNameFromModel(vehicleID).."]"
        elseif axis == "CLONE" then drawText = (fakeClone and "FAKE CLONE" or "CLONE")
        end
        typingMode = true
        return
    end
    -- Object logic
    local rx, ry, rz = getElementRotation(selectedObj)
    originalRot = {rx, ry, rz}
    originalScale = getObjectScale(selectedObj)
    originalModel = getElementModel(selectedObj)
    if axis == "ZERO" then drawText = "ZERO"
    elseif axis == "SCALE" then drawText = "SCALE: " .. string.format("%.2f", originalScale)
    elseif axis == "DOUBLESIDE" then drawText = "DOUBLESIDE: " .. tostring(exports.edf:edfGetElementProperty(selectedObj, "doublesided") or false)
    elseif axis == "MODEL" then drawText = "MODEL: " .. originalModel
    elseif axis == "COLLISIONS" then drawText = "COLLISIONS: " .. tostring(exports.edf:edfGetElementProperty(selectedObj, "collisions") or "true")
    elseif axis == "OFFSET" then drawText = "OFFSET:"
    elseif axis == "CLONE" then drawText = (fakeClone and "FAKE CLONE" or "CLONE")
    else
        local currentVal = axis == "X" and rx or axis == "Y" and ry or rz
        drawText = axis .. ": " .. string.format("%.2f", currentVal)
    end
    typingMode = true
end

addEventHandler("onClientCharacter", root, function(char)
    if not typingMode or not editingAxis or isOffsetLockActive() then return end
    local selObj = getSelectedEditorObject()
    if isElement(selObj) and (getElementType(selObj) == "marker" or getElementType(selObj) == "checkpoint") then
        if editingAxis == "SIZE" then
            if tonumber(char) or char == "." then
                inputBuffer = inputBuffer .. char
                drawText = "SIZE: " .. inputBuffer
            end
        elseif editingAxis == "COLOUR" then
            if char:match("[A-Fa-f0-9]" ) then
                inputBuffer = inputBuffer .. char
                drawText = "COLOUR: " .. inputBuffer
            end
        end
        return
    end
    if not tonumber(char) and not char:match("^[.+-]$") then return end
    if ({COLLISIONS=true, DOUBLESIDE=true, OFFSET=true, CLONE=true, ZERO=true, NITRO=true, REPAIR=true})[editingAxis] then return end
    inputBuffer = inputBuffer .. char
    drawText = editingAxis .. ": " .. inputBuffer
    if editingAxis == "X" or editingAxis == "Y" or editingAxis == "Z" then
        local preview = tonumber(inputBuffer)
        if preview and selectedObj then
            local rot = {originalRot[1], originalRot[2], originalRot[3]}
            if editingAxis == "X" then rot[1] = preview elseif editingAxis == "Y" then rot[2] = preview elseif editingAxis == "Z" then rot[3] = preview end
            setElementRotation(selectedObj, unpack(rot))
        end
    elseif editingAxis == "SCALE" then
        local preview = tonumber(inputBuffer)
        if preview and selectedObj then setObjectScale(selectedObj, preview) end
    elseif editingAxis == "VEHICLE" then
        local vehicleID = inputBuffer
        if vehicleID and #vehicleID == 3 then
                if (tonumber(vehicleID) <= 611 and tonumber(vehicleID) >= 400) then
                    drawText = "VEHICLE: " .. tostring(vehicleID).. " ["..getVehicleNameFromModel(vehicleID).."]"
                end
            end
    end
end)

function resetInput()
    if RedoAdd then
        inputBuffer = ""
        axis = lastAxisUsed
        startAxisEdit(getAxisList(selectedObj)[axisIndex])
    else
        typingMode, editingAxis, quickEditMode, drawText, inputBuffer, lastAxisUsed = false, nil, false, "", "", 0
    end
end


local function drawOutlinedText(text, x, y, color, scale)
    if not text or type(text) ~= "string" or not x or not y then return end
    local outline = 2.5
    local font = "default-bold"
    local textScale = scale or 2.2
    local alpha = tocolor(0, 0, 0, 255)
    dxDrawText(text, x - outline, y, x - outline, y, alpha, textScale, font, "left", "top")
    dxDrawText(text, x + outline, y, x + outline, y, alpha, textScale, font, "left", "top")
    dxDrawText(text, x, y - outline, x, y - outline, alpha, textScale, font, "left", "top")
    dxDrawText(text, x, y + outline, x, y + outline, alpha, textScale, font, "left", "top")
    dxDrawText(text, x, y, x, y, color, textScale, font, "left", "top")
end

addCommandHandler("xyz", function()
    showXYZLines = not showXYZLines
    outputChatBox(rtool .. "XYZ Lines: " .. (showXYZLines and "#33cc33ON" or "#ff6666OFF"), 200, 200, 255, true)
end)

local uiqeVisible = true
addCommandHandler("uiqe", function()
    uiqeVisible = not uiqeVisible
end)

function table.find(t, value)
     for i, v in ipairs(t) do
          if v == value then return i end
     end
     return nil
end

local blockedKeys = { }

function MasterKeyHandler(button, press)
    if not press then return end
    if typingMode and button == "c" then
        local etype = getElementType(selectedObj)
        cancelEvent()
        if etype == "object" then
            addQuickRedoAction({ axis = "CLONE" })
            selectedObj = getSelectedEditorObject()
            triggerServerEvent("doCloneElement", selectedObj, 2) 
            exports.editor_main:selectElement(selectedObj, 2) 
        end
    end
    if quickRedoMenuActive and #quickRedoMenuVisibleLists > 0 and not getKeyState(KEY_TOGGLE_EDIT) then
        
        if button == "mouse_wheel_up" then
            exports.editor_main:dropElement()
            quickRedoMenuIndex = math.max(1, quickRedoMenuIndex - 1)
            
            cancelEvent() 

            if exports["editor_main"]:getMode() == 1 then
               exports["editor_main"]:setMode(2)
            end
            return

        elseif button == "mouse_wheel_down" then
            exports.editor_main:dropElement()
            quickRedoMenuIndex = math.min(#quickRedoMenuVisibleLists, quickRedoMenuIndex + 1)
            
            cancelEvent()

            if exports["editor_main"]:getMode() == 1 then
               exports["editor_main"]:setMode(2)
            end
            
            return
        end
    end
    if blockedKeys[button] then
        cancelEvent()
    end
end
addEventHandler("onClientKey", root, MasterKeyHandler)


function getPositionFromElementAtOffset(element,x,y,z)
   if not x or not y or not z then
      return false
   end
		local ox,oy,oz = getElementPosition(element)
        local matrix = getElementMatrix ( element )
		if not matrix then return ox+x,oy+y,oz+z end
        local offX = x * matrix[1][1] + y * matrix[2][1] + z * matrix[3][1] + matrix[4][1]
        local offY = x * matrix[1][2] + y * matrix[2][2] + z * matrix[3][2] + matrix[4][2]
        local offZ = x * matrix[1][3] + y * matrix[2][3] + z * matrix[3][3] + matrix[4][3]
        return offX, offY, offZ
end

-- Block keys when using lists menu

addEventHandler("onClientRender", root, function()
	if typingMode then return end
    local selObj = getSelectedEditorObject()
	if quickEditMode then
        if not loadedLists then 
		loadPresets()
        else
            blockedKeys = {
                mouse_wheel_up = true,
                mouse_wheel_down = true
            }
        if isElement(selObj) then
			local model = getElementModel(selObj)
			quickRedoMenuVisibleLists = getModelPresets(model)
			if #quickRedoMenuVisibleLists > 0 then
				quickRedoMenuActive = true
				quickRedoMenuIndex = 1
		    end
        end
    end
		else
			quickRedoMenuActive = false
            blockedKeys = {}
			--quickRedoMenuVisibleLists {}
	end
end)

------------------------
-- MAIN RENDER
------------------------

addEventHandler("onClientRender", root, function()
    local obj = getSelectedEditorObject()
    if showXYZLines and isElement(obj) and not isPedInVehicle(localPlayer) then
        if getElementType(obj) == "object" then
            local camX, camY, camZ = getCameraMatrix()
            local x, y, z = getElementPosition(obj)
            local dist = getDistanceBetweenPoints3D(camX, camY, camZ, x, y, z)
            local maxDistance, minDistance = 350, 30

            -- Clamp the radius offset to avoid huge spread
            local baseRadius = tonumber(exports.edf:edfGetElementRadius(obj)) or 5
            local minOffset = 3.5
            local maxOffset = 20 -- maximum offset from center (world units)
            local radius = math.min(baseRadius, maxOffset)

            if baseRadius <= minOffset then
                radius = math.min(minOffset, maxOffset)
            end

            local rx, ry, rz = getElementRotation(obj)
            local fontScale = 1.5
            local heightOffset = 0.1

            local xx, xy, xz = getPositionFromElementAtOffset(obj, radius, 0, 0)
            local yx, yy, yz = getPositionFromElementAtOffset(obj, 0, radius, 0)
            local zx, zy, zz = getPositionFromElementAtOffset(obj, 0, 0, radius)

            local sx, sy   = getScreenFromWorldPosition(xx, xy, xz + heightOffset)
            local syx, syy = getScreenFromWorldPosition(yx, yy, yz + heightOffset)
            local szx, szy = getScreenFromWorldPosition(zx, zy, zz + heightOffset)

            if dist < maxDistance and dist > minDistance and sx and sy and syx and syy and szx and szy then
                -- Draw at object
                drawOutlinedText("↕ X: " .. string.format("%.2f", rx), sx, sy, axisColors.X, fontScale)
                drawOutlinedText("Pg Y: " .. string.format("%.2f", ry), syx, syy, axisColors.Y, fontScale)
                drawOutlinedText("↔ Z: " .. string.format("%.2f", rz), szx, szy, axisColors.Z, fontScale)
            else
                -- Draw top right
                local sw, _ = guiGetScreenSize()
                local iconPad = 10
                local iconSize = imgSizeX or 64
                local textPad = 8 * globalScale
                local startX = sw - iconSize - iconPad - 180 * globalScale
                local startY = iconPad

                -- If quickRedoHistory is visible, offset below it
                if #quickRedoHistory > 0 then
                    local quickRedoLines = math.min(#quickRedoHistory, quickRedoHistoryLimit)
                    startY = startY + iconSize + 40 + (quickRedoLines * 18)
                else
                    startY = startY + iconSize + 20
                end

                drawOutlinedText("↕ X: " .. string.format("%.2f", rx), startX, startY, axisColors.X, fontScale)
                drawOutlinedText("Pg Y: " .. string.format("%.2f", ry), startX, startY + 28 * globalScale, axisColors.Y, fontScale)
                drawOutlinedText("↔ Z: " .. string.format("%.2f", rz), startX, startY + 56 * globalScale, axisColors.Z, fontScale)
            end
        end
    end
	
    local sw, sh = guiGetScreenSize()
    local iconX, iconY = sw - imgSizeX - 10, 10

    if uiqeVisible and not isPedInVehicle(localPlayer) then
        
        if quickEditMode then
            dxDrawImage(iconX, iconY, imgSizeX, imgSizeY, qeon)
        else
            dxDrawImage(iconX, iconY, imgSizeX, imgSizeY, qeoff, nil, nil, tocolor(255, 255, 255, 30))
        end

		if #quickRedoHistory > 0 then
			local elapsed = getTickCount() - quickRedoFadeStart
			local alpha = 255
			if elapsed > quickRedoFadeDuration then
				local fadeProgress = math.min(1, (elapsed - quickRedoFadeDuration) / 1500)
				alpha = interpolateBetween(255, 0, 0, 0, 0, 0, fadeProgress, "Linear")
			end

			if alpha > 0 then
				local sw, _ = guiGetScreenSize()
				local startY = iconY + imgSizeX --para el texto de quickredo
				local startX = sw - 120 
				local startIndex = math.max(1, #quickRedoHistory - (quickRedoHistoryLimit - 1))
				
				dxDrawText(math.min(#quickRedoHistory, quickRedoHistoryLimit).."/" ..quickRedoHistoryLimit, startX, startY + 10, sw - 20, startY + 18, tocolor(255,255,255,255), 1.5, "arial", "right", "top")
				
				for i = startIndex, #quickRedoHistory do
					local act = quickRedoHistory[i]
					local axis = act.axis or "?"
					local color = axisColors[axis] or tocolor(255,255,255,alpha)
					local display = ""

					if axis == "X" or axis == "Y" or axis == "Z" then
						local idx = (axis == "X") and 1 or (axis == "Y") and 2 or 3
						local oldVal = (act.old and act.old[idx]) and string.format("%.2f", act.old[idx]) or "-"
						local newVal = act.new[idx] and string.format("%.2f", act.new[idx]) or "-"
						local expr = act.expression or ""
						display = string.format("%s: %s ", axis, newVal)
					else
						if act.value ~= nil then
							display = string.format("%s: %s", axis, tostring(act.value))
						elseif act.new then
							display = string.format("%s", axis)
						else
							display = axis
						end
					end
					if axis == "OFFSET" then
						display = "OFFSET"
					elseif act.value ~= nil then
						display = string.format("%s: %s", axis, tostring(act.value))
					end
					
					dxDrawText(display, startX, startY + 40, sw - 10, startY + 18, axisColors[axis], 1.5, "default-bold", "right", "top")
					startY = startY + 18
				end
			end
		end
    end

    if getTickCount() - applyMessageTime < applyMessageDuration then
        local baseX, baseY = sx / 2, sy / 1.1
        local elapsed = getTickCount() - applyMessageTime
        local alpha = 255
        local size = 2.4
        if elapsed < 300 then
            local progress = elapsed / 300
            alpha = interpolateBetween(0, 0, 0, 255, 0, 0, progress, "InOutQuad")
            size = interpolateBetween(1.8, 0, 0, 2.4, 0, 0, progress, "InOutQuad")
        elseif elapsed > applyMessageDuration - 300 then
            local outProgress = (elapsed - (applyMessageDuration - 300)) / 300
            alpha = interpolateBetween(255, 0, 0, 0, 0, 0, outProgress, "InOutQuad")
            size = interpolateBetween(2.4, 0, 0, 1.8, 0, 0, outProgress, "InOutQuad")
        end
        local appliedText = isRedoApplied and "REDO APPLIED" or "CHANGE APPLIED"
        local textWidth = dxGetTextWidth(appliedText, size, "default-bold")
        local textHeight = dxGetFontHeight(size, "default-bold")
        local padding = 15
        local rectX, rectY = baseX - textWidth / 2 - padding, baseY - textHeight / 2 - padding
        local rectW, rectH = textWidth + padding * 2, textHeight + padding * 2
        dxDrawRectangle(rectX, rectY, rectW, rectH, tocolor(0, 0, 0, math.floor(alpha * 0.7)))
        drawOutlinedText(appliedText, baseX - textWidth / 2, baseY - textHeight / 2, tocolor(0, 255, 0, alpha), size)
    end
    
    --Define which axisOrder will be used
    local axisRender = axisOrderObject
    
    if isElement(selectedObj) then
        axisRender = getAxisList(selectedObj)
    end

    if quickEditMode and getKeyState(KEY_REDO_TOGGLE) then
        local currentObj = getSelectedEditorObject()
        if currentObj ~= selectedObj then
            selectedObj = currentObj
            if isElement(selectedObj) then
                    startAxisEdit(axisRender[axisIndex])
            end
        end
    end

  local now = getTickCount()
  local baseX, baseY = sx - (1500 * scaleX), sy - (1100 * scaleY) -- MOVER A LOS LADOS /// ARRIBA ABAJO
  local lineHeight = 35 * globalScale
  local scale = 1.6 * globalScale
    if not typingMode then
		if quickEditMode and isElement(obj) then 
            if supportedElement(obj) then
                local fullText = "Press " .. KEY_TOGGLE_EDIT .. " to open MENU"
                dxDrawText(fullText, sx - 300, sh - 1380, baseX / 10 + (dxGetTextWidth(fullText, 1.5 * globalScale, "serif", true) / 10) , 10 , tocolor(200, 200, 200, 255), 1.5 * globalScale, "default-bold", "left", "center", true, true, false, true, true)
            end
		end
	else
	
    local half = math.floor(maxVisible / 2)
    targetScrollOffset = (axisIndex - 1) * lineHeight
    local currentTick = getTickCount()
    local deltaTime = (currentTick - lastTick) / 1000.0
    lastTick = currentTick
    scrollOffset = scrollOffset + (targetScrollOffset - scrollOffset) * animationSpeed * deltaTime * 120

    local displayFrom, displayTo = math.max(1, math.floor(axisIndex - half)), math.min(#axisRender, math.ceil(axisIndex + half))
    if (displayTo - displayFrom + 1) < maxVisible then
        if displayFrom == 1 then
            displayTo = math.min(#axisRender, displayFrom + maxVisible - 1)
        elseif displayTo == #axisRender then
            displayFrom = math.max(1, displayTo - maxVisible + 1)
        end
    end

    local firstVisibleY, lastVisibleY
    -- local prevDrawn, nextDrawn = false, false

    for i = displayFrom, displayTo do
        local y = baseY + ((i - axisIndex) * lineHeight) - (scrollOffset % lineHeight)
        local distanceFromCenter = math.abs(i - axisIndex)
        local maxDistance = half + 1
        local normalizedDistance = math.min(1, distanceFromCenter / maxDistance)
        local alpha = math.floor(255 * (1 - normalizedDistance))
        alpha = math.max(0, alpha)
        local r, g, b = 255 + (150 - 255) * normalizedDistance, 255 + (150 - 255) * normalizedDistance, 255 + (150 - 255) * normalizedDistance
        local currentScale = scale + (1 - normalizedDistance) * 0.3

        -- gaurdar primer y último elemento visible
        if alpha > 0 then
            if not firstVisibleY then firstVisibleY = y end
            lastVisibleY = y
        end

        if y > (sy * 0.1) and y < (sy * 0.9) then
            if i == axisIndex and drawText and drawText ~= "" then
				dxDrawRectangle(baseX - (30 * scaleX), y - (lineHeight / 2.5), 20 * scaleX, 20 * scaleY, axisColors[editingAxis])
                drawOutlinedText(drawText, baseX, y - lineHeight / 2, axisColors[editingAxis], currentScale)
				if RedoAdd then 
					drawOutlinedText("REDO", baseX - (110 * scaleX), y - lineHeight / 2, tocolor(46, 106, 176,alpha), currentScale)
				end
            else
                dxDrawText(axisRender[i], baseX, y - lineHeight / 2, baseX + (150 * scaleX), y + lineHeight / 2, tocolor(r, g, b, alpha), currentScale, "default-bold", "left", "center", true)
            end
        end
	end
		if lastVisibleY then
			local infoQe1 = "▼ " .. string.upper(KEY_NEXT_AXIS).. " / ▲ " .. string.upper(KEY_PREV_AXIS)
			local infoQe2 = "APPLY: " .. string.upper(KEY_CONFIRM) .. " / CANCEL: " .. string.upper(KEY_CANCEL).. " / MULTI-REDO: " .. string.upper(KEY_REDO_TOGGLE)
			local infoQe3 = "ADD ROTATION: " .. string.upper(KEY_ADD_ROTATION)
			local infoQe4 = "/fakeclone "
			local infoQe5 = "STORE MOVEMENT AND ROTATION CHANGES"
			
			dxDrawText(infoQe1, baseX - 20, lastVisibleY, baseX, lastVisibleY + lineHeight * 2, tocolor(200, 200, 200, 120), 1.5 * globalScale, "default", "left", "center", true, false, false, true, true)
			dxDrawText(infoQe2, baseX - 160, lastVisibleY, baseX, lastVisibleY + lineHeight * 4, tocolor(200, 200, 200, 120), 1.5 * globalScale, "default", "left", "center", true, false, false, true, true)
			
			if editingAxis == "X" or editingAxis == "Y" or editingAxis == "Z" then 
				dxDrawText(infoQe3, baseX - 30, lastVisibleY, baseX, lastVisibleY + lineHeight * 6, tocolor(200, 200, 200, 120), 1.5 * globalScale, "default", "left", "center", true, false, false, true, true)
			elseif editingAxis == "CLONE" then
				dxDrawText(infoQe4, baseX - 80, lastVisibleY, baseX, lastVisibleY + lineHeight * 6, tocolor(200, 200, 200, 120), 1.5 * globalScale, "default", "left", "center", true, false, false, true, true)
			elseif editingAxis == "OFFSET" then
				dxDrawText(infoQe5, baseX - 65, lastVisibleY, baseX, lastVisibleY + lineHeight * 6, tocolor(200, 200, 200, 120), 1.5 * globalScale, "default", "left", "center", true, false, false, true, true)
			end
		end
	end
end)

------------------------
-- PRESETS RENDER
------------------------

addEventHandler("onClientRender", root, function()
	--if not quickEditMode or typingMode then return end
	if quickRedoMenuActive and #quickRedoMenuVisibleLists > 0 then

		local baseY = sy * 0.10
		local textScale = 2 * globalScale
		local lineHeight = 35 * globalScale

		drawOutlinedText("PRESETS:", ( sx / 2) + ( sx / 4)  , baseY - (lineHeight * 1.5), tocolor(255, 255, 255, 220), textScale + 0.2)

		for i, data in ipairs(quickRedoMenuVisibleLists) do
			local y = baseY + ((i - 1) * lineHeight)
			local color = (i == quickRedoMenuIndex) and tocolor(46, 106, 176, 255) or tocolor(255, 255, 255, 180)
			drawOutlinedText(i .. ". " .. data.name .. " (" .. data.count .. " actions)", ( sx / 2) + ( sx / 4.3), y - (lineHeight * 0.5), color, textScale)

		end

		local info = "▼ / ▲ MOUSE WHEEL | ENTER to load"
		dxDrawText(info, ( sx / 2) + ( sx / 4.5), baseY + (#quickRedoMenuVisibleLists * lineHeight), sx / 2, sy, tocolor(200, 200, 200, 120), textScale - 0.5, "default", "left", "top")
	end
end)

------------------------
-- ROTATION UTILS
------------------------

function evaluateMathExpression(str)
    local fn, err = loadstring("return " .. str)
    if not fn then return nil end
    local success, result = pcall(fn)
    if success then return result end
    return nil
end

function getAxisRotVal(axis)
    local rx, ry, rz = getElementRotation(selectedObj)
    if axis == "X" then return rx elseif axis == "Y" then return ry elseif axis == "Z" then return rz end
    return 0
end

local function quatMul(a, b)
    return {
        a[4]*b[1] + a[1]*b[4] + a[2]*b[3] - a[3]*b[2],
        a[4]*b[2] + a[2]*b[4] + a[3]*b[1] - a[1]*b[3],
        a[4]*b[3] + a[3]*b[4] + a[1]*b[2] - a[2]*b[1],
        a[4]*b[4] - a[1]*b[1] - a[2]*b[2] - a[3]*b[3]
    }
end

local function quatInverse(q)
    return {-q[1], -q[2], -q[3], q[4]}
end

local function getQuatFromEuler(euler)
    local tcos, tsin = {}, {}
    for i=1,3 do
        tcos[i] = math.cos(math.rad(euler[i]/2))
        tsin[i] = math.sin(math.rad(euler[i]/2))
    end
    return {
        tcos[1]*tcos[2]*tcos[3] + tsin[1]*tsin[2]*tsin[3],
        tsin[1]*tcos[2]*tcos[3] - tcos[1]*tsin[2]*tsin[3],
        tcos[1]*tsin[2]*tcos[3] + tsin[1]*tcos[2]*tsin[3],
        tcos[1]*tcos[2]*tsin[3] - tsin[1]*tsin[2]*tcos[3]
    }
end

local function getEulerFromQuat(q)
    local q0,q1,q2,q3 = q[1], q[2], q[3], q[4]
    local sinp = 2*(q0*q2 - q3*q1)
    -- clamp asin input
    if sinp >= 1 or sinp <= -1 then
        sinp = math.max(-1, math.min(1, sinp))
    end
    return {
        math.deg(math.atan2(2*(q0*q1+q2*q3), 1 - 2*(q1^2 + q2^2))),
        math.deg(math.asin(sinp)),
        math.deg(math.atan2(2*(q0*q3+q1*q2), 1 - 2*(q2^2 + q3^2)))
    }
end

-- Crea el cuaternión offset para un eje (X/Y/Z) de "angle" grados (igual que en editor)
local function makeAxisOffsetQuat(axis, angle)
    local arad = math.rad(angle)
    local s = math.sin(arad / 2)
    local c = math.cos(arad / 2)
    if axis == "X" then
        return {s, 0, 0, c}
    elseif axis == "Y" then
        return {0, s, 0, c}
    elseif axis == "Z" then
        return {0, 0, s, c}
    end
    return {0,0,0,1}
end

-- newQuat = offset * currentQuat
local function applyOffsetQuat(obj, offsetQuat)
    if not isElement(obj) then return nil end
    local rx, ry, rz = getElementRotation(obj, "ZYX")
    local curQ = getQuatFromEuler({rx, ry, rz})
    local newQ = quatMul(offsetQuat, curQ)
    local newEuler = getEulerFromQuat(newQ)
        setElementRotation(obj, newEuler[1], newEuler[2], newEuler[3], "ZYX")
    return newEuler
end

function applyLocalRotation(obj, axis, angle)
    local oq = makeAxisOffsetQuat(axis, angle)
    return applyOffsetQuat(obj, oq)
end

local function applyRotation(val, rawExpression)
    if not selectedObj or not isElement(selectedObj) then return end

    local rx, ry, rz = getElementRotation(selectedObj)
    local oldRot = {rx, ry, rz}
    local newRot = {rx, ry, rz}
    local delta = 0
    local isRelative = (rawExpression ~= nil)

    if isRelative then
		--outputChatBox("test")
        local offsetQuat = makeAxisOffsetQuat(editingAxis, val)
        local applied = applyOffsetQuat(selectedObj, offsetQuat)
        newRot = applied or newRot

        addQuickRedoAction({
            axis = editingAxis,
            old = oldRot,
            new = newRot,
            deltaQuat = offsetQuat,
            expression = rawExpression
        })
    else
		if editingAxis == "X" then
			delta = val - rx
			newRot[1] = val
		elseif editingAxis == "Y" then
			delta = val - ry
			newRot[2] = val
		elseif editingAxis == "Z" then
			delta = val - rz
			newRot[3] = val
		end

		setElementRotation(selectedObj, unpack(newRot))
		
		exports.editor_main:dropElement()
		exports["editor_main"]:selectElement(selectedObj, 2) --Drop y luego volver a seleccior para evitar que el Editor no lo actualice
        addQuickRedoAction({
            axis = editingAxis,
            old = oldRot,
            new = newRot,
			delta = delta,
            expression = rawExpression
        })
    end

    applyMessageTime, isRedoApplied = getTickCount(), false
    resetInput()
end

------------------------
-- NAVIGATION
------------------------

function toggleQuickEdit()
    selectedObj = getSelectedEditorObject()
    if isPedInVehicle(localPlayer) then return end
    if getKeyState(KEY_REDO_TOGGLE) then
        quickEditMode = true
        if lastAxisUsed then
            local axisType
            if isElement(selectedObj) then
                axisType = getAxisList(selectedObj)
            end

            axisIndex = table.find(axisType, lastAxisUsed) or 1
            startAxisEdit(axisType[axisIndex])
        end
        return
    end
    
    local wasQuickEditMode = quickEditMode
    editingAxis, inputBuffer, axisIndex, scrollOffset = nil, "", 0, 0

    if quickEditMode then
        local axisType = getAxisList(selectedObj)
        axisIndex = axisIndex % #axisType + 1
        startAxisEdit(axisType[axisIndex])
    else
        quickEditMode = true
    end
    -- Si el modo Quick Edit se acaba de activar, reinicia el temporizador de la lista.
    if not wasQuickEditMode and quickEditMode and #quickRedoHistory > 0 then
        quickRedoFadeStart = getTickCount()
    end
end
bindKey(KEY_TOGGLE_EDIT, "down", toggleQuickEdit)

function toggleRedo()
    if quickEditMode and typingMode then
    local obj = getSelectedEditorObject()
    if getElementType(obj) == "racepickup" then outputChatBox(rtool.."#2E6AB0Multi-Redo#FFFFFF is not supported for this type", 200, 200, 255, true) return end
        if not isOffsetLockActive() then 
            RedoAdd = not RedoAdd
            quickRedoHistory = {}
        end
    end
end
bindKey(KEY_REDO_TOGGLE, "down", toggleRedo)

function axisNav(_, _, direction)
    if not quickEditMode or isOffsetLockActive() then return end
    if not isElement(selectedObj) then return end

    local delta = (direction == "next") and 1 or -1
    -- Markers/cps
    if (getElementType(selectedObj) == "marker" or getElementType(selectedObj) == "checkpoint") and markerTypeSelectionActive and editingAxis == "TYPE" then
        markerTypeIndex = (markerTypeIndex - 1 + delta) % #markerTypes + 1
        drawText = "TYPE: " .. markerTypes[markerTypeIndex] .." (< "..KEY_NEXT_AXIS.."/"..KEY_PREV_AXIS.." >)"
        return
    end

    local axisType = getAxisList(selectedObj)
    axisIndex = (axisIndex - 1 + delta) % #axisType + 1
    startAxisEdit(axisType[axisIndex])
end
bindKey(KEY_NEXT_AXIS, "down", axisNav, "next")
bindKey(KEY_PREV_AXIS, "down", axisNav, "prev")

function addRotToggle()
    if typingMode and (editingAxis == "X" or editingAxis == "Y" or editingAxis == "Z") then
        local currentVal = getAxisRotVal(editingAxis)
        inputBuffer = tostring(currentVal)
        drawText = editingAxis .. ": " .. inputBuffer .. " [+ / -]"
    end
end
bindKey(KEY_ADD_ROTATION, "down", addRotToggle)

function backspaceEdit() 
    if typingMode and editingAxis and #inputBuffer > 0 then
        inputBuffer = inputBuffer:sub(1, -2)
        drawText = editingAxis .. ": " .. inputBuffer
    end
end
bindKey(KEY_BACKSPACE, "down", backspaceEdit)

function onConfirm(alt)
	if alt and quickRedoMenuActive and not getKeyState(KEY_TOGGLE_EDIT) then
		local selected = quickRedoMenuVisibleLists[quickRedoMenuIndex]
		if not selected then return end
		local name = selected.name
			quickRedoHistory = table.deepcopy(quickRedoSaves[name])
			outputChatBox(rtool.. "Preset '#33cc33" .. name .. "#FFFFFF' loaded.", 100, 255, 100, true)
			--QuickRedoMain()
		quickRedoMenuActive = false
		quickEditMode = false
    end

    if not typingMode or not selectedObj or not isElement(selectedObj) then resetInput() return end
    local etype = getElementType(selectedObj)
    local oldSettings, newSettings = {}, {}
    if etype == "marker" or etype =="checkpoint" then
        if editingAxis == "SIZE" then
            local size = tonumber(inputBuffer)
            if size then
                oldSettings.size = exports.edf:edfGetElementProperty(selectedObj, "size")
                exports.edf:edfSetElementProperty(selectedObj, "size", tostring(size))
                newSettings.size = tostring(size)
                addQuickRedoAction({axis = "SIZE", value = size, elementType = "marker"})
            end
        elseif editingAxis == "TYPE" then
            if not markerTypeSelectionActive then
                markerTypeSelectionActive = true
                drawText = "TYPE: " .. markerTypes[markerTypeIndex] .. " (< "..KEY_NEXT_AXIS.."/"..KEY_PREV_AXIS.." >)"
            else
                local mtype = markerTypes[markerTypeIndex]
                oldSettings.type = exports.edf:edfGetElementProperty(selectedObj, "type")
                newSettings.type = mtype
                exports.edf:edfSetElementProperty(selectedObj, "type", mtype)
                --arrow will always appear slightly below compared to any other type
                if newSettings.type == "arrow" and oldSettings.type ~= "arrow" then 
                    local mx, my, mz = getElementPosition(selectedObj)
                    setElementPosition(selectedObj, mx, my, mz+1)
                end
                drawText = "TYPE: " .. markerTypes[markerTypeIndex]
                markerTypeSelectionActive = false
                addQuickRedoAction({axis = "TYPE", value = mtype, elementType = "marker"})
            end
            --pendejos pinches putos idiotas q son britanicos o que mierda "colour" que mierda de donde sacan eso pendejos
        elseif editingAxis == "COLOUR" then
            local color = inputBuffer
            if color and #color == 6 then
                oldSettings.color = exports.edf:edfGetElementProperty(selectedObj, "colour")
                exports.edf:edfSetElementProperty(selectedObj, "colour", tostring("#"..color))
                newSettings.color = tostring("#"..color)
                addQuickRedoAction({axis = "COLOUR", value = color, elementType = "marker"})
            end
        end
        if next(newSettings) then
            triggerServerEvent("syncProperties", localPlayer, oldSettings, newSettings, selectedObj)
            applyMessageTime, isRedoApplied = getTickCount(), false
        resetInput()
        return
        end
    elseif etype == "racepickup" then
        if editingAxis == "REPAIR" then
            oldSettings.type = exports.edf:edfGetElementProperty(selectedObj, "type")
            exports.edf:edfSetElementProperty(selectedObj, "type", "repair")
            newSettings.type = "repair"
            addQuickRedoAction({axis = "REPAIR", elementType = "racepickup"})
        elseif editingAxis == "NITRO" then 
            oldSettings.type = exports.edf:edfGetElementProperty(selectedObj, "type")
            exports.edf:edfSetElementProperty(selectedObj, "type", "nitro")
            newSettings.type = "nitro"
            addQuickRedoAction({axis = "NITRO", elementType = "racepickup"})
        elseif editingAxis == "VEHICLE" then 
            local vehicleID = inputBuffer
            oldSettings.type = exports.edf:edfGetElementProperty(selectedObj, "type")
            exports.edf:edfSetElementProperty(selectedObj, "type", "vehiclechange")
            newSettings.type = "vehiclechange"
            if vehicleID and #vehicleID == 3 then
                if (tonumber(vehicleID) <= 611 and tonumber(vehicleID) >= 400) then
                    oldSettings.vehicle = exports.edf:edfGetElementProperty(selectedObj, "vehicle")
                    newSettings.vehicle = tostring(vehicleID)
                    exports.edf:edfSetElementProperty(selectedObj, "vehicle", (vehicleID))
                    addQuickRedoAction({axis = "VEHICLE", value = vehicleID, elementType = "racepickup"})
                else
                    outputChatBox(rtool.."#FFFFFFWrong number. Vehicle ID range is 400 - 611", 90, 32, 162, true)
                end
            else
                addQuickRedoAction({axis = "VEHICLE", elementType = "racepickup"})
                if vehicleID and #vehicleID ~= 3 or not (tonumber(vehicleID) <= 611 and tonumber(vehicleID) >= 400) then
                    outputChatBox(rtool.."#FFFFFFWrong or no specified vehicle ID. Only changed pickup type", 90, 32, 162, true)
                end
            end
        end

        if next(newSettings) then
            triggerServerEvent("syncProperties", localPlayer, oldSettings, newSettings, selectedObj)
            applyMessageTime, isRedoApplied = getTickCount(), false
        resetInput()
        return
        end
    else
    -- objects
    if editingAxis == "ZERO" then
        local rx, ry, rz = getElementRotation(selectedObj)
        oldSettings.rotation = {rx, ry, rz}
        setElementRotation(selectedObj, 0, 0, 0)
        newSettings.rotation = {0, 0, 0}
        exports.editor_main:dropElement()
        exports["editor_main"]:selectElement(selectedObj, 2)
        addQuickRedoAction({axis = "ZERO", old = oldSettings.rotation, new = newSettings.rotation})
    elseif editingAxis == "OFFSET" then
        if not offsetEditing then
            local x, y, z = getElementPosition(selectedObj)
            offsetStartPos = {x, y, z}
            offsetStartRot = {getElementRotation(selectedObj, "ZYX")}
            offsetStartMat = getElementMatrix(selectedObj)
            offsetEditing = true
            drawText = "OFFSET: Move Object"
            return
        else
            selectedObj = getSelectedEditorObject()
            local x, y, z = getElementPosition(selectedObj)
            local dx, dy, dz = x - offsetStartPos[1], y - offsetStartPos[2], z - offsetStartPos[3]
            local m = offsetStartMat or getElementMatrix(selectedObj)
            local localDelta = {
                dx * m[1][1] + dy * m[1][2] + dz * m[1][3],
                dx * m[2][1] + dy * m[2][2] + dz * m[2][3],
                dx * m[3][1] + dy * m[3][2] + dz * m[3][3],
            }
            local rx1, ry1, rz1 = unpack(offsetStartRot)
            local rx2, ry2, rz2 = getElementRotation(selectedObj, "ZYX")
            local q1 = getQuatFromEuler({rx1, ry1, rz1})
            local q2 = getQuatFromEuler({rx2, ry2, rz2})
            local deltaQuat = quatMul(q2, quatInverse(q1))
            addQuickRedoAction({
                axis = "OFFSET",
                value = localDelta,
                deltaQuat = deltaQuat,
                startMat = offsetStartMat,
                startPos = offsetStartPos
            })
            offsetEditing = false
            resetInput()
        end
    elseif editingAxis == "CLONE" then
        if not RedoAdd then
            outputChatBox(rtool.. "Enable #0067F7REDO #FFFFFFto use #5E89FFCLONE. #FFFFFF("..KEY_REDO_TOGGLE..") ", 255, 100, 100, true)
            resetInput()
            return
        end
        if not fakeClone then
            exports.editor_main:dropElement()
            triggerServerEvent("doCloneElement", selectedObj, 2)
            exports.editor_main:dropElement()
        end
        addQuickRedoAction({ axis = "CLONE" })
    elseif editingAxis == "SCALE" then
        local scale = tonumber(inputBuffer)
        if scale then
            oldSettings.scale = getObjectScale(selectedObj)
            setObjectScale(selectedObj, scale)
            newSettings.scale = scale
            addQuickRedoAction({axis = "SCALE", value = scale})
        end
    elseif editingAxis == "DOUBLESIDE" then
        local current = getElementData(selectedObj, "me:doubleSided") or false
        oldSettings.doublesided = tostring(current)
        local newVal = not current
        setElementData(selectedObj, "me:doubleSided", newVal)
        exports.edf:edfSetElementProperty(selectedObj, "doublesided", tostring(newVal))
        newSettings.doublesided = tostring(newVal)
        addQuickRedoAction({axis = "DOUBLESIDE", value = newVal})
    elseif editingAxis == "MODEL" then
        local model = tonumber(inputBuffer)
        if model then
            oldSettings.model = getElementModel(selectedObj)
            setElementModel(selectedObj, model)
            newSettings.model = model
            addQuickRedoAction({axis = "MODEL", value = model})
        end
    elseif editingAxis == "COLLISIONS" then
        local current = exports.edf:edfGetElementProperty(selectedObj, "collisions")
        local newVal = (tostring(current) == "true") and "false" or "true"
        oldSettings.collisions = tostring(current)
        exports.edf:edfSetElementProperty(selectedObj, "collisions", newVal)
        newSettings.collisions = newVal
        addQuickRedoAction({axis = "COLLISIONS", value = newVal})
    else
        local evaluated = evaluateMathExpression(inputBuffer)
        if not evaluated then resetInput() return end
        local isRelative = inputBuffer:gsub("%s+", ""):find("^[+-]")
        applyRotation(evaluated, isRelative and inputBuffer:gsub("%s+", "") or nil)
        return
    end
    if next(newSettings) then
        triggerServerEvent("syncProperties", localPlayer, oldSettings, newSettings, selectedObj)
        applyMessageTime, isRedoApplied = getTickCount(), false
    end
    resetInput()
end
end
bindKey(KEY_CONFIRM, "down", onConfirm)
bindKey("num_enter", "down", onConfirm)
--bindKey(KEY_CONFIRM_ALT, "down", onConfirm, gay)

function cancelEdit()
    if typingMode then
        if isElement(selectedObj) then
            local etype = getElementType(selectedObj)
            if etype == "object" then
                setElementRotation(selectedObj, unpack(originalRot))
                setObjectScale(selectedObj, originalScale)
                setElementModel(selectedObj, originalModel)
                offsetEditing = false
                offsetStartPos = nil
            end
        end
        RedoAdd = false
        scrollOffset = 0
        resetInput()
		quickRedoMenuActive, quickRedoMenuVisibleLists = false, {}
    elseif quickEditMode then
        quickEditMode, editingAxis = false, nil
		quickRedoMenuActive, quickRedoMenuVisibleLists = false, {}
    end
end
bindKey(KEY_CANCEL, "down", cancelEdit)

------------------------
-- QUICK REDO
------------------------

function getPollDelay()
    local ping = getPlayerPing(localPlayer)
    return math.min(1500, 250 + (ping * 1.4)) -- 0-10 Ping = 250 / 300 Ping = 800 +/-
end


function QuickRedoMain()
    if not getKeyState(KEY_TOGGLE_EDIT) then return end
    if #quickRedoHistory == 0 then return end

    local startObj = getSelectedEditorObject()
    if not isElement(startObj) then return end
	
	quickEditMode, quickRedoMenuActive, quickRedoMenuVisibleLists = false, false, {}

	local timeoutPerClone = getPollDelay()
	local pollInterval   = getPollDelay()

    local function applyActionToObject(obj, act)
        local oldSettings, newSettings = {}, {}
    
    if act.elementType == "marker" or act.elementType == "checkpoint" then
        if getElementType(startObj) ~= "marker" and getElementType(startObj) ~= "checkpoint" then outputChatBox(rtool.."#FFFFFFWrong element type!", 200, 200, 255, true) return end
            if act.axis == "COLOUR" then
                oldSettings.color = exports.edf:edfGetElementProperty(obj, "colour")
                newSettings.color = tostring("#"..act.value)
                exports.edf:edfSetElementProperty(obj, "colour", tostring("#"..act.value))
            elseif act.axis == "TYPE" then
                if getElementType(startObj) == "checkpoint" then
                    oldSettings.type = exports.edf:edfGetElementProperty(obj, "type", act.value)
                else
                    oldSettings.type = getMarkerType(obj)
                end
                newSettings.type = act.value
                exports.edf:edfSetElementProperty(obj, "type", act.value)
            elseif act.axis == "SIZE" then
                oldSettings.size = exports.edf:edfGetElementProperty(obj, "size")
                newSettings.size = tostring(act.value)
                exports.edf:edfSetElementProperty(obj, "size", tostring(act.value))
            end
        
        if next(newSettings) then
            triggerServerEvent("syncProperties", localPlayer, oldSettings, newSettings, obj)
        end

    elseif act.elementType == "racepickup" then
        if getElementType(startObj) ~= "racepickup" then outputChatBox(rtool.."#FFFFFFWrong element type!", 200, 200, 255, true) return end
        if act.axis == "REPAIR" then
            oldSettings.type = exports.edf:edfGetElementProperty(selectedObj, "type")
            exports.edf:edfSetElementProperty(selectedObj, "type", "repair")
            newSettings.type = "repair"
        elseif act.axis == "NITRO" then 
            oldSettings.type = exports.edf:edfGetElementProperty(selectedObj, "type")
            exports.edf:edfSetElementProperty(selectedObj, "type", "nitro")
            newSettings.type = "nitro"
        elseif act.axis == "VEHICLE" then 
            -- local vehicleID = act.value
            oldSettings.type = exports.edf:edfGetElementProperty(selectedObj, "type")
            exports.edf:edfSetElementProperty(selectedObj, "type", "vehiclechange")
            newSettings.type = "vehiclechange"
            if act.value and #act.value == 3 then
                if (tonumber(act.value) <= 611 and tonumber(act.value) >= 400) then
                    oldSettings.vehicle = exports.edf:edfGetElementProperty(selectedObj, "vehicle")
                    newSettings.vehicle = tostring(act.value)
                    exports.edf:edfSetElementProperty(selectedObj, "vehicle", act.value)
                else
                    outputChatBox(rtool.."#FFFFFFWrong number. Vehicle ID range is 400 - 611", 90, 32, 162, true)
                end
            else
                outputChatBox(rtool.."#FFFFFFWrong vehicle ID. Only changed pickup type", 90, 32, 162, true)
            end
        end

        if next(newSettings) then
            triggerServerEvent("syncProperties", localPlayer, oldSettings, newSettings, obj)
        end

    else
        if getElementType(startObj) ~= "object" then outputChatBox(rtool.."#FFFFFFWrong element type!", 200, 200, 255, true) return end
            if act.axis == "X" or act.axis == "Y" or act.axis == "Z" then
                local rx, ry, rz = getElementRotation(obj)
                local oldRot, newRot = {rx, ry, rz}, {rx, ry, rz}
                local idx = (act.axis == "X") and 1 or (act.axis == "Y") and 2 or 3
                
                --add or substract
                if act.delta > 0 then
                    newRot[idx] = newRot[idx] + act.delta

                -- this is basically defunct but I keep it anyway just in case.
                elseif act.expression then
                    local curVal = getAxisRotVal(act.axis)
                    local exprStr = tostring(curVal) .. tostring(act.expression)
                    local result = evaluateMathExpression(exprStr)
                    if result then
                        newRot[idx] = result
                    end
                    
                    --normal absolute rotation
                    elseif act.new then
                        if act.new[idx] ~= nil then
                            newRot[idx] = act.new[idx]
                        end
                    end

                setElementRotation(obj, unpack(newRot))

            elseif act.axis == "CLONE" then
                triggerServerEvent("doCloneElement", obj, 2)
                exports.editor_main:dropElement()
                exports.editor_main:selectElement(obj, 2) 

            elseif act.axis == "SCALE" then
                oldSettings.scale = getObjectScale(obj)
                setObjectScale(obj, act.value)
                newSettings.scale = act.value

            elseif act.axis == "DOUBLESIDE" then
                local cur = tostring(exports.edf:edfGetElementProperty(obj, "doublesided"))
                exports.edf:edfSetElementProperty(obj, "doublesided", tostring(act.value))
                oldSettings.doublesided = cur
                newSettings.doublesided = tostring(act.value)

            elseif act.axis == "MODEL" then
                oldSettings.model = getElementModel(obj)
                setElementModel(obj, act.value)
                newSettings.model = act.value

            elseif act.axis == "COLLISIONS" then
                local cur = tostring(exports.edf:edfGetElementProperty(obj, "collisions"))
                exports.edf:edfSetElementProperty(obj, "collisions", tostring(act.value))
                oldSettings.collisions = cur
                newSettings.collisions = tostring(act.value)

            elseif act.axis == "ZERO" then
                local rx, ry, rz = getElementRotation(obj)
                local oldRot = { rx, ry, rz }
                setElementRotation(obj, unpack(act.new))
                oldSettings.rotation = oldRot
                newSettings.rotation = act.new

            elseif act.axis == "OFFSET" then
                local ox, oy, oz = getElementPosition(obj)
                local dx, dy, dz = unpack(act.value or {0,0,0})
                local wx, wy, wz = getPositionFromElementOffset(getElementMatrix(obj), dx, dy, dz)
                setElementPosition(obj, wx, wy, wz)

                if act.deltaQuat then
                    applyOffsetQuat(obj, act.deltaQuat)
                elseif act.deltaRot then
                    if act.deltaRot[1] ~= 0 then applyLocalRotation(obj, "X", act.deltaRot[1]) end
                    if act.deltaRot[2] ~= 0 then applyLocalRotation(obj, "Y", act.deltaRot[2]) end
                    if act.deltaRot[3] ~= 0 then applyLocalRotation(obj, "Z", act.deltaRot[3]) end
                end

                oldSettings.position = {ox, oy, oz}
                newSettings.position = {wx, wy, wz}
            end

            if next(newSettings) then
                triggerServerEvent("syncProperties", localPlayer, oldSettings, newSettings, obj)
            end
        end
    end

local function processSequence(index, obj)
    if index > #quickRedoHistory then
        quickEditMode = false
        isRedoApplied = true
        applyMessageTime = getTickCount()
        return
    end

    local act = quickRedoHistory[index]
    if not act then
        processSequence(index + 1, obj)
        return
    end

    if act.axis == "OFFSET" then
        local m = getElementMatrix(obj)
        local pos = {getElementPosition(obj)}
        local rot = {getElementRotation(obj, "ZYX")}
    end

    if act.axis == "CLONE" then
		exports.editor_main:dropElement() -- DROPEAR LO ARREGLA TODO VIEJA
        local original = obj
			exports.editor_main:selectElement(obj, 2) -- SELECCIONAR DESPUES DE DROPEAR
        local prevRot = {getElementRotation(original, "ZYX")}
        applyActionToObject(obj, act)

        local elapsed = 0
        local pollTimer

        pollTimer = setTimer(function()
            elapsed = elapsed + pollInterval
            local newObj = getSelectedEditorObject()

            if newObj and isElement(newObj) and newObj ~= original then
                if isTimer(pollTimer) then killTimer(pollTimer) end

                local rx, ry, rz = getElementRotation(newObj, "ZYX")
                if rx == 0 and ry == 0 and rz == 0 then
                    if type(prevRot[1]) == "number" and type(prevRot[2]) == "number" and type(prevRot[3]) == "number" then
						setElementRotation(newObj, prevRot[1], prevRot[2], prevRot[3])
					end
                end

                processSequence(index + 1, newObj)

            elseif elapsed >= timeoutPerClone then
                if isTimer(pollTimer) then killTimer(pollTimer) end
                processSequence(index + 1, original)
            end
        end, pollInterval, 0)

    else
        applyActionToObject(obj, act)
        local nextObj = getSelectedEditorObject()
        if act.axis == "OFFSET" and isElement(nextObj) then
            processSequence(index + 1, nextObj)
        else
            processSequence(index + 1, obj)
        end
    end
end

    processSequence(1, startObj)
end
bindKey(KEY_REDO, "down", QuickRedoMain)

addCommandHandler("presave", function(_, name, ...)
    if not name or name == "" then
        outputChatBox(rtool.. " Usage: /presave <name> <IDs>", 255, 100, 100, true)
        return
    end
    if tostring(name):find("^%d") then
        outputChatBox(rtool.. "#FF0000ERROR! #FFFFFFPreset name cannot start with a number", 255, 100, 100, true)
        return
    end
    if #quickRedoHistory == 0 then
        outputChatBox(rtool.. "#FF0000ERROR! #FFFFFFNo actions found in #0067F7REDO #FFFFFFhistory", 255, 100, 100, true)
        return
    end
    quickRedoSaves[name] = table.deepcopy(quickRedoHistory)

    local args = {...}
    if #args > 0 then
        quickRedoSaves[name]._ids = args
    end

    savePresets()
    outputChatBox(rtool.."Preset '" .. name .. "' saved with '##33cc33" .. tostring(#quickRedoHistory) .. "#FFFFFF' actions.", 100, 255, 100, true)
end)

function table.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
        end
        setmetatable(copy, table.deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

addCommandHandler("preload", function(_, name)
    if not name or not quickRedoSaves[name] then
        outputChatBox(rtool.. "#FF0000ERROR! #FFFFFFList not found!", 255, 100, 100, true)
        return
    end
    quickRedoHistory = table.deepcopy(quickRedoSaves[name])
    outputChatBox(rtool.."Preset '" .. name .. "' loaded with '##33cc33" .. tostring(#quickRedoHistory) .. "#FFFFFF' actions.", 100, 255, 100, true)
end)

addCommandHandler("prelist", function(_, page)
    page = tonumber(page) or 1
    local perPage = 10
    local names = {}
    for k in pairs(quickRedoSaves) do
        table.insert(names, k)
    end
    table.sort(names)

    local total = #names
    local startIdx = (page - 1) * perPage + 1
    local endIdx = math.min(startIdx + perPage - 1, total)
    local totalPages = math.ceil(total / perPage)

    if total == 0 then
        outputChatBox(rtool.."No presets found!", 255, 100, 100)
        return
    end
	
	outputChatBox(rtool.."Presets ("..total.." total) — Page " ..page.."/"..totalPages..":", 255, 100, 100, true)
    for i = startIdx, endIdx do
        local name = names[i]
        local list = quickRedoSaves[name]
        outputChatBox(string.format("%s. #33cc33%s #FFFFFF - %d Actions", i, name, #list), 0, 102, 255, true)
    end

    -- outputChatBox(string.format("Page %d/%d | Use /qrlist <n>", page, totalPages), 180, 180, 180)
end)

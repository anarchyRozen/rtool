local ignoreEnterUntil = 0
--CONFIG 
local PreviewAlpha = 255 -- Preview object transparency 0-255
local maxMostUsedPages = 5 
local mostUsedExclusions = { [3458]=true, [8558]=true, [8557]=true, [8838]=true, [7657]=true, [8357]=true, [6959]=true, [1234]=true, [3045]=true, [2221]=true }

-- LISTAS DON'T CHANGE
local listModes = {"recent", "mostused", "favorites"}
local currentListIndex = 1
local favoriteObjects = {}
local mostUsedObjects = {}

-- CONFIGURACIÓN GENERAL DON'T CHANGE TOO
local doublePressTime = 300       
local textPositionX = 0.82  
local textPositionY = 0.3         
local textSize = 2.5            
local textColor, borderColor, selectedItemColor  = tocolor(255, 255, 255, 255), tocolor(0, 0, 0, 255), tocolor(61, 139, 255, 255) 

local listOffsetY = 0.03         
local listItemSize = 2.3         
local maxListItems = 15         

local historyFileName = "usertool.xml" -- objects_id_history.xml before RtoOL 1.5

local isSearchMode, globalObjectsLoaded, quickAddReplacing = false, false, false
local searchResults, globalObjectsList = {}, {}
local FavAutoTop, enableGlobalSearch = true, true, true
local searchInput = ""
local globalObjectsFilePath = "objects.xml"

local lastRKeyPressTime = 0
local originalModel = nil
-- local backspaceHoldStart = 0
local isInputActive = false
local currentInput = ""
local showCursor = true
local cursorTimer = getTickCount()
local createdObjectsHistory = {}  
local selectedListItem = -1  -- (-1 = nada)
local currentPage = 1            

------------------------
-- QUICKADD HISTORY / XML
------------------------

function saveObjectHistory()
    local root, hist = loadUsertoolGroup("objectHistory")

    -- limpiar viejo contenido
    for _, n in ipairs(xmlNodeGetChildren(hist)) do
        xmlDestroyNode(n)
    end

    local recentNode = xmlCreateChild(hist, "recent")
    for _, obj in ipairs(createdObjectsHistory) do
        local item = xmlCreateChild(recentNode, "object")
        xmlNodeSetAttribute(item, "id", tostring(obj.id))
        xmlNodeSetAttribute(item, "name", obj.name)
    end

    local favNode = xmlCreateChild(hist, "favorites")
    for _, obj in ipairs(favoriteObjects) do
        local item = xmlCreateChild(favNode, "object")
        xmlNodeSetAttribute(item, "id", tostring(obj.id))
        xmlNodeSetAttribute(item, "name", obj.name)
    end

    xmlSaveFile(root)
end


function loadObjectHistory()
    local _, hist = loadUsertoolGroup("objectHistory")

    createdObjectsHistory = {}
    favoriteObjects = {}

    for _, node in ipairs(xmlNodeGetChildren(hist)) do
        if xmlNodeGetName(node) == "recent" then
            for _, c in ipairs(xmlNodeGetChildren(node)) do
                table.insert(createdObjectsHistory, {
                    id   = tonumber(xmlNodeGetAttribute(c, "id")),
                    name = xmlNodeGetAttribute(c, "name")
                })
            end
        elseif xmlNodeGetName(node) == "favorites" then
            for _, c in ipairs(xmlNodeGetChildren(node)) do
                table.insert(favoriteObjects, {
                    id   = tonumber(xmlNodeGetAttribute(c, "id")),
                    name = xmlNodeGetAttribute(c, "name")
                })
            end
        end
    end
end


-- Cargar objetos globales desde objects.xml
function loadGlobalObjects()
    if not enableGlobalSearch then return end
    if globalObjectsLoaded then return end

    if not fileExists(globalObjectsFilePath) then
        outputChatBox(rtool.."#FF5555Global search disabled: objects.xml not found in resource folder.", 255, 255, 255, true)
        return
    end

    local xml = xmlLoadFile(globalObjectsFilePath)
    if not xml then
        outputChatBox(rtool.."#FF5555Failed to load objects.xml", 255, 255, 255, true)
        return
    end

    local function parseNode(node)
        for _, child in ipairs(xmlNodeGetChildren(node)) do
            local tag = xmlNodeGetName(child)
            if tag == "object" then
                local id = tonumber(xmlNodeGetAttribute(child, "model"))
                local name = xmlNodeGetAttribute(child, "name")
                local keywords = xmlNodeGetAttribute(child, "keywords") or ""
                if id and name then
                    table.insert(globalObjectsList, {id = id, name = name, keywords = keywords})
                end
            elseif tag == "group" or tag == "catalog" then
                parseNode(child)
            end
        end
    end

    parseNode(xml)
    xmlUnloadFile(xml)
    globalObjectsLoaded = true
    outputDebugString("[QuickAdd] Loaded " .. #globalObjectsList .. " objects from XML")
end
loadObjectHistory()
loadGlobalObjects()

------------------------
-- BINDINGS
------------------------

--Block keys from being triggered using UI
local blockedEditorKeys = {
    arrow_u = true,
    arrow_d = true,
    arrow_l = true,
    arrow_r = true,
    mouse_wheel_up = true,
    mouse_wheel_down = true,
    mouse2 = true,
    lctrl = true,
    lalt = true
}

addEventHandler("onClientKey", root, function(button, press)
    if not isInputActive then return end
    if isSearchMode and not searchResults[selectedListItem + 1 ] then
        cancelEvent()
        return
    end
    local sel = getSelectedEditorObject()
    if sel and isElement(sel) and blockedEditorKeys[button] then
        cancelEvent()
    end
end)


function mainToggle(key, press)
    if typingMode then return end
    if not press then return end
    if getKeyState(KEY_TOGGLE_EDIT) or isPedInVehicle(localPlayer) then return end

    if not isInputActive and getSelectedEditorObject() and isElement(getSelectedEditorObject()) then 
        originalModel = getElementModel(getSelectedEditorObject())
    end

    local now = getTickCount()
    if key == KEY_TOGGLE_QA and not isSearchMode then
        if isInputActive then return end
        if (now - lastRKeyPressTime) < doublePressTime then
            isInputActive = true
            isSearchMode = false
            quickAddReplacing = false
            currentInput = ""
            selectedListItem = -1
            currentPage = 1
            ignoreEnterUntil = now + 200
            if listModes[currentListIndex] == "mostused" then
                generateMostUsedList()
            end

            lastRKeyPressTime = 0
        else
            lastRKeyPressTime = now
        end
        return
    end
    
    --SEARCH
    if key == keySearch then
        if isInputActive then
            beginSearch()
            quickAddReplacing = true
            return
        else
            -- Abrir Search directamente
            if (now - lastRKeyPressTime) < doublePressTime then
                isInputActive = true
                quickAddReplacing = false
                beginSearch()
                lastRKeyPressTime = 0
            else
                lastRKeyPressTime = now
            end
            return
        end
    end
end
bindKey(KEY_TOGGLE_QA, "down", mainToggle)
bindKey(keySearch, "down", mainToggle)

function beginSearch()
    isSearchMode = true
    searchInput = ""
    searchResults = {}
    selectedListItem = -1
    -- Set to a random page if no object is selected
    if #globalObjectsList > 0 then
        local totalPages = math.max(1, math.ceil(#globalObjectsList / maxListItems))
        currentPage = math.random(1, totalPages)
    else
        currentPage = 183
    end

    if exports["editor_main"]:getMode() == 1 then
        exports["editor_main"]:setMode(2)
    end

    -- AUTO POSICIÓN SI HAY OBJETO SELECCIONADO
    local sel = getSelectedEditorObject()
    if sel and isElement(sel) then
        local model = getElementModel(sel)

        table.sort(globalObjectsList, function(a,b) return a.id < b.id end)

        for i,obj in ipairs(globalObjectsList) do
            if obj.id == model then
                currentPage = math.ceil(i / maxListItems)
                selectedListItem = i - 1
                searchResults = globalObjectsList
                updatePreview(model)
                return
            end
        end
    end

    -- si no había objeto seleccionado > mostrar lista global completa
    table.sort(globalObjectsList, function(a,b) return a.id < b.id end)
    searchResults = globalObjectsList
end

-- bindKey(keySearch, "down", beginSearch)

local previewObject = nil

function destroyPreview(replaced)

    local sel = getSelectedEditorObject()
    if not replaced and sel then
        local restoreObj = setElementModel(sel, originalModel)
    end

    if isElement(previewObject) then
        destroyElement(previewObject)
        previewObject = nil
    end
end

function updatePreview(modelID)
    local sel = getSelectedEditorObject()
    if not modelID or not isValidModel(modelID) then
        destroyPreview()
        return
    end
    destroyPreview()

    if quickAddReplacing and sel then
        originalModel = getElementModel(sel)
        setElementModel(sel, modelID)
        return
    end

    local cx, cy, cz, lx, ly, lz = getCameraMatrix()
    local dirX, dirY, dirZ = lx - cx, ly - cy, lz - cz
    local len = math.sqrt(dirX * dirX + dirY * dirY + dirZ * dirZ)
    if len == 0 then len = 1 end
    dirX, dirY, dirZ = dirX / len, dirY / len, dirZ / len

    -- Default posicion de preview
    local px, py, pz = cx + dirX * 4, cy + dirY * 4, cz + dirZ * 4

    previewObject = createObject(modelID, px, py, pz)
    if not previewObject then return end

    setElementDimension(previewObject, exports["editor_main"]:getWorkingDimension())
    setElementAlpha(previewObject, PreviewAlpha)
    setElementCollisionsEnabled(previewObject, false)

    local x1, y1, z1, x2, y2, z2 = getElementBoundingBox(previewObject)
    local radius = 2
    if x1 then
        radius = math.max(math.abs(x2 - x1), math.abs(y2 - y1), math.abs(z2 - z1)) / 2
    end

    -- Calcular por radius
    local minDist, maxDist, radiusThreshold = 5, 100, 110
    local desiredDist
    if radius > radiusThreshold then
        desiredDist = math.max(minDist, math.min(maxDist, radius * 1.1))
    else
        desiredDist = math.max(minDist, radius * 2.5)
    end

    -- Hit
    local hit, hx, hy, hz = processLineOfSight(cx, cy, cz, cx + dirX * desiredDist, cy + dirY * desiredDist, cz + dirZ * desiredDist, true, true, true, true, true, false, false)
    local finalX, finalY, finalZ
    if hit then
        finalX, finalY, finalZ = hx, hy, hz + 0.5
    else
        finalX, finalY, finalZ = cx + dirX * desiredDist, cy + dirY * desiredDist, cz + dirZ * desiredDist
    end

    setElementPosition(previewObject, finalX, finalY, finalZ)
    setElementDoubleSided(previewObject, true)
    engineSetModelLODDistance(getElementModel(previewObject), 325)

    -- Rotar
    setTimer(function()
        if isElement(previewObject) then
            setElementRotation(previewObject, 0, 0, (getTickCount() / 20) % 360)
        end
    end, 50, 0)
end

function toggleReplace()
    if not isInputActive then return end
        if not isSearchMode then
            quickAddReplacing = not quickAddReplacing
        end

        if isSearchMode and searchResults[selectedListItem + 1 ] then
            quickAddReplacing = not quickAddReplacing
        end

        -- if quickAddReplacing then 
        --     outputChatBox("og"..originalModel)
        --     setElementModel(getSelectedEditorObject(), originalModel)
        -- end
        updatePreviewFromList()
end
bindKey(KEY_REPLACE, "down", toggleReplace)

------------------------
-- INPUT
------------------------

function onClientGeneralKeyPress(key, press)
    if not isInputActive or not press then return end
		if key == KEY_CANCEL then
			isInputActive = false
			isSearchMode = false
			searchInput = ""
			searchResults = {}
			selectedListItem = -1
			destroyPreview()
			return
		end

    local list = getCurrentList()
    local totalItems = #list
    local totalPages = math.max(1, math.ceil(totalItems / maxListItems))

    if isChatBoxInputActive() then return end
	
    if key == "backspace" then
        currentInput = string.sub(currentInput, 1, -2)
        searchInput = string.sub(searchInput, 1, -2 )
        if isSearchMode then currentPage = 1
            selectedListItem = -1
        end
    end
	
		if key == NAV_UP or key == NAV_UP_ALT then
		local activeList = isSearchMode and searchResults or getCurrentList()
		local totalItemsLocal = #activeList
		if totalItemsLocal > 0 then
			local startIndexOnPage = (currentPage - 1) * maxListItems
			if selectedListItem == -1 then
				selectedListItem = math.min(currentPage * maxListItems - 1, totalItemsLocal - 1)
			else
				selectedListItem = selectedListItem - 1
			end
			if selectedListItem < startIndexOnPage then
				currentPage = currentPage - 1
				if currentPage < 1 then currentPage = math.max(1, math.ceil(totalItemsLocal / maxListItems)) end
				selectedListItem = math.min((currentPage * maxListItems) - 1, totalItemsLocal - 1)
			end
            updatePreviewFromList()
		end
		return
	elseif key == NAV_DOWN or key == NAV_DOWN_ALT then
		local activeList = isSearchMode and searchResults or getCurrentList()
		local totalItemsLocal = #activeList
		if totalItemsLocal > 0 then
			local endIndexOnPage = math.min(currentPage * maxListItems - 1, totalItemsLocal - 1)
			if selectedListItem == -1 then
				selectedListItem = (currentPage - 1) * maxListItems
			else
				selectedListItem = selectedListItem + 1
			end
			if selectedListItem > endIndexOnPage or selectedListItem >= totalItemsLocal then
				currentPage = currentPage + 1
				local totalPagesLocal = math.max(1, math.ceil(totalItemsLocal / maxListItems))
				if currentPage > totalPagesLocal then currentPage = 1 end
				selectedListItem = (currentPage - 1) * maxListItems
			end
            updatePreviewFromList()
			currentPage = math.ceil((selectedListItem + 1) / maxListItems)
		end
		return
	end
	
    local numericValue = tonumber(key)
    if not isSearchMode and not numericValue and string.sub(key, 1, 4) == "num_" then
        numericValue = tonumber(string.sub(key, 5))
    end
    if numericValue ~= nil and not isSearchMode then
        currentInput = currentInput .. numericValue
        selectedListItem = -1
        return
    end

    if key == keyPagePrev then
        if currentPage > 1 then
            currentPage = currentPage - 1
            selectedListItem = -1
            destroyPreview()
        end
        return
    end
    if key == keyPageNext then
        local totalSearchPages = math.max(1, math.ceil(#searchResults / maxListItems))
        if isSearchMode and currentPage < totalSearchPages then
            currentPage = currentPage + 1
            selectedListItem = -1
            destroyPreview()
        elseif not isSearchMode and currentPage < totalPages then
            currentPage = currentPage + 1
            selectedListItem = -1
            destroyPreview()
        end
        return
    end


if key == KEY_CONFIRM or key == KEY_CONFIRM_ALT or key == KEY_CONFIRM_ALT2 then
    if getTickCount() < ignoreEnterUntil then return end

    local modelID
    if isSearchMode and selectedListItem ~= -1 and searchResults[selectedListItem + 1] then
        modelID = searchResults[selectedListItem + 1].id
        currentInput = tostring(modelID)
    else
        modelID = tonumber(currentInput)
    end

    if not modelID then return end

    if isValidModel(modelID) then
        local selObj = getSelectedEditorObject()
        if selObj and isElement(selObj) and quickAddReplacing then
            local oldModel = getElementModel(selObj)
            setElementModel(selObj, modelID)
            triggerServerEvent("syncProperties", localPlayer, {model = oldModel}, {model = modelID}, selObj)
            outputChatBox(rtool.."#FFFFFFChanged to: " .. modelID .. " (" .. getObjectNameFromID(modelID) .. ")", 90, 32, 162, true)
        else    

            createEditorObject(modelID)

            if FavAutoTop and listModes[currentListIndex] == "favorites" then
                for i, obj in ipairs(favoriteObjects) do
                    if obj.id == modelID then
                        table.remove(favoriteObjects, i)
                        table.insert(favoriteObjects, 1, {id = modelID, name = getObjectNameFromID(modelID)})
                        saveObjectHistory()
                        break
                    end
                end
            end
        end

        local modelName = getObjectNameFromID(modelID)
        local foundIndex = -1
        for i, obj in ipairs(createdObjectsHistory) do
            if obj.id == modelID then
                foundIndex = i
                break
            end
        end
        if foundIndex ~= -1 then table.remove(createdObjectsHistory, foundIndex) end
        table.insert(createdObjectsHistory, 1, {id = modelID, name = modelName})
        saveObjectHistory()

		--Limpieza
        isInputActive = false
        isSearchMode = false
        searchInput = ""
        searchResults = {}
        selectedListItem = -1
        if quickAddReplacing then
            destroyPreview(true)
        else
            destroyPreview()
        end
    else
        outputChatBox(rtool.."#FFFFFFInvalid or unknown ID: "..tostring(currentInput), 255, 255, 255, true)
        return
    end
end


	if isSearchMode then
        local numericValue = tonumber(key)

        if not numericValue and string.sub(key, 1, 4) == "num_" then
            numericValue = tonumber(string.sub(key, 5))
        end

        if numericValue ~= nil and selectedListItem == -1 then
            searchInput = searchInput .. tostring(numericValue)
		elseif (key == "-" or key == "minus") and (getKeyState("lshift") or getKeyState("rshift")) and selectedListItem == -1 then
			searchInput = searchInput .. "_"
		elseif key:len() == 1 and key:match("[A-Za-z]") and selectedListItem == -1 then
			searchInput = searchInput .. key
		end
        -- currentPage = 1

        --Evitar que se cambie el item si se togglea freecam en search sin nada escrito
        if searchInput == "" then
            return
        else
            currentPage = 1
        end     

		searchResults = {}
		local added = {}
		for _, listName in ipairs(listModes) do
			local lst = (listName == "recent" and createdObjectsHistory)
				or (listName == "favorites" and favoriteObjects)
				or (listName == "mostused" and mostUsedObjects)
			for _, obj in ipairs(lst) do
				if obj.name and obj.name:lower():find(searchInput:lower(), 1, true) and not added[obj.id] then
					table.insert(searchResults, {id = obj.id, name = obj.name})
					added[obj.id] = true
				end
			end
		end

		-- Pon 'and #searchResults == 0' antes del then si quieres q solo se búsque cuando no haya resultados en las listas
		if enableGlobalSearch and globalObjectsLoaded then
			for _, obj in ipairs(globalObjectsList) do
				if (obj.name and obj.name:lower():find(searchInput:lower(), 1, true))
					or (obj.keywords and obj.keywords:lower():find(searchInput:lower(), 1, true)) then
					if not added[obj.id] then
						table.insert(searchResults, {id = obj.id, name = obj.name})
						added[obj.id] = true
					end
				end
			end
			--[[debug
			if #searchResults > 0 then
				outputChatBox ("Sin resultados en listas. Usando global", 100, 200, 255)
			else
				outputChatBox ("Ningun resultado en ambas listas", 100, 200, 255)
			end]]
		end

		return
	end

end
addEventHandler("onClientKey", root, onClientGeneralKeyPress)

-- Most used
function generateMostUsedList()
    local counts = {}
    for _, obj in ipairs(getElementsByType("object")) do
        local model = getElementModel(obj)
        if not mostUsedExclusions[model] then
            counts[model] = (counts[model] or 0) + 1
        end
    end
    mostUsedObjects = {}
    for model, count in pairs(counts) do
        table.insert(mostUsedObjects, {id = model, name = getObjectNameFromID(model), count = count})
    end
    table.sort(mostUsedObjects, function(a,b) return a.count > b.count end)
    -- Limitar a maxMostUsedPages
    local limit = maxMostUsedPages * maxListItems
    if #mostUsedObjects > limit then
        while #mostUsedObjects > limit do
            table.remove(mostUsedObjects)
        end
    end
end

function switchList()
    if isInputActive and not isSearchMode then
        currentListIndex = currentListIndex + 1
        if currentListIndex > #listModes then currentListIndex = 1 end
        currentPage = 1
        selectedListItem = -1
        if listModes[currentListIndex] == "mostused" then
            generateMostUsedList()
        end
    else
        return
    end
end

function toggleFavorite()
	if isPedInVehicle(localPlayer) then return end
    local modelID, modelName
    -- Si hay objeto seleccionado en el editor
    local selObj = getSelectedEditorObject()
    if selObj and isElement(selObj) then
        modelID = getElementModel(selObj)
        modelName = getObjectNameFromID(modelID)
    else
        local list
        if isSearchMode then
            list = searchResults
        else
            list = getCurrentList()
        end

        if selectedListItem ~= -1 and list[selectedListItem + 1] then
            modelID = list[selectedListItem + 1].id
            modelName = list[selectedListItem + 1].name
        end
    end
    if not modelID then
        -- outputChatBox(rtool.."#FFFFFFSelect an objet to add favorite.", 255,255,255,true)
        return
    end
    -- Verificar si ya esta en favoritos
    local foundIndex
    for i, obj in ipairs(favoriteObjects) do
        if obj.id == modelID then
            foundIndex = i
            break
        end
    end
    if foundIndex then
        table.remove(favoriteObjects, foundIndex)
        outputChatBox(rtool.."#FFFFFFRemoved from favorites: "..modelID.." ("..modelName..")", 255,255,255,true)
    else
        table.insert(favoriteObjects, 1, {id = modelID, name = modelName})
        outputChatBox(rtool.."#FFFFFFAdded to favorites: "..modelID.." ("..modelName..")", 255,255,255,true)
    end
    saveObjectHistory()
end

bindKey(keyListSwitch, "down", switchList)
bindKey(keyToggleFavorite, "down", toggleFavorite)
addCommandHandler("fav", toggleFavorite)

------------------------
-- RENDER
------------------------
local refX, refY = 2560, 1440

function renderInputText()
    if not isInputActive then return end
    if typingMode then isInputActive = false return end

    local list = getCurrentList()
    local screenW, screenH = guiGetScreenSize()

    local scaleX, scaleY = screenW / refX, screenH / refY
    local globalScale = math.min(scaleX, scaleY)

    local selObj = getSelectedEditorObject()

    if getTickCount() - cursorTimer > 500 then
        showCursor = not showCursor
        cursorTimer = getTickCount()
    end
    local cursor = (showCursor and selectedListItem == -1) and "|" or ""
    local displayText = ""
    local prefixText, prefixWidth = "", 0
    local afterPrefixText = ""
    local prefixFont = "pricedown"
    local afterPrefixFont = "default-bold"
    local prefixColor = textColor
    local afterPrefixColor = textColor 

    if selObj and isElement(selObj) then
        if isSearchMode then
            prefixText = "[#00C21CSEARCH#FFFFFF] "
            afterPrefixText = (selectedListItem == -1 and "NAME:#9F88C3 " .. searchInput .. cursor or "NAME: " .. searchInput .. cursor )
        else
            prefixText = "[#0066ff"..string.upper(listModes[currentListIndex]).."#FFFFFF] "
            afterPrefixText = "ID: " .. currentInput .. cursor
        end
        local ReplaceText = (quickAddReplacing and "\n#33cc33[REPLACING : #ffffff" .. string.upper(KEY_REPLACE) .. "#33cc33 ]" or "\n#ffcc00[NOT REPLACING : #ffffff" .. string.upper(KEY_REPLACE) .. " #ffcc00]")
        if not isSearchMode then
            afterPrefixText = afterPrefixText .. ReplaceText
        else
            if selectedListItem ~= -1 then
                afterPrefixText = afterPrefixText .. ReplaceText
            end
        end
    else
        if isSearchMode then
            prefixText = "[#00C21CSEARCH#FFFFFF] "
            afterPrefixText = (selectedListItem == -1 and "NAME:#9F88C3 " .. searchInput .. cursor or "NAME: " .. searchInput .. cursor )
        else
            prefixText = "[#0066ff"..string.upper(listModes[currentListIndex]).."#FFFFFF] "
            afterPrefixText = "ID: " .. currentInput .. cursor
        end
    end

    -- Calculate prefix width for alignment
    local prefixSize = (textSize / 1.15) * globalScale
    prefixWidth = dxGetTextWidth(prefixText, prefixSize, prefixFont, true)
    local textX = textPositionX * screenW
    local textY = textPositionY * screenH

    -- Draw border (shadow) for both prefix and afterPrefix
    dxDrawText(string.gsub(prefixText, "#%x%x%x%x%x%x", ""), textX, textY - 18, nil, nil, borderColor, prefixSize, prefixFont, "center", "center", false, false, false, false)
    dxDrawText(string.gsub(afterPrefixText, "#%x%x%x%x%x%x", ""), (textX + prefixWidth / 2), textY - 18, nil, nil, borderColor, textSize * globalScale, afterPrefixFont, "left", "center", false, false, false, false)

    -- Draw colored prefix and afterPrefix
    dxDrawText(prefixText, textX, textY - 20, nil, nil, prefixColor, prefixSize, prefixFont, "center", "center", false, false, false, true)
    dxDrawText(afterPrefixText, (textX + prefixWidth / 2), textY - 20, nil, nil, afterPrefixColor, textSize * globalScale, afterPrefixFont, "left", "center", false, false, false, true)

    local totalItems = #list
    local totalPages = math.max(1, math.ceil(totalItems / maxListItems))
    local startIndex = (currentPage - 1) * maxListItems + 1
    local endIndex = math.min(currentPage * maxListItems, totalItems)

    local currentYOffset = textY + (screenH * listOffsetY)

    if isSearchMode then
        list = searchResults
        totalItems = #list
        totalPages = math.max(1, math.ceil(totalItems / maxListItems))
        startIndex = (currentPage - 1) * maxListItems + 1
        endIndex = math.min(currentPage * maxListItems, totalItems)
        selectedItemColor = tocolor(0, 194, 28)
    else
        selectedItemColor = tocolor(61, 139, 255, 255) 
    end

    for i = startIndex, endIndex do
        local obj = list[i]
        local displayItem = obj.id .. " (" .. obj.name .. (obj.count and (", x"..obj.count) or "") .. ")"
        local itemColor = textColor
        if i - 1 == selectedListItem then 
            itemColor = selectedItemColor 
            dxDrawText("RETURN: ← BACKSPACE",(textPositionX * screenW) - (1 * scaleX), (textPositionY * screenH) - (80 * scaleY), nil, nil, tocolor(255, 255, 255, 150), 1.8 * globalScale, "default-bold", "center", "center", false, false, false, false)
        end

        dxDrawText(displayItem, (textPositionX * screenW) - (160 * scaleX), currentYOffset, nil, nil, borderColor, listItemSize * globalScale, "default-bold", "left", "center", false, false, false, true)
        dxDrawText(displayItem, (textPositionX * screenW) - (158 * scaleX), currentYOffset - (2 * scaleY), nil, nil, itemColor, listItemSize * globalScale, "default-bold", "left", "center", false, false, false, false)

        currentYOffset = currentYOffset + (screenH * 0.025)
    end

    local pageIndicatorText = "< "..keyPagePrev.."  " .. currentPage .. "/" .. totalPages .. "  "..keyPageNext.." >"
    dxDrawText(pageIndicatorText, textX, currentYOffset + (screenH * 0.01), nil, nil, borderColor, (listItemSize - 0.2) * globalScale, "default-bold", "center", "center", false, false, false, true)
    dxDrawText(pageIndicatorText, textX - (1 * scaleX), currentYOffset + (screenH * 0.01) - (1 * scaleY), nil, nil, selectedItemColor, (listItemSize - 0.2) * globalScale, "default-bold", "center", "center", false, false, false, false)

    -- dxDrawText("CONFIRM: "..string.upper(KEY_CONFIRM).." - "..string.upper(KEY_CONFIRM_ALT2), textX - (1 * scaleX), currentYOffset + (screenH * 0.04) - (1 * scaleY), nil, nil, tocolor(200, 200, 200, 120), 1.5 * globalScale, "default", "center", "center", false, false, false, false)
    -- dxDrawText("CANCEL: "..string.upper(KEY_CANCEL), textX - (1 * scaleX), currentYOffset + (screenH * 0.055) - (1 * scaleY), nil, nil,tocolor(200, 200, 200, 120), 1.5 * globalScale, "default", "center", "center", false, false, false, false)
    -- dxDrawText("/fav :: ADD OBJECT TO FAVORITES", textX - (1 * scaleX), currentYOffset + (screenH * 0.07) - (1 * scaleY), nil, nil,tocolor(200, 200, 200, 120), 1.5 * globalScale, "default", "center", "center", false, false, false, false)
    -- if not isSearchMode then
    --     dxDrawText("SEARCH: "..string.upper(keySearch).." / CHANGE LIST: "..string.upper(keyListSwitch), textX - (1 * scaleX), currentYOffset + (screenH * 0.085) - (1 * scaleY), nil, nil, tocolor(200, 200, 200, 120), 1.5 * globalScale, "default", "center", "center", false, false, false, false)
    -- end

    -- if selObj then
    --     local ReplaceTextHelp = 0.1
    --     if isSearchMode then ReplaceTextHelp = 0.085 end
    --     dxDrawText("TOGGLE REPLACING: "..string.upper(KEY_REPLACE), textX - (1 * scaleX), currentYOffset + (screenH * ReplaceTextHelp) - (1 * scaleY), nil, nil, tocolor(200, 200, 200, 120), 1.5 * globalScale, "default", "center", "center", false, false, false, false)
    -- end
end
addEventHandler("onClientRender", root, renderInputText)

--Help

addEventHandler("onClientRender", root, function()
    if not isInputActive then return end

    -- local indexStr = (moveTipo == "circ" and "") or ("#" .. moveIndex)
    
    local text = "Confirm: #0066ff"..string.upper(KEY_CONFIRM).." / "..string.upper(KEY_CONFIRM_ALT).." #ffffff| Cancel: #0066ff"..string.upper(KEY_CANCEL).." #ffffff| Swap list: #0066ff"..string.upper(keyListSwitch).."#ffffff\nAdd to favorites: #0066ff/fav #ffffff| Search by name: #0066ff"..string.upper(keySearch).." #ffffff | Toggle Replace: #0066ff"..string.upper(KEY_REPLACE)
    
    local screenX, screenY = guiGetScreenSize()
    dxDrawText(text, 44, screenY - 87, screenX, screenY, tocolor(255, 255, 255, 180), 2, "default-bold", "center", "top", false, false, false, true)
end)


------------------------
-- UTILS
------------------------

function getCurrentList()
    if isSearchMode and searchResults[selectedListItem] then
        return searchResults
    elseif listModes[currentListIndex] == "recent" then
        return createdObjectsHistory
    elseif listModes[currentListIndex] == "mostused" then
        return mostUsedObjects
    elseif listModes[currentListIndex] == "favorites" then
        return favoriteObjects
    end
    return {}
end

function updatePreviewFromList()
    local activeList = isSearchMode and searchResults or getCurrentList()
    if activeList[selectedListItem + 1] then
        local id = activeList[selectedListItem + 1].id
        if isSearchMode then
            updatePreview(id)
        else
            currentInput = tostring(id)
            updatePreview(id)
        end
    end
end

function getSelectedEditorObject()
    if getResourceFromName(editorResource) then
        return exports[editorResource]:getSelectedElement()
    end
    return nil
end

function getObjectNameFromID(id)
    local numericID = tonumber(id)
    if not numericID then return "Unknown" end
    local name = engineGetModelNameFromID(numericID)
    return name or "Unknown"
end

function isValidModel(id)
    if not id then return false end
    local testObj = createObject(id, 0, 0, 0)
    if isElement(testObj) then
        destroyElement(testObj)
        return true
    end
    return false
end

--TO DO: Juntar doCreateElement y createEditorObject posibilemente
function createEditorObject(modelID)
    if not doCreateElement then
        outputChatBox(rtool.."Can't trigger 'doCreateElement', start Editor.", 255, 255, 0)
        return
    end
    local params = { model = modelID }
    doCreateElement("object", "editor_main", params)
    outputChatBox(rtool.."#FFFFFFCreated ID: " .. modelID .. " (" .. getObjectNameFromID(modelID) .. ")", 90, 32, 162, true)
end

-- marker pickup test
function createMarkerTest(pickup)
    if not doCreateElement then return end 
    local params = { type = pickup or "nitro" }
    doCreateElement("racepickup", "race", params)
end
addCommandHandler("qamarker", createMarkerTest)

function doCreateElement(elementType, resourceName, creationParameters, attachLater, shortcut)
    creationParameters = creationParameters or {}
    if not creationParameters.position then
        local cx, cy, cz, lx, ly, lz = getCameraMatrix()
        local hit, x, y, z = processLineOfSight(cx, cy, cz, lx, ly, lz, true, true, true, true, true, false, false)
        if hit then
            creationParameters.position = {x, y, z + 0.5}
        else
            creationParameters.position = {lx, ly, lz + 0.5}
        end
    end
    if attachLater == nil then attachLater = true end
    if triggerEvent("onClientElementPreCreate", root, elementType, resourceName, creationParameters, attachLater, shortcut) then
        triggerServerEvent("doCreateElement", localPlayer, elementType, resourceName, creationParameters, attachLater, shortcut)
    end
end

addEvent("updateKeybind", true)
-- Manejador de eventos para recibir las actualizaciones de la GUI
function handleRtoolKeybindUpdate(oldKey, newKey, functionName)
    -- Verificamos qué función se está intentando actualizar y usamos la referencia local
    -- que solo este archivo conoce.
    outputChatBox("hola")
    local funcRef = nil
    
    -- Mapeo de la cadena de texto (functionName) a la referencia local de la función
    if functionName == "mainToggle" then
        funcRef = mainToggle
    elseif functionName == "toggleReplace" then
        funcRef = toggleReplace
    elseif functionName == "switchList" then
        funcRef = switchList
    elseif functionName == "toggleFavorite" then
        funcRef = toggleFavorite
    end
    
    if funcRef then
        -- 1. Desvincular la tecla antigua usando la referencia local
        if oldKey and oldKey ~= "" then
            unbindKey(oldKey, "down", funcRef)
            outputChatBox("[#] #CCCCCCQuick Add: Unbound #FFA94D"..oldKey, 255, 255, 255, true) 
        end
        
        -- 2. Vincular la nueva tecla
        bindKey(newKey, "down", funcRef)
        outputChatBox("[#] #CCCCCCQuick Add: Bound #FFA94D"..newKey.." #CCCCCCto "..functionName, 255, 255, 255, true) 
    end
end

-- Registrar el manejador de eventos
addEventHandler("updateKeybind", root, handleRtoolKeybindUpdate)

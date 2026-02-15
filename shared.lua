rtool = "#0066ffR#ffcc00t#33cc33o#ff6666O#cc0000L #FFFFFF| "
versionRtool = "  v1.5 #ACDBF2(BETA)"

imgSizeX = 60  -- Icons
imgSizeY = imgSizeX + 10 

-- ========================
-- Global Variables 
-- ========================

univUI = false
dynamicFPS = true

-- Quick Edit
quickEditMode = false
typingMode = false

-- Warps
nofixEnabled = false
nosrefEnabled = false
isRewinding = false
rewindSpeed = 1
fastRewindSpeed = 4
classicMode = false

-- ========================
-- Key binds
-- ========================

-- -- Quick Edit
-- KEY_TOGGLE_EDIT = "Q" -- Toggle Quick Edit / toggleQuickEdit
-- KEY_NEXT_AXIS = "LCTRL" -- Next option / nextAxis
-- KEY_PREV_AXIS = "LALT" -- Previous option / prevAxis
-- KEY_BACKSPACE = "backspace" -- Backspace / backspaceQE
-- KEY_CONFIRM = "ENTER" -- Confirm / onConfirm
-- KEY_CONFIRM_ALT = "mouse1" -- Confirm (2) / onConfirm
-- KEY_CANCEL = "TAB" -- Cancel | Exit / quickEditCancel
-- KEY_REDO = "R" -- Redo / QuickRedoMain
-- KEY_REDO_TOGGLE = "LSHIFT" -- Toggle Redo mode / toggleRedo
-- KEY_ADD_ROTATION = "RSHIFT" -- Add Rotation / addRotToggle

--Chronos
KEY_RECORD = "c" -- Record / togglePauseOrRestart

-- -- Quick Add
-- KEY_TOGGLE_QA = "r" --Open Menu / onClientR_KeyPress
-- KEY_CANCEL = "tab" -- Cancel | Exit
-- KEY_REPLACE = "R" -- Replace / toggleReplace
-- keyPagePrev = "lctrl" -- Previous Page
-- keyPageNext = "lalt" -- Next Page
-- keyListSwitch = "LSHIFT" -- Switch List / switchList
-- keyToggleFavorite = "mouse4" -- Toggle Favorite / toggleFavorite
-- keySearch = "b" -- Search / onClientR_KeyPress
-- NAV_UP = "mouse_wheel_up" -- Navigate Up / IGNORE.
-- NAV_UP_ALT = "arrow_u" -- Navigate Up Alt / IGNORE.
-- NAV_DOWN = "mouse_wheel_down" -- Navigate Down / IGNORE.
-- NAV_DOWN_ALT = "arrow_d" --Navigate Down Alt / IGNORE.
-- KEY_CONFIRM = "enter" -- Confirm
-- KEY_CONFIRM_ALT = "num_enter" -- Confirm Alt
-- KEY_CONFIRM_ALT2 = "mouse1" -- Confirm Alt 2

--Warps
keyShowList = "lshift" -- Preview Warps / IGNORE.
keyUp = "arrow_u" -- Warp List Up
keyDown = "arrow_d" -- Warp List Down
KEY_REWIND = "backspace" -- Rewind / IGNORE.
KEY_FAST_REWIND = "q" -- Fast Rewind Modifier
SAVEWARP_KEY = "4" -- Save Warp / SAVEWARP_CMD
LOADWARP_KEY = "5" -- Load Warp / LOADWARP_CMD
DELETEWARP_KEY = "3" -- Delete Warp / DELETEWARP_CMD

-- ========================
-- Commands
-- ========================

--Warps
SAVEWARP_CMD = "sw"
LOADWARP_CMD = "lw"
DELETEWARP_CMD = "dw"

-- ========================
-- Utils
-- ========================

--Nexerver Mentions
addEvent("mentionSound", true)
addEventHandler("mentionSound", root, function()
    local sound = playSound("bonk.mp3")
end)

-- ========================
-- XML
-- ========================

local rtoolData = "usertool.xml"

function ensureUsertoolRoot()
    local root

    if not fileExists(rtoolData) then
        root = xmlCreateFile(rtoolData, "usertool")
        xmlSaveFile(root)
        return root
    end

    root = xmlLoadFile(rtoolData)

    if xmlNodeGetName(root) ~= "usertool" then
        local newRoot = xmlCreateFile(rtoolData, "usertool")

        for _, node in ipairs(xmlNodeGetChildren(root)) do
            local name = xmlNodeGetName(node)
            local clone = xmlCreateChild(newRoot, name)

            for k, v in pairs(xmlNodeGetAttributes(node) or {}) do
                xmlNodeSetAttribute(clone, k, v)
            end

            local function copyChildren(src, dest)
                for _, child in ipairs(xmlNodeGetChildren(src)) do
                    local c = xmlCreateChild(dest, xmlNodeGetName(child))

                    for kk, vv in pairs(xmlNodeGetAttributes(child) or {}) do
                        xmlNodeSetAttribute(c, kk, vv)
                    end

                    copyChildren(child, c)
                end
            end

            copyChildren(node, clone)
        end

        xmlUnloadFile(root)
        xmlSaveFile(newRoot)
        return newRoot
    end

    return root
end


function loadUsertoolGroup(groupName)
    local root = ensureUsertoolRoot()

    local group = xmlFindChild(root, groupName, 0)
    if not group then
        group = xmlCreateChild(root, groupName)
        xmlSaveFile(root)
    end

    return root, group
end


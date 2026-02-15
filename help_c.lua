
Help = {}
HelpShow = false
Item = "ReplacementToolEN"

local MainText = {
    ReplacementToolEN = [[
Replacement Tool is a modular script that replaces certain editor elements and other scripts without modifying them directly, adding Quality of Life features in the meantime.

The main tools included as of current version is QUICK-ADD, QUICK-EDIT, & WARPS.
KHRONOS, PREVIEW are experimental and DISPLAY is just a misc addon.

Except for QUICK-ADD and QUICK-EDIT. The other tools have a certain functions inside the Global UI.
Most of the commands have instructions when no arguments are given, for example write '/snap' and you'll get all arguments needed.

Global UI: Workaround to stop using commands for everything.
• Open by pressing 'G' twice. 
Instructions are shown in this Menu.

User data like saved warps, presets, quick add history/favorites are stored in 'usertool.xml'. If you are an user of past versions with saved data you can import from the old
XML files by copying the whole old file contents, and pasting into the matching section in 'usertool.xml'

* All the key binds specified in this help panel are the default binds, check 'shared.lua' for custom key binds.

Follow me on YouTube: anarchyRozen
]],
    QuickEdit1EN = [[
QUICK-EDIT: Object Properties Menu 

Use 'Q' to toggle Quick Edit, icon should turn green, select an object if you haven't yet and press 'Q' again to open Menu.
Navigating the Menu is by default using previously mentioned keys.
Press ENTER on a boolean type setting like COLLISIONS to toggle it true or false, or write the value you want to change and confirm with ENTER in settings that require it like X, Y, Z, etc.

When using the menu, press 'LSHIFT' to turn on MULTI-REDO, this allows you to do the next things:
    A. Make multiple changes without closing the menu
    B. Create a list of changes to apply later to different objects, or save it for later use.

    > Press TAB to finish adding changes/close menu when having REDO active.

    When you apply changes you will be able to REDO those changes to a different object pressing 'Q' + 'R' together.

Consider REDO will apply the exact changes you store in queue, so plan ahead if you want to repeat some actions.

In the file 'quickedit_c.lua' you can change the order of the Axis' as you wish or remove the ones you don't need/use.
]],
    QuickEdit2EN = [[
Available commands:
 • /uiqe - Toggles Quick Edit icon.
 • /xyz - Toggles the XYZ lines
 • /fakeclone - Toggles Clone Dummy, this is to add CLONE action to REDO history without actually cloning the object.
 • /presave <name> [IDs] - Saves REDO actions as a preset, name is obligatory, IDs are optional. 
    >If IDs are providen you will see the stored REDO actions when selecting an object with Quick Edit mode enabled. 
 • /preload <name> - Loads a previously saved preset.
 • /prelist <page> - shows saved REDO presets.

 Currently QUICK-EDIT includes the following options:
  1. ROTATION X, Y, Z
  2. MODEL - Changes object model ID
  3. SCALE - Changes object scale
  4. COLLISIONS - Toggles object collisions true/false
  5. DOUBLESIDE - Toggles object doubleside true/false
  Custom:
  6. OFFSET
  7. CLONE
  8. ZERO
  Check part 3 for more info of the custom options.
]],
     QuickEdit3EN = [[
 • ADD ROTATION: Press 'RSHIFT' while being at X Y or Z, write "+amount" to add rotation. For some reason using "-" doesn't work for REDO, but "+" does.
 • ZERO: Sets object rotation to 0 on all axis.
 • CLONE: Clones the selected object, only useful when combining it with OFFSET.

 • OFFSET: Use this when you want to store position and rotation changes. 
 For example, you want to create an object 'preset' using a carshade and a bally, follow these steps:
    1. Select the object that will be the base of your preset.
    1. Open the Menu and toggle REDO (Left Shift).
    2. Use CLONE
    3. Use MODEL, change the ID to ballypllr (3437)
    4. Use OFFSET: Press ENTER and you'll see 'Move Object'    
        This is when you move the object and potentially rotate it too.
        Once you are satisfied with the position and rotation press ENTER again to store the OFFSET.
    5. Press TAB to finish adding changes.

Done! Now perform REDO on any object (preferably the same model as the base object) and you'll see the ballypllr appear on the desired position and rotation.

IMPORTANT: DON'T MOVE IT BEFORE USING OFFSET, OTHERWISE THE OFFSET WILL BE WRONG. DO NOT SELECT ANY OTHER OBJECT OR UNSELECT OBJECT.
]],

    QuickAddEN = [[
QUICK-ADD: Alternative for the object browser. Open the menu by pressing 'R' twice quickly. 
You can create objects by writing their object ID, or select an Item from one of the lists. The main lists are the following:

• RECENT: List of recently created objects using Quick-Add menu
• MOST USED: List of most used objects in the current map.
• FAVORITES: Self-explanatory. Write '/favr' while selecting an object.

Press LSHIFT to swap between lists. ▼ / ▲ or Mouse Wheel to navigate through the lists. Use ENTER/MOUSE1 to create object.

SEARCH:
> Press 'B' twice to open or press 'B' to switch the Search on Quick Add. Here you can write an object name to search
If you have an object selected when you open the Menu you will have the option to Replace said object with a new ID, original object rotatio and position remains.

> You can add objects to Favorites by pressing MOUSE4 while selecting an object or browsing the lists.
If you don't have mouse4, you can rebind it on 'shared.lua' section.

]],
    WarpsEN = [[WARPS: All the warps functionality known to man and more.
   Key features:
>You can preview your warps before loading them. (Press LSHIFT and ▼ / ▲ to preview, release LSHIFT to load.)
>When you load a warp, this selects said warp, so you don't have to write /lw <number> every time.
>You can save warps individually for each map.
>There's no infinite spam when loading/saving warps.
>Rewind and Fast Rewind feature. BACKSPACE and BACKSPACE + Q respectively.
>Your warps and settings remain between sessions. No matter if you restart script or reconnect.

Commands: PSA: <> obligatory argument, [] optional argument.
    • /sw - Save warp.
    • /lw [number] - Load warp • /lw <playerName> [number] - loads someone else's warp.
    • /lwp <playerName> - Loads someone else's warps.
    • /dw [number(s)/all] - Delete warp, delete multiple warps or all.
    • /wlist [page] - Lists saved warp lists.
    • /wl <name> - Load a warp list previously saved.
    • /ws <name> - Save current warps as a list.
    • /whud - Toggle Warps HUD mode.
    • /nofix - Auto-repair
    • /nosref - Unlimited Nitro
    • /snap <sf/lv/ls/spawn/warp/player> - Snap camera or car to location.
    • /classic - Toggle REWIND and PREVIEW off.
    • Hold LSHIFT, then ▼ / ▲ - Preview warps to load.

]],
    KhronosEN = [[ 
    KHRONOS: This script allows you to measure how long your map is, time-wise
    It also includes time displays to view time during Editor mode.
     >You can use REWIND from RtoOL Warps to rewind clock too.
    
    All the commands are accesible through the Global UI.

      >During test, inside a car:
    • Turn on Khronos via the Global UI
    • Press "C" to start recording. Or start driving in AUTO mode.
    • Press "C" again to pause and tap "C" twice to restart timer to 0
    • Use '/croti' to inject time. For example: 1m13s 

    When clock is running, Time Displays will be created each amount of time. 
    Default is 20 seconds.

    You can toggle them visible via the Global UI, clear them or save/load to have it for future
    sessions.

    There's two modes to start the clock
    MANUAL = Starts after pressing 'C' (DEFAULT)
    AUTO = Starts after pressing either 'W' or 'S', basically accelerating/reversing

    ]],

    DisplayEN = [[
    DISPLAY: This was the script that begun RtoOL. Lore aside, this is a simple display that replaces the race HUD when playing and adds a
    FPS and Ping Display. I decided to give it much more style though. Complements other RtoOL modules like Warps.
     > Includes other miscellaneous features.
    
    (!) Display assumes you have a modified Race script that hides the default HUD. You can find it in many places or modify it yourself.
       You can use it without modifying it, but you may see Display elements on top of Race HUD.

    When using Auto-Repair and Unlimited Nitro from Warps you WILL see a Checkmark that symbolizes it's enabled.

    Commands:
    • /visfx - Turns ON/OFF Speedometer Visual Effects.
    • /etog - Turns the HUD ON/OFF
    • /dynamicfps - Turns ON/OFF Dynamic FPS
        > Dynamic FPS sets FPS limit at 100 when map testing, and 51 while mapping
        > You can change values by using '/dynamicfps <fpsEditor> <fpsTest>'
    • /rlod [amount] - This is for the veteran users.
    
    ]],
    ReplacementToolES = [[
Replacement Tool es un script modular que reemplaza ciertos elementos del editor y otros scripts sin modificarlos directamente, añadiendo funciones de "Calidad de Vida" en el proceso.

Las herramientas principales incluidas en la versión actual son QUICK-ADD, QUICK-EDIT y WARPS.
KHRONOS y PREVIEW son experimentales y DISPLAY es solo un complemento misceláneo.

A excepción de QUICK-ADD y QUICK-EDIT, las otras herramientas tienen ciertas funciones dentro de la Interfaz Global (Global UI).
La mayoría de los comandos tienen instrucciones cuando no se dan argumentos; por ejemplo, escribe '/snap' y obtendrás todos los argumentos necesarios.

Global UI: Solución alternativa para dejar de usar comandos para todo.
• Ábrelo presionando 'G' dos veces. 
Las instrucciones se muestran en este Menú.

Los datos del usuario, como warps guardados, Presets de acciones para Quick Redo e historial/favoritos de Quick Add, se almacenan en 'usertool.xml'. Si eres usuario de versiones anteriores con datos guardados, puedes importar desde los antiguos archivos XML copiando todo el contenido del archivo viejo y pegándolo en la sección correspondiente en 'usertool.xml'.

* Todas las teclas asignadas especificadas en este panel de ayuda son las predeterminadas, revisa 'shared.lua' para ver las asignaciones personalizadas.

Sígueme en YouTube: anarchyRozen
]],
    QuickEdit1ES = [[
QUICK-EDIT: Menú de Propiedades del Objeto 

Usa 'Q' para alternar Quick Edit, el ícono debería ponerse verde. Selecciona un objeto si aún no lo has hecho y presiona 'Q' de nuevo para abrir el Menú.
Los botones para navegar el menú por defecto son LCTRL y LALT. Aparecerán abajo del Menú junto con otros tips.
Presiona ENTER en una configuración de tipo booleano como COLLISIONS para cambiarla a verdadero o falso, o escribe el valor que deseas cambiar y confirma con ENTER en propiedades que lo requieran como X, Y, Z, etc.

Al usar el menú, presiona 'LSHIFT' para activar MULTI-REDO, esto te permite hacer las siguientes cosas:
    A. Realizar múltiples cambios sin cerrar el menú.
    B. Crear una lista de cambios para aplicar más tarde a diferentes objetos, o guardarla como un preset.

    > Presiona TAB para terminar de agregar cambios/cerrar el menú cuando tengas REDO activo.

    Cuando apliques cambios, podrás REHACER esos cambios en un objeto diferente presionando 'Q' + 'R' juntos.

Considera que REDO aplicará los cambios exactos que almacenes en la cola, así que planifica con antelación si deseas repetir algunas acciones.

En el archivo 'quickedit_c.lua' puedes cambiar el orden de los Ejes como desees o eliminar los que no necesites/uses.
]],
    QuickEdit2ES = [[
Comandos disponibles:
 • /uiqe - Alterna el ícono de Quick Edit.
 • /xyz - Alterna las líneas XYZ.
 • /fakeclone - Alterna el "Clone Dummy" (Clon Simulado), esto es para agregar la acción de CLONAR a la lista de REDO sin clonar realmente el objeto.
 • /presave <nombre> [IDs] - Guarda las acciones de REDO en el historia como un Preset, el nombre es obligatorio, los IDs son opcionales. 
    > Si se proporcionan IDs, verás las acciones de REDO almacenadas al seleccionar un objeto con el modo Quick Edit habilitado. 
 • /preload <nombre> - Carga un Preset guardado con anterioridad.
 • /prelist <página> - Enumera los Presets guardados.

 Actualmente QUICK-EDIT incluye las siguientes opciones:
  1. ROTACIÓN X, Y, Z
  2. MODEL - Cambia el ID del modelo del objeto
  3. SCALE - Cambia la escala del objeto
  4. COLLISIONS - Alterna las colisiones del objeto 
  5. DOUBLESIDE - Alterna el doble cara del objeto
  Personalizado:
  6. OFFSET
  7. CLONE
  8. ZERO
  Revisa la parte 3 para más información sobre las opciones personalizadas.
]],
      QuickEdit3ES = [[
 • ADD ROTATION: Presiona 'RSHIFT' mientras estás en X, Y o Z, escribe "+cantidad" para agregar rotación. Por alguna razón, usar "-" no funciona para REDO, pero "+" sí.
 • ZERO: Establece la rotación del objeto a 0 en todos los ejes.
 • CLONE: Clona el objeto seleccionado, solo útil cuando se combina con OFFSET.

 • OFFSET: Usa esto cuando quieras almacenar cambios de posición y rotación. 
 Por ejemplo, si quieres crear un 'Preset' (preajuste) de objeto usando un carshade y una bally, sigue estos pasos:
    1. Selecciona el objeto que será la base de tu Preset
    1. Abre el Menú y activa REDO (Shift izq.)
    2. Usa CLONE
    3. Usa MODEL, cambia el ID a ballypllr (3437)
    4. Usa OFFSET: Presiona ENTER y verás 'Move Object' (Mover Objeto).    
        Aquí es cuando mueves el objeto y potencialmente lo rotas también.
        Una vez que estés satisfecho con la posición y rotación, presiona ENTER nuevamente para almacenar el OFFSET.
    5. Presiona TAB para terminar de agregar cambios.

¡Listo! Ahora realiza REDO en cualquier objeto (preferiblemente el mismo modelo que el objeto base) y verás aparecer la ballypllr en la posición y rotación deseadas.

IMPORTANTE: NO LO MUEVAS ANTES DE USAR OFFSET, DE LO CONTRARIO EL OFFSET ESTARÁ MAL. NO SELECCIONES NINGÚN OTRO OBJETO NI DESELECCIONES EL OBJETO.
]],

    QuickAddES = [[
QUICK-ADD: Alternativa para el navegador de objetos. Abre el menú presionando 'R' dos veces rápidamente. 
Puedes crear objetos escribiendo su ID de objeto, o seleccionar un Ítem de una de las listas. Las listas principales son las siguientes:

• RECENT: Lista de objetos creados recientemente usando el menú Quick-Add.
• MOST USED: Lista de los objetos más usados en el mapa actual.
• FAVORITES: Se explica solo. Escribe '/favr' mientras seleccionas un objeto.

Presiona LSHIFT para cambiar entre listas. ▼ / ▲ o Rueda del Ratón para navegar a través de las listas. Usa ENTER/MOUSE1 para crear el objeto.

BÚSQUEDA:
> Presiona 'B' dos veces para abrir o presiona 'B' para activar la Búsqueda en Quick Add. Aquí puedes escribir el nombre de un objeto para buscar.
Si tienes un objeto seleccionado cuando abres el Menú, tendrás la opción de Reemplazar dicho objeto con un nuevo ID; la rotación y posición del objeto original permanecen.

> Puedes agregar objetos a Favoritos presionando MOUSE4 mientras seleccionas un objeto o navegas por las listas.
Si no tienes mouse4, puedes reasignarlo en la sección 'shared.lua'.

]],
    WarpsES = [[WARPS: Toda la funcionalidad de warps conocida por el hombre y más.
   Características clave:
> Puedes previsualizar tus warps antes de cargarlos. (Presiona LSHIFT y ▼ / ▲ para previsualizar, suelta LSHIFT para cargar.)
> Cuando cargas un warp, esto selecciona dicho warp, así no tienes que escribir /lw <número> cada vez.
> Puedes guardar warps individualmente para cada mapa.
> No hay spam infinito al cargar/guardar warps.
> Función de Rebobinar (Rewind) y Rebobinar Rápido. BACKSPACE y BACKSPACE + Q respectivamente.
> Tus warps y configuraciones permanecen entre sesiones. No importa si reinicias el script o te reconectas.

Comandos: AVISO: <> argumento obligatorio, [] argumento opcional.
    • /sw - Guardar warp.
    • /lw [número] - Cargar warp • /lw <nombreJugador> [número] - carga el warp de alguien más.
    • /lwp <nombreJugador> - Carga los warps de alguien más.
    • /dw [número(s)/all] - Borrar warp, borrar múltiples warps o todos.
    • /wlist [página] - Enumera las listas de warps guardadas.
    • /wl <nombre> - Carga una lista de warps guardada previamente.
    • /ws <nombre> - Guarda los warps actuales como una lista.
    • /whud - Alterna el modo HUD de Warps.
    • /nofix - Auto-reparación.
    • /nosref - Nitro Ilimitado.
    • /snap <sf/lv/ls/spawn/warp/player> - Ajusta la cámara o el auto a una ubicación.
    • /classic - Desactiva REWIND y PREVIEW.
    • Mantén LSHIFT, luego ▼ / ▲ - Previsualiza warps para cargar.

]],
    KhronosES = [[ 
    KHRONOS: Este script te permite medir qué tan largo es tu mapa, en cuanto a tiempo.
    También incluye visualizadores de tiempo para ver el tiempo durante el modo Editor.
     > Puedes usar REWIND de RtoOL Warps para rebobinar el reloj también.
    
    Todos los comandos son accesibles a través de la Interfaz Global (Global UI).

      > Durante la prueba, dentro de un auto:
    • Enciende Khronos vía la Global UI.
    • Presiona "C" para comenzar a grabar. O comienza a conducir en modo AUTO.
    • Presiona "C" de nuevo para pausar y toca "C" dos veces para reiniciar el temporizador a 0.
    • Usa '/croti' para inyectar tiempo. Por ejemplo: 1m13s 

    Cuando el reloj está corriendo, se crearán Visualizadores de Tiempo cada cierta cantidad de tiempo. 
    El valor predeterminado es 20 segundos.

    Puedes alternar su visibilidad vía la Global UI, borrarlos o guardar/cargar para tenerlos en futuras
    sesiones.

    Hay dos modos para iniciar el reloj:
    MANUAL = Inicia después de presionar 'C' (PREDETERMINADO)
    AUTO = Inicia después de presionar 'W' o 'S', básicamente acelerando/retrocediendo

    ]],

    DisplayES = [[
    DISPLAY: Este fue el script que inició RtoOL. Dejando la historia de lado, este es un visualizador simple que reemplaza el HUD de carrera al jugar y añade un
    visualizador de FPS y Ping. Sin embargo, decidí darle mucho más estilo. Complementa otros módulos de RtoOL como Warps.
     > Incluye otras características misceláneas.
    
    (!) Display asume que tienes un script de Carrera modificado que oculta el HUD predeterminado. Puedes encontrarlo en muchos lugares o modificarlo tú mismo.
       Puedes usarlo sin modificarlo, pero podrías ver elementos de Display encima del HUD de Carrera.

    Cuando uses Auto-Reparación y Nitro Ilimitado de Warps VERÁS una marca de verificación que simboliza que está habilitado.

    Comandos:
    • /visfx - Enciende/Apaga los Efectos Visuales del Velocímetro.
    • /etog - Enciende/Apaga el HUD.
    • /dynamicfps - Enciende/Apaga los FPS Dinámicos.
        > FPS Dinámicos establece el límite de FPS en 100 al probar el mapa, y 51 mientras mapeas.
        > Puedes cambiar los valores usando '/dynamicfps <fpsEditor> <fpsTest>'
    • /rlod [cantidad] - Esto es para los usuarios veteranos.
    
    ]]
}

function toggleHELP()
    HelpShow = not HelpShow
    if HelpShow then
        -- outputChatBox("Debug")    
        showHelpPanel()
    else
        guiSetVisible(Help.CloseButton, false)
        guiSetVisible(Help.List, false)
        showCursor(false)
    end
end
addCommandHandler("rhelp", toggleHELP)

function showHelpPanel()
    Help.CloseButton = guiCreateButton(0.71, 0.79, 0.10, 0.07, "Close ", true)


    -- Help.CommandsButton = guiCreateButton(0.71, 0.71, 0.10, 0.07, "Commands", true)
    -- guiSetFont(Help.CommandsButton, "default-bold-small")


    Help.List = guiCreateGridList(0.71, 0.17, 0.11, 0.50, true)
    guiGridListSetSortingEnabled(Help.List, false)
    guiGridListAddColumn(Help.List, "Select", 0.9)
    for i = 1, 15 do
        guiGridListAddRow(Help.List)
    end
    guiGridListSetItemText(Help.List, 1, 1, "Replacement Tool", false, false)
    guiGridListSetItemText(Help.List, 2, 1, "Quick Edit", false, false)
    guiGridListSetItemText(Help.List, 3, 1, "Quick Edit (2)", false, false)
    guiGridListSetItemText(Help.List, 4, 1, "Quick Edit (3)", false, false)
    guiGridListSetItemText(Help.List, 5, 1, "Quick Add", false, false)
    guiGridListSetItemText(Help.List, 6, 1, "Warps", false, false)
    guiGridListSetItemText(Help.List, 7, 1, "Khronos", false, false)
    guiGridListSetItemText(Help.List, 8, 1, "---------", false, false)
    guiGridListSetItemText(Help.List, 9, 1, "Replacement Tool ES", false, false)  
    guiGridListSetItemText(Help.List, 10, 1, "Quick Edit ES", false, false)  
    guiGridListSetItemText(Help.List, 11, 1, "Quick Edit (2) ES", false, false)  
    guiGridListSetItemText(Help.List, 12, 1, "Quick Edit (3) ES", false, false)  
    guiGridListSetItemText(Help.List, 13, 1, "Quick Add ES", false, false)  
    guiGridListSetItemText(Help.List, 14, 1, "Warps ES", false, false)  
    guiGridListSetItemText(Help.List, 15, 1, "Khronos ES", false, false)  
            showCursor(true)
end
-- addEventHandler("onClientResourceStart", root, showHelpPanel)

local screenW, screenH = guiGetScreenSize()


function renderHelpPanel()
    if not HelpShow then return end
    local text = MainText[Item]
        local mainFontSize = 1.3
        if screenW >= 1440 then 
            mainFontSize = 2.3
        elseif screenW >= 1024 then
            mainFontSize = 1.8
        else
            mainFontSize = 1.3
        end
        dxDrawLine((screenW * 0.1727) - 1, (screenH * 0.0979) - 1, (screenW * 0.1727) - 1, screenH * 0.9049, tocolor(0, 0, 0, 255), 1, false)
        dxDrawLine(screenW * 0.8211, (screenH * 0.0979) - 1, (screenW * 0.1727) - 1, (screenH * 0.0979) - 1, tocolor(0, 0, 0, 255), 1, false)
        dxDrawLine((screenW * 0.1727) - 1, screenH * 0.9049, screenW * 0.8211, screenH * 0.9049, tocolor(0, 0, 0, 255), 1, false)
        dxDrawLine(screenW * 0.8211, screenH * 0.9049, screenW * 0.8211, (screenH * 0.0979) - 1, tocolor(0, 0, 0, 255), 1, false)
        dxDrawRectangle(screenW * 0.1727, screenH * 0.0979, screenW * 0.6484, screenH * 0.8069, tocolor(157, 53, 191, 152), false)
        dxDrawRectangle(screenW * 0.1840, screenH * 0.1708, screenW * 0.5199, screenH * 0.6896, tocolor(56, 23, 73, 164), false)
        dxDrawText(rtool.. "Replacement Tool" ..versionRtool, screenW * 0.3801, screenH * 0.1194, screenW * 0.6266, screenH * 0.1569, tocolor(255, 255, 255, 255), 3.00, "default-bold", "center", "top", false, false, false, true, false)
        dxDrawText(text, screenW * 0.1879, screenH * 0.1896, screenW * (0.1840 + 0.5199), screenH * (0.1708 + 0.6896),  tocolor(255, 255, 255, 255), mainFontSize, "sans", "left", "top", false, true, false, false, false)
end
addEventHandler("onClientRender", root, renderHelpPanel)

function GUIclick()
    if source == Help.CloseButton then
        showCursor(false)
        guiSetVisible(Help.CloseButton, false)
        -- guiSetVisible(Help.CommandsButton, false)
        guiSetVisible(Help.List, false)
        HelpShow = false
    elseif source == Help.CommandsButton then
        openCommandsGUI()
    elseif source == Help.List then
        local selectedRow, selectedCol = guiGridListGetSelectedItem(Help.List)
        if selectedRow ~= -1 then
            local selectedText = guiGridListGetItemText(Help.List, selectedRow, selectedCol)
            -- outputChatBox(selectedText)
            if selectedText == "Replacement Tool" then
                Item = "ReplacementToolEN"
            elseif selectedText == "Quick Edit" then 
                Item = "QuickEdit1EN"
            elseif selectedText == "Quick Edit (2)" then
                Item = "QuickEdit2EN"
            elseif selectedText == "Quick Edit (3)" then
                Item = "QuickEdit3EN"
            elseif selectedText == "Quick Add" then
                Item = "QuickAddEN"
            elseif selectedText == "Warps" then
                Item = "WarpsEN"
            elseif selectedText == "Khronos" then
                Item = "KhronosEN"
            elseif selectedText == "Display" then
                Item = "DisplayEN"
            elseif selectedText == "Replacement Tool ES" then
                Item = "ReplacementToolES"
            elseif selectedText == "Quick Edit ES" then 
                Item = "QuickEdit1ES"
            elseif selectedText == "Quick Edit (2) ES" then
                Item = "QuickEdit2ES"
            elseif selectedText == "Quick Edit (3) ES" then
                Item = "QuickEdit3ES"
            elseif selectedText == "Quick Add ES" then
                Item = "QuickAddES"
            elseif selectedText == "Warps ES" then
                Item = "WarpsES"
            elseif selectedText == "Khronos ES" then
                Item = "KhronosES"
            elseif selectedText == "Display ES" then
                Item = "DisplayES"
            end
        end
    end

end
addEventHandler("onClientGUIClick", root, GUIclick) 

-- i hate this fuck mta ui

local sx, sy = guiGetScreenSize()
local w, h = sx*0.45, sy*0.55
local x, y = (sx-w)/2, (sy-h)/2

local window
local tabpanel
local saveBtn
local restoreBtn
local closeBtn

local currentTab = "QuickEdit"
local editFields = {}

local capturingKey = nil

function refreshTab(tabName)
    if not editFields[tabName] then return end

    for _, v in ipairs(KEY_DEFAULTS[tabName]) do
        local value = settings[v.id] or v.default
        guiSetText(editFields[tabName][v.id].edit, value)
    end
end

function createCommandsGUI()
    if window then return end

    window = guiCreateWindow(x, y, w, h, "Commands", false)
    guiWindowSetSizable(window, false)

    tabpanel = guiCreateTabPanel(0.025, 0.07, 0.95, 0.75, true, window)

    for tabName, values in pairs(KEY_DEFAULTS) do
        local tab = guiCreateTab(tabName, tabpanel)
        -- guiSetSelectedTab(tostring(currentTab), tabpanel)  -- Fuerza que QuickEdit sea la inicial
        currentTab = guiGetText(guiGetSelectedTab(tabpanel, 0))
        refreshTab(currentTab)


        local scroll = guiCreateScrollPane(0.01,0.01,0.98,0.98,true,tab)
        editFields[tabName] = {}

        local yoff = 0
        for _, v in ipairs(values) do
            guiCreateLabel(0.02, yoff, 0.5, 0.05, v.desc, true, scroll)

            local edit = guiCreateEdit(0.52, yoff, 0.25, 0.05, settings[v.id] or v.default, true, scroll)
            guiEditSetReadOnly(edit, true)

            local btn = guiCreateButton(0.79, yoff, 0.18, 0.05, "Default", true, scroll)

            editFields[tabName][v.id] = {edit=edit, button=btn}

            addEventHandler("onClientGUIFocus", edit, function()
                capturingKey = { tab=tabName, id=v.id, edit=edit }
                guiSetText(edit, "Press a key...")
            end)

            addEventHandler("onClientGUITabSwitched", tabpanel, function(tab)
                currentTab = guiGetText(tab)
                refreshTab(currentTab)
            end)

            addEventHandler("onClientGUIClick", btn, function()
                settings[v.id] = v.default
                guiSetText(edit, v.default)
            end, false)

            yoff = yoff + 0.07
        end
    end

    saveBtn = guiCreateButton(0.02, 0.85, 0.25, 0.1, "SAVE", true, window)
    restoreBtn = guiCreateButton(0.30, 0.85, 0.35, 0.1, "RESTORE DEFAULT", true, window)
    closeBtn = guiCreateButton(0.70, 0.85, 0.27, 0.1, "CLOSE", true, window)

    addEventHandler("onClientGUIClick", saveBtn, function()
        saveSettings()
        applySettings()
        applyAllKeyBinds()
    end, false)

    addEventHandler("onClientGUIClick", closeBtn, function()
        guiSetVisible(window, false)
        -- showCursor(false)
    end, false)

    addEventHandler("onClientGUIClick", restoreBtn, function()
        local tab = guiGetSelectedTab(tabpanel)
        local name = guiGetText(tab)
        for _, v in ipairs(KEY_DEFAULTS[name]) do
            settings[v.id] = v.default
            guiSetText(editFields[name][v.id].edit, v.default)
        end
    end, false)

    addEventHandler("onClientKey", root, function(button, press)
        if capturingKey and press then
            settings[capturingKey.id] = button
            guiSetText(capturingKey.edit, button)
            capturingKey = nil
        end
    end)

    guiSetVisible(window, false)
end

function openCommandsGUI()
    if not window then createCommandsGUI() end
    refreshTab(currentTab)
    guiSetVisible(window, true)
    showCursor(true)
end

-- Definición de variables globales por si no existen (valores iniciales basados en el prompt)
-- IMPORTANTE: En un entorno MTA real, estas variables YA estarían definidas en shared.lua.
-- Las definimos aquí solo para que el código sea ejecutable.
KEY_TOGGLE_EDIT = KEY_TOGGLE_EDIT or "Q"
KEY_NEXT_AXIS = KEY_NEXT_AXIS or "lctrl"
KEY_PREV_AXIS = KEY_PREV_AXIS or "lalt"
KEY_BACKSPACE = KEY_BACKSPACE or "backspace"
KEY_CONFIRM = KEY_CONFIRM or "enter"
KEY_CONFIRM_ALT = KEY_CONFIRM_ALT or "mouse1"
KEY_CANCEL = KEY_CANCEL or "tab" -- Duplicada, se usará la de Quick Edit
KEY_REDO = KEY_REDO or "R"
KEY_REDO_TOGGLE = KEY_REDO_TOGGLE or "lshift"
KEY_ADD_ROTATION = KEY_ADD_ROTATION or "rshift"

KEY_TOGGLE_QA = KEY_TOGGLE_QA or "r"
KEY_REPLACE = KEY_REPLACE or "r"
keyPagePrev = keyPagePrev or "lctrl"
keyPageNext = keyPageNext or "lalt"
keyListSwitch = keyListSwitch or "lshift"
keyToggleFavorite = keyToggleFavorite or "mouse4"
keySearch = keySearch or "b"
NAV_UP = NAV_UP or "mouse_wheel_up" 
NAV_UP_ALT = NAV_UP_ALT or "arrow_u" 
NAV_DOWN = NAV_DOWN or "mouse_wheel_down" 
NAV_DOWN_ALT = NAV_DOWN_ALT or "arrow_d"
KEY_CONFIRM_ALT2 = KEY_CONFIRM_ALT2 or "num_enter"

keyUp = keyUp or "arrow_u"
keyDown = keyDown or "arrow_d"
KEY_FAST_REWIND = KEY_FAST_REWIND or "q"
SAVEWARP_KEY = SAVEWARP_KEY or "4"
LOADWARP_KEY = LOADWARP_KEY or "5"
DELETEWARP_KEY = DELETEWARP_KEY or "3"

BIND_CONFIG = {
    ["Quick Edit"] = {
        { var = "KEY_TOGGLE_EDIT", name = "Toggle Quick Edit", func = "toggleQuickEdit" },
        { var = "KEY_NEXT_AXIS", name = "Next Option", func = "nextAxis" },
        { var = "KEY_PREV_AXIS", name = "Previous Option", func = "prevAxis" },
        { var = "KEY_BACKSPACE", name = "Backspace", func = "backspaceQE" },
        { var = "KEY_CONFIRM", name = "Confirm", func = "onConfirm" },
        { var = "KEY_CONFIRM_ALT", name = "Confirm (Alt)", func = "onConfirm" },
        { var = "KEY_CANCEL", name = "Cancel | Exit", func = "quickEditCancel" },
        { var = "KEY_REDO", name = "Redo", func = "QuickRedoMain" },
        { var = "KEY_REDO_TOGGLE", name = "Toggle Redo mode", func = "toggleRedo" },
        { var = "KEY_ADD_ROTATION", name = "Add Rotation", func = "addRotToggle" },
    },
    ["Quick Add"] = {
        { var = "KEY_TOGGLE_QA", name = "Open Menu", func = "onClientR_KeyPress" },
        { var = "KEY_CANCEL", name = "Cancel | Exit", func = nil }, -- Var Only
        { var = "KEY_REPLACE", name = "Replace", func = "toggleReplace" },
        { var = "keyPagePrev", name = "Previous Page", func = nil }, -- Var Only
        { var = "keyPageNext", name = "Next Page", func = nil }, -- Var Only
        { var = "keyListSwitch", name = "Switch List", func = "switchList" },
        { var = "keyToggleFavorite", name = "Toggle Favorite", func = "toggleFavorite" },
        { var = "keySearch", name = "Search", func = "onClientR_KeyPress" },
        { var = "KEY_CONFIRM", name = "Confirm", func = nil }, -- Var Only
        { var = "KEY_CONFIRM_ALT", name = "Confirm Alt", func = nil }, -- Var Only
        { var = "KEY_CONFIRM_ALT2", name = "Confirm Alt 2", func = nil }, -- Var Only
    },
    ["Warps"] = {
        -- 'keyShowList', 'KEY_REWIND' se excluyen por 'IGNORE.'
        { var = "keyUp", name = "Warp List Up", func = nil }, -- Var Only
        { var = "keyDown", name = "Warp List Down", func = nil }, -- Var Only
        { var = "KEY_FAST_REWIND", name = "Fast Rewind Modifier", func = nil }, -- Var Only
        -- Para Warps, asumimos que 'func' es el nombre del comando/función al que se hace bind.
        { var = "SAVEWARP_KEY", name = "Save Warp", func = "SAVEWARP_CMD" },
        { var = "LOADWARP_KEY", name = "Load Warp", func = "LOADWARP_CMD" },
        { var = "DELETEWARP_KEY", name = "Delete Warp", func = "DELETEWARP_CMD" },
    },
}

--- ====================================================================================
-- GUI CREATION
-- ====================================================================================

local screenW, screenH = guiGetScreenSize()
local windowWidth = 500 
local windowHeight = 550
local windowX = (screenW - windowWidth) / 2
local windowY = (screenH - windowHeight) / 2

local rtoolKeybindsWindow = nil
local isRtoolKeybindsGUIShown = false


function createRtoolKeybindsGUI()
    if rtoolKeybindsWindow and isElement(rtoolKeybindsWindow) then return end

    rtoolKeybindsWindow = guiCreateWindow(windowX, windowY, windowWidth, windowHeight, "RtoOL Keybinds", false)
    guiSetVisible(rtoolKeybindsWindow, false)

    local tabPanel = guiCreateTabPanel(0.02, 0.03, 0.96, 0.94, true, rtoolKeybindsWindow)
    

    -- Función auxiliar para crear la interfaz de una pestaña
    local function createBindTab(tabName, configTable)
        local tab = guiCreateTab(tabName, tabPanel)
        local yOffset = 0.05
        local rowHeight = 0.05
        
        for _, bindData in ipairs(configTable) do
            local varName = bindData.var
            local friendlyName = bindData.name
            local funcName = bindData.func
            local initialValue = _G[varName] or "MISSING" -- Obtener el valor actual

            guiCreateLabel(0.03, yOffset, 0.45, rowHeight, friendlyName .. ":", true, tab)
            
            local editBox = guiCreateEdit(0.48, yOffset, 0.25, rowHeight, tostring(initialValue), true, tab)
            
            local buttonText = funcName and "Set Bind" or "Set Key"
            local btn = guiCreateButton(0.75, yOffset, 0.22, rowHeight, buttonText, true, tab)
            
            addEventHandler("onClientGUIClick", btn, function()
                -- Llamar a la función robusta con los datos de configuración
                setRtoolKeyBind(varName, editBox, funcName)
            end, false)
            
            yOffset = yOffset + rowHeight + 0.01
        end
        
        -- Etiqueta informativa al final de la pestaña
        if yOffset + rowHeight < 0.95 then
             guiCreateLabel(0.03, yOffset + 0.02, 0.94, 0.03, "Note: 'Set Bind' updates key and bind. 'Set Key' only updates the variable.", true, tab)
        end
    end
    
    -- Crear las pestañas
    for tabName, configTable in pairs(BIND_CONFIG) do
        createBindTab(tabName, configTable)
    end
end

-- ====================================================================================
-- VISIBILITY CONTROL CON LA TECLA 'O' (Ejemplo, puede usar la tecla que prefiera)
-- ====================================================================================

function toggleRtoolKeybindsGUI()
    if not rtoolKeybindsWindow then
        createRtoolKeybindsGUI()
    end

    isRtoolKeybindsGUIShown = not isRtoolKeybindsGUIShown
    guiSetVisible(rtoolKeybindsWindow, isRtoolKeybindsGUIShown)

    if isRtoolKeybindsGUIShown then
        guiSetInputMode("no_binds_when_editing")
    else
        guiSetInputMode("allow_binds")
    end
end
addCommandHandler("rkeys", toggleRtoolKeybindsGUI)

-- Inicializar la GUI cuando el recurso inicia
addEventHandler("onClientResourceStart", resourceRoot, createRtoolKeybindsGUI)

-- ====================================================================================
-- FUNCIÓN DE LÓGICA ROBUSTA PARA ACTUALIZAR BINDS (En el archivo de la GUI)
-- ====================================================================================

--- @param keyVariable string Nombre de la variable global (ej: "KEY_RECORD")
--- @param editBox element Elemento GUI EditBox
--- @param functionName string|nil Nombre de la función o comando al que se hace bind. Nil si solo es para getKeyState.
function setRtoolKeyBind(keyVariable, editBox, functionName)
    local newKey = guiGetText(editBox)
    
    if not newKey or #newKey == 0 then
        outputChatBox("[#] #FF6666ERROR: #CCCCCCInvalid key input.", 255, 255, 255, true)
        return
    end

    -- 1. OBTENER EL VALOR DE LA TECLA ANTIGUA de la variable global
    local oldKey = _G[keyVariable]

    -- 2. Actualizar la variable global de inmediato (necesario para la persistencia y getKeyState)
    _G[keyVariable] = newKey 

    -- 3. Si hay una función asociada, disparamos un evento a nivel de recurso.
    if functionName then
        -- Enviamos la tecla antigua, la tecla nueva y el nombre de la función como string.
        -- Los módulos que escuchen este evento realizarán el unbind/bind.
        triggerEvent("updateKeybind", root, oldKey, newKey, functionName)
        
        outputChatBox(string.format("[#] #CCCCCCKey variable %s updated to #FFA94D'%s'. #CCCCCCSending update signal to modules...", keyVariable, newKey), 255, 255, 255, true)
    else
        -- Solo se actualiza la variable.
        outputChatBox(string.format("[#] #CCCCCCKey variable %s updated to #FFA94D'%s'. #CCCCCC(Variable only)", keyVariable, newKey), 255, 255, 255, true)
    end
end
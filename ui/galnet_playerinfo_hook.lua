-- ui/galnet_playerinfo_hook.lua
-- Collegamento tra GalNetPlayerInfoMenu e kuertee_ui_extensions (PlayerInfoMenu)

local GalNetPlayerInfoMenu = require("extensions.galnet.ui.menu_playerinfo_galnet")

-- 1. Sidebar: aggiungi la voce GalNet
local function injectGalNetSidebar(entries)
    DebugError("[GalNet] injectGalNetSidebar called! entries=" .. tostring(entries))
    return GalNetPlayerInfoMenu.injectSidebarEntry(entries)
end

-- 2. Gestione selezione sidebar
local function handleSidebarSelection(sectionID, existingBlocks)
    if GalNetPlayerInfoMenu.handleSidebarSelection(sectionID) then
        -- GalNet attivo: restituisci i blocchi da renderizzare
        return GalNetPlayerInfoMenu.buildRenderBlocks()
    end
    -- Non GalNet: restituisci i blocchi esistenti
    return existingBlocks
end

-- 3. Gestione click sui tab (da chiamare quando l’utente clicca su un tab GalNet)
local function handleTabSelection(tabID)
    return GalNetPlayerInfoMenu.handleTabSelection(tabID)
end

-- 4. Optional registration helper
local function registerWithPlayerInfoAPI(api)
    -- Try to register common hook points if present on the provided API object.
    -- This is intentionally conservative: if the API doesn't expose these
    -- methods, the function returns false and does nothing.
    if type(api) ~= "table" then return false end
    local ok = false
    if type(api.injectSidebarEntry) == "function" then
        api.injectSidebarEntry(injectGalNetSidebar)
        ok = true
    end
    if type(api.registerSidebarSelectionHandler) == "function" then
        api.registerSidebarSelectionHandler(handleSidebarSelection)
        ok = true
    end
    if type(api.registerTabClickHandler) == "function" then
        api.registerTabClickHandler(handleTabSelection)
        ok = true
    end
    return ok
end

local exported = {
    injectGalNetSidebar = injectGalNetSidebar,
    handleSidebarSelection = handleSidebarSelection,
    handleTabSelection = handleTabSelection,
    registerWithPlayerInfoAPI = registerWithPlayerInfoAPI,
}

-- Try to automatically register against commonly used kuertee/global PlayerInfo APIs.
-- Be conservative: we only call registerWithPlayerInfoAPI when we detect a table
-- or a function that returns a table. Also expose a helper for manual registration.
local function tryAutoRegister()
    local candidates = {
        "PlayerInfoAPI",
        "playerInfoAPI",
        "kuertee_ui_extensions",
        "kuertee",
        "KuerteeUI",
        "PlayerInfoMenuAPI",
        "PlayerInfoMenu",
    }

    for _, name in ipairs(candidates) do
        local api = rawget(_G, name)
        if type(api) == "function" then
            local ok, res = pcall(api)
            if ok and type(res) == "table" and registerWithPlayerInfoAPI(res) then
                return true
            end
        elseif type(api) == "table" then
            if registerWithPlayerInfoAPI(api) then
                return true
            end
        end
    end
    return false
end

-- Expose the auto-register helper so other scripts (or kuertee init) can call it.
exported.tryAutoRegister = tryAutoRegister

-- Attempt immediate auto-registration (safe, wrapped in pcall).
pcall(tryAutoRegister)

-- Expose globally for kuertee or other scripts to pick up
rawset(_G, "GalNetPlayerInfoHook", exported)

return exported

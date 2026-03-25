-- ui/galnet_kuertee_adapter.lua
-- Lightweight adapter that attempts to register GalNet's PlayerInfo hooks
-- with known kuertee UI extension entry points. This is intentionally
-- defensive: it will try a few common function names and tolerate their
-- absence. If nothing is found, `GalNetPlayerInfoHook.tryAutoRegister` can
-- be invoked by kuertee or by a mod initializer later.

local hook = rawget(_G, "GalNetPlayerInfoHook") or require("extensions.galnet.ui.galnet_playerinfo_hook")

local function tryRegisterWithKuertee()
    local candidates = {
        rawget(_G, "kuertee_ui_extensions"),
        rawget(_G, "kuertee"),
        rawget(_G, "KuerteeUI"),
    }

    for _, k in ipairs(candidates) do
        if type(k) == "table" then
            -- Preferred explicit registration API
            if type(k.registerPlayerInfoIntegration) == "function" then
                pcall(k.registerPlayerInfoIntegration, {
                    id = "galnet",
                    injectSidebarEntry = hook.injectGalNetSidebar,
                    handleSidebarSelection = hook.handleSidebarSelection,
                    handleTabSelection = hook.handleTabSelection,
                })
                return true
            end

            -- Fallback: some versions expose an 'api' subtable
            if type(k.api) == "table" and type(k.api.registerSidebar) == "function" then
                pcall(k.api.registerSidebar, hook.injectGalNetSidebar)
                if type(k.api.registerSidebarSelectionHandler) == "function" then
                    pcall(k.api.registerSidebarSelectionHandler, hook.handleSidebarSelection)
                end
                if type(k.api.registerTabClickHandler) == "function" then
                    pcall(k.api.registerTabClickHandler, hook.handleTabSelection)
                end
                return true
            end
        end
    end

    -- Nothing found now; expose helper for delayed/manual registration.
    return false
end

-- Try immediate registration, safely.
pcall(tryRegisterWithKuertee)

-- Expose helper for manual registration attempts by other scripts.
rawset(_G, "GalNetKuerteeAdapter", { tryRegister = tryRegisterWithKuertee })

return { tryRegister = tryRegisterWithKuertee }

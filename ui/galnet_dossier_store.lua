-- ui/galnet_dossier_store.lua
-- Store for Dossier (lore) entries, similar to a journal but for static or semi-static lore cards.

local Dossier = {}
Dossier._items = {}
Dossier._subscribers = {}

-- Add or update a dossier entry. entry = { id, title_id/body_id or title_text/body_text, tags = {"lore"}, date }
function Dossier.add(entry)
    if type(entry) ~= "table" or not entry.id then return false end
    -- Replace if id exists, else insert
    for i, e in ipairs(Dossier._items) do
        if e.id == entry.id then Dossier._items[i] = entry; goto notify end
    end
    table.insert(Dossier._items, entry)
    ::notify::
    for _, cb in ipairs(Dossier._subscribers) do pcall(cb, entry) end
    return true
end

function Dossier.get_all()
    local out = {}
    for i = 1, #Dossier._items do out[#out+1] = Dossier._items[i] end
    return out
end

function Dossier.query(filter)
    filter = filter or {}
    local out = {}
    for _, e in ipairs(Dossier._items) do
        if filter.tag then
            local has = false
            if type(e.tags) == "table" then
                for _, t in ipairs(e.tags) do if t == filter.tag then has = true; break end end
            end
            if not has then goto continue end
        end
        if filter.q and type(filter.q) == "string" then
            local q = filter.q:lower()
            local title = (e.title_text or tostring(e.title_id or ""))
            local body = (e.body_text or tostring(e.body_id or ""))
            if not (string.lower(title):find(q, 1, true) or string.lower(body):find(q, 1, true)) then goto continue end
        end
        out[#out+1] = e
        ::continue::
    end
    return out
end

function Dossier.subscribe(cb)
    if type(cb) ~= "function" then return function() end end
    Dossier._subscribers[#Dossier._subscribers + 1] = cb
    local idx = #Dossier._subscribers
    return function() Dossier._subscribers[idx] = nil end
end

rawset(_G, "GalNetDossierStore", Dossier)

return Dossier
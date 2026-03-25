-- ui/galnet_atlas_store.lua
-- Store for Atlas (encyclopedia/atlas) entries: static or dynamic data cards about places, factions, etc.

local Atlas = {}
Atlas._items = {}
Atlas._subscribers = {}

-- Add or update an atlas entry. entry = { id, title_id/body_id or title_text/body_text, type, tags, data }
function Atlas.add(entry)
    if type(entry) ~= "table" or not entry.id then return false end
    for i, e in ipairs(Atlas._items) do
        if e.id == entry.id then Atlas._items[i] = entry; goto notify end
    end
    table.insert(Atlas._items, entry)
    ::notify::
    for _, cb in ipairs(Atlas._subscribers) do pcall(cb, entry) end
    return true
end

function Atlas.get_all()
    local out = {}
    for i = 1, #Atlas._items do out[#out+1] = Atlas._items[i] end
    return out
end

function Atlas.query(filter)
    filter = filter or {}
    local out = {}
    for _, e in ipairs(Atlas._items) do
        if filter.type and e.type ~= filter.type then goto continue end
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

function Atlas.subscribe(cb)
    if type(cb) ~= "function" then return function() end end
    Atlas._subscribers[#Atlas._subscribers + 1] = cb
    local idx = #Atlas._subscribers
    return function() Atlas._subscribers[idx] = nil end
end

rawset(_G, "GalNetAtlasStore", Atlas)

return Atlas
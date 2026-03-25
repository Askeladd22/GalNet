-- ui/galnet_chronicles_store.lua
-- Store for Cronache (chronicles): timeline events, can be sorted/filtered by date, tag, or type.

local Chronicles = {}
Chronicles._items = {}
Chronicles._subscribers = {}

-- Add or update a chronicle event. entry = { id, title_id/body_id or title_text/body_text, date, tags, type, meta }
function Chronicles.add(entry)
    if type(entry) ~= "table" or not entry.id then return false end
    for i, e in ipairs(Chronicles._items) do
        if e.id == entry.id then Chronicles._items[i] = entry; goto notify end
    end
    table.insert(Chronicles._items, entry)
    ::notify::
    for _, cb in ipairs(Chronicles._subscribers) do pcall(cb, entry) end
    return true
end

function Chronicles.get_all()
    local out = {}
    for i = 1, #Chronicles._items do out[#out+1] = Chronicles._items[i] end
    return out
end

function Chronicles.query(filter)
    filter = filter or {}
    local out = {}
    for _, e in ipairs(Chronicles._items) do
        if filter.type and e.type ~= filter.type then goto continue end
        if filter.tag then
            local has = false
            if type(e.tags) == "table" then
                for _, t in ipairs(e.tags) do if t == filter.tag then has = true; break end end
            end
            if not has then goto continue end
        end
        if filter.since and e.date and e.date < filter.since then goto continue end
        if filter.until_time and e.date and e.date > filter.until_time then goto continue end
        if filter.q and type(filter.q) == "string" then
            local q = filter.q:lower()
            local title = (e.title_text or tostring(e.title_id or ""))
            local body = (e.body_text or tostring(e.body_id or ""))
            if not (string.lower(title):find(q, 1, true) or string.lower(body):find(q, 1, true)) then goto continue end
        end
        out[#out+1] = e
        ::continue::
    end
    -- Sort by date ascending (oldest first)
    table.sort(out, function(a, b) return (a.date or 0) < (b.date or 0) end)
    return out
end

function Chronicles.subscribe(cb)
    if type(cb) ~= "function" then return function() end end
    Chronicles._subscribers[#Chronicles._subscribers + 1] = cb
    local idx = #Chronicles._subscribers
    return function() Chronicles._subscribers[idx] = nil end
end

rawset(_G, "GalNetChroniclesStore", Chronicles)

return Chronicles
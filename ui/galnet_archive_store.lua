-- ui/galnet_archive_store.lua
-- Simple archive store for GalNet: stores historical items with tags and supports basic filtering.

local Archive = {}
Archive._items = {}
Archive._subscribers = {}

-- Add an archive entry. entry = { id, title_id/body_id or title_text/body_text, tags = {"tag1"}, date }
function Archive.add(entry)
    if type(entry) ~= "table" then return false end
    entry.date = entry.date or os.time()
    table.insert(Archive._items, 1, entry)
    for _, cb in ipairs(Archive._subscribers) do
        pcall(cb, entry)
    end
    return true
end

function Archive.get_all()
    local out = {}
    for i = 1, #Archive._items do out[#out+1] = Archive._items[i] end
    return out
end

-- filter = { tag = "economy", q = "station", since = timestamp }
function Archive.query(filter)
    filter = filter or {}
    local out = {}
    for _, e in ipairs(Archive._items) do
        if filter.tag then
            local has = false
            if type(e.tags) == "table" then
                for _, t in ipairs(e.tags) do if t == filter.tag then has = true; break end end
            end
            if not has then goto continue end
        end
        if filter.since and e.date and e.date < filter.since then goto continue end
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

function Archive.subscribe(cb)
    if type(cb) ~= "function" then return function() end end
    Archive._subscribers[#Archive._subscribers + 1] = cb
    local idx = #Archive._subscribers
    return function() Archive._subscribers[idx] = nil end
end

rawset(_G, "GalNetArchiveStore", Archive)

return Archive

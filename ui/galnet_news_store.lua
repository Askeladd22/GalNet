-- ui/galnet_news_store.lua
-- Simple in-memory news store for GalNet.

local NewsStore = {}
NewsStore._items = {} -- newest first
NewsStore._subscribers = {}

-- Persistence helpers (serialize to a Lua file in the extension folder)
local function serialize_value(v)
    if type(v) == "number" then return tostring(v) end
    if type(v) == "boolean" then return v and "true" or "false" end
    if type(v) == "string" then
        return string.format("%q", v)
    end
    if type(v) == "table" then
        local is_array = true
        local maxn = 0
        for k,_ in pairs(v) do
            if type(k) ~= "number" then is_array = false; break end
            if k > maxn then maxn = k end
        end
        local parts = {}
        if is_array then
            for i=1,maxn do parts[#parts+1] = serialize_value(v[i]) end
            return "{" .. table.concat(parts, ",") .. "}"
        else
            for k,val in pairs(v) do
                parts[#parts+1] = "[" .. serialize_value(k) .. "]=" .. serialize_value(val)
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "nil"
end

local function get_data_path()
    -- Try to derive base path from this source file location
    local src = debug.getinfo(1, "S").source or ""
    local base = src:match("@?(.*)[/\\]ui[/\\]galnet_news_store.lua$")
    if not base then base = "" end
    local data_dir = base .. "/data"
    local path = data_dir .. "/galnet_news_store.lua"
    return path, data_dir
end

local function save_to_disk()
    local path, data_dir = get_data_path()
    local ok, err
    -- attempt to create directory (best-effort)
    pcall(function()
        -- try simple mkdir via os.execute; works on many systems
        os.execute("mkdir \"" .. data_dir .. "\"")
    end)
    local f, e = io.open(path, "w")
    if not f then return false, e end
    f:write("return ")
    f:write(serialize_value(NewsStore._items))
    f:close()
    return true
end

local function load_from_disk()
    local path,_ = get_data_path()
    local ok, chunk = pcall(loadfile, path)
    if ok and type(chunk) == "function" then
        local status, tbl = pcall(chunk)
        if status and type(tbl) == "table" then
            NewsStore._items = tbl
        end
    end
end

-- Publish a news entry. Entry is a table with optional fields:
-- id, title_id, body_id, title_text, body_text, date, meta
function NewsStore.publish(entry)
    if type(entry) ~= "table" then return false end
    entry.date = entry.date or os.time()
    table.insert(NewsStore._items, 1, entry)
    -- notify subscribers (pcall to be defensive)
    for _, cb in ipairs(NewsStore._subscribers) do
        pcall(cb, entry)
    end
    -- persist
    pcall(save_to_disk)
    return true
end

function NewsStore.get_latest(n)
    n = tonumber(n) or 10
    local out = {}
    for i = 1, math.min(n, #NewsStore._items) do
        out[#out + 1] = NewsStore._items[i]
    end
    return out
end

function NewsStore.clear()
    NewsStore._items = {}
end

function NewsStore.subscribe(cb)
    if type(cb) ~= "function" then return function() end end
    NewsStore._subscribers[#NewsStore._subscribers + 1] = cb
    local idx = #NewsStore._subscribers
    return function()
        NewsStore._subscribers[idx] = nil
    end
end

-- Helper publish function that accepts localized IDs or raw strings.
function NewsStore.publish_localized(id, title_id, body_id, meta)
    return NewsStore.publish({ id = id, title_id = title_id, body_id = body_id, meta = meta })
end

-- Expose globally for MD scripts or other mods to call directly.
rawset(_G, "GalNetNewsStore", NewsStore)

-- Convenience global to be callable from MD or other scripts: GalNetPublish(id, title_id, body_id, meta)
rawset(_G, "GalNetPublish", function(id, title_id, body_id, meta)
    return NewsStore.publish_localized(id, title_id, body_id, meta)
end)

-- Load persisted items on startup (best-effort)
pcall(load_from_disk)

return NewsStore

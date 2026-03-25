-- ui/galnet_chronicles_renderer.lua
-- Renderer for Cronache: timeline events, sorted by date, with optional filters

local Chronicles = rawget(_G, "GalNetChroniclesStore") or require("extensions.galnet.ui.galnet_chronicles_store")
local Data = rawget(_G, "GalNetUIData") or require("extensions.galnet.ui.galnet_data")

local function text(id, fallback)
    if type(Data.text) == "function" then
        return Data.text(id, fallback)
    end
    if type(ReadText) == "function" then
        local ok, value = pcall(ReadText, 9950, id)
        if ok and type(value) == "string" and value ~= "" and not value:match("^ReadText") then
            return value
        end
    end
    return fallback or (tostring(id) or "")
end

local ChroniclesRenderer = {}

function ChroniclesRenderer.render(filter)
    local items = Chronicles.query(filter)
    local sections = {}
    for _, e in ipairs(items) do
        sections[#sections + 1] = {
            kind = "chronicle_event",
            id = e.id,
            title = e.title_text or (e.title_id and text(e.title_id)) or e.title or "(untitled)",
            body = e.body_text or (e.body_id and text(e.body_id)) or e.body or "",
            date = e.date,
            tags = e.tags,
            type = e.type,
            meta = e.meta,
        }
    end
    return sections
end

return ChroniclesRenderer
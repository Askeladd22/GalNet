-- ui/galnet_archive_renderer.lua
-- Renderer for archive entries with simple filtering UI model

local Archive = rawget(_G, "GalNetArchiveStore") or require("extensions.galnet.ui.galnet_archive_store")
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

local ArchiveRenderer = {}

function ArchiveRenderer.render(filter)
    local items = Archive.query(filter)
    local sections = {}
    for _, e in ipairs(items) do
        sections[#sections + 1] = {
            kind = "archive_item",
            id = e.id,
            title = e.title_text or (e.title_id and text(e.title_id)) or e.title or "(untitled)",
            body = e.body_text or (e.body_id and text(e.body_id)) or e.body or "",
            date = e.date and os.date("%Y-%m-%d", e.date) or "",
            tags = e.tags,
        }
    end
    return sections
end

return ArchiveRenderer

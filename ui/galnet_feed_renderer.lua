-- ui/galnet_feed_renderer.lua
-- Renderer helper that converts news store entries into renderable blocks

local NewsStore = rawget(_G, "GalNetNewsStore") or require("extensions.galnet.ui.galnet_news_store")
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

local FeedRenderer = {}

function FeedRenderer.render_sections(count)
    local items = NewsStore.get_latest(count or 10)
    local sections = {}
    for _, entry in ipairs(items) do
        local title = entry.title_text or (entry.title_id and text(entry.title_id)) or entry.title or "(no title)"
        local body = entry.body_text or (entry.body_id and text(entry.body_id)) or entry.body or ""
        local date = entry.date and os.date("%Y-%m-%d %H:%M", entry.date) or ""
        sections[#sections + 1] = {
            kind = "news_card",
            id = entry.id,
            title = title,
            body = body,
            date = date,
            meta = entry.meta,
        }
    end
    return sections
end

return FeedRenderer

    -- Chronicles tab: use ChroniclesRenderer if present
    if selectedTab and selectedTab.key == "chronicles" then
      local ChroniclesRenderer = rawget(_G, "GalNetChroniclesRenderer")
      if not ChroniclesRenderer then
        local ok, mod = pcall(require, "extensions.galnet.ui.galnet_chronicles_renderer")
        if ok and type(mod) == "table" then ChroniclesRenderer = mod end
      end
      if ChroniclesRenderer and type(ChroniclesRenderer.render) == "function" then
        content.sections = ChroniclesRenderer.render()
      end
    end
  -- Atlas tab: use AtlasRenderer if present
  if selectedTab and selectedTab.key == "atlas" then
    local AtlasRenderer = rawget(_G, "GalNetAtlasRenderer")
    if not AtlasRenderer then
      local ok, mod = pcall(require, "extensions.galnet.ui.galnet_atlas_renderer")
      if ok and type(mod) == "table" then AtlasRenderer = mod end
    end
    if AtlasRenderer and type(AtlasRenderer.render) == "function" then
      content.sections = AtlasRenderer.render()
    end
  end
-- ui/menu_playerinfo_galnet.lua
-- GalNet 2.0: Player Information panel scaffold.
--
-- Important:
-- 1) This file gives you the state model and the panel/tab logic.
-- 2) The ONLY part you still need to adapt to your local kuertee UI Extensions build
--    is the concrete callback/hook registration against PlayerInfoMenu.
-- 3) I am intentionally not inventing exact UIX callback names that I cannot verify
--    from your installed version.

GalNetPlayerInfoMenu = GalNetPlayerInfoMenu or {}

local menu = {
  id = "galnet",
  name = "GalNetPlayerInfoMenu",
  selectedTabID = "feed",
  isOpen = false,
  sidebarIcon = "encyclopedia", -- TODO: replace with the exact icon token you want to use in Player Information.
}

local Data = rawget(_G, "GalNetUIData") or {}

-- Try to locate the NewsStore and FeedRenderer if available
local NewsStore = rawget(_G, "GalNetNewsStore")
if not NewsStore then
  local ok, mod = pcall(require, "extensions.galnet.ui.galnet_news_store")
  if ok and type(mod) == "table" then NewsStore = mod end
end

local FeedRenderer = rawget(_G, "GalNetFeedRenderer")
if not FeedRenderer then
  local ok2, mod2 = pcall(require, "extensions.galnet.ui.galnet_feed_renderer")
  if ok2 and type(mod2) == "table" then FeedRenderer = mod2 end
end

local function clampSelectedTab(tabid)
  if type(Data.getTab) == "function" and Data.getTab(tabid) then
    return tabid
  end
  return "feed"
end

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
  return fallback or ("ReadText9950-" .. tostring(id))
end

function menu.getSidebarEntryDescriptor()
  return {
    id = menu.id,
    text = text(7300, "GalNet"),
    icon = menu.sidebarIcon,
    mouseover = text(7309, "Voce dedicata nella colonna laterale di Informazioni Giocatore."),
  }
end

function menu.open(optionalTabID)
  menu.isOpen = true
  menu.selectedTabID = clampSelectedTab(optionalTabID or menu.selectedTabID)
end

function menu.close()
  menu.isOpen = false
end

function menu.setTab(tabid)
  menu.selectedTabID = clampSelectedTab(tabid)
end


function menu.getViewModel()
  -- Build the tab list for the horizontal tab bar
  local tabs = {}
  for _, tab in ipairs(Data.tabs or {}) do
    table.insert(tabs, {
      key = tab.key,
      label = text(tab.label, tab.key),
      summary = text(tab.summary, ""),
      strap = text(tab.strap, ""),
    })
  end

  -- Find the selected tab's content
  local selectedTab = Data.get_tab and Data.get_tab(menu.selectedTabID) or (Data.tabs and Data.tabs[1])
  local content = {
    title = selectedTab and text(selectedTab.label, selectedTab.key) or "",
    body = selectedTab and text(selectedTab.summary, "") or "",
    sections = {},
  }

  -- If the Feed tab is selected and a NewsStore/FeedRenderer is available,
  -- populate sections from live news items instead of the static blocks.
  if selectedTab and selectedTab.key == "feed" then
    if FeedRenderer and type(FeedRenderer.render_sections) == "function" then
      content.sections = FeedRenderer.render_sections(10)
    elseif NewsStore and type(NewsStore.get_latest) == "function" then
      local items = NewsStore.get_latest(10)
      for _, entry in ipairs(items) do
        table.insert(content.sections, {
          title = entry.title_text or (entry.title_id and text(entry.title_id)) or entry.title or "",
          body = entry.body_text or (entry.body_id and text(entry.body_id)) or entry.body or "",
        })
      end
    else
      -- Fallback to configured static blocks
      if selectedTab and selectedTab.blocks then
        for _, block in ipairs(selectedTab.blocks) do
          table.insert(content.sections, {
            title = text(block.title, ""),
            body = text(block.body, ""),
          })
        end
      end
    end
  else
    if selectedTab and selectedTab.blocks then
      for _, block in ipairs(selectedTab.blocks) do
        table.insert(content.sections, {
          title = text(block.title, ""),
          body = text(block.body, ""),
        })
      end
    end
  end
  
  -- Archive tab: use ArchiveRenderer if present
  if selectedTab and selectedTab.key == "archive" then
    local ArchiveRenderer = rawget(_G, "GalNetArchiveRenderer")
    if not ArchiveRenderer then
      local ok, mod = pcall(require, "extensions.galnet.ui.galnet_archive_renderer")
      if ok and type(mod) == "table" then ArchiveRenderer = mod end
    end
    if ArchiveRenderer and type(ArchiveRenderer.render) == "function" then
      content.sections = ArchiveRenderer.render()
    end
  end

  -- Dossier tab: use DossierRenderer if present
  if selectedTab and selectedTab.key == "dossier" then
    local DossierRenderer = rawget(_G, "GalNetDossierRenderer")
    if not DossierRenderer then
      local ok, mod = pcall(require, "extensions.galnet.ui.galnet_dossier_renderer")
      if ok and type(mod) == "table" then DossierRenderer = mod end
    end
    if DossierRenderer and type(DossierRenderer.render) == "function" then
      content.sections = DossierRenderer.render()
    end
  end

  return {
    paneltitle = text(Data.title, "GalNet 2.0"),
    panelsubtitle = text(Data.subtitle, "Console editoriale unificata"),
    panelbody = text(Data.overview, "Primo scheletro UI di GalNet 2.0."),
    selectedtab = menu.selectedTabID,
    tabs = tabs,
    content = content,
    status = {
      title = text(Data.status_title, "Stato attuale"),
      body = text(Data.status_body, "MVP UI attivo in Informazioni Giocatore."),
    },
    ticker = {},
  }
end

-- ============================================================================
-- Adapter surface: these functions are the ones you should call from your hook
-- into PlayerInfoMenu.
-- ============================================================================

-- Call this while building the left sidebar entries for Player Information.
function menu.injectSidebarEntry(entryList)
  if type(entryList) ~= "table" then
    return entryList
  end

  local alreadyPresent = false
  for _, entry in ipairs(entryList) do
    if entry.id == menu.id then
      alreadyPresent = true
      break
    end
  end

  if not alreadyPresent then
    entryList[#entryList + 1] = menu.getSidebarEntryDescriptor()
  end

  return entryList
end

-- Call this when the user changes the selected section in Player Information.
-- Return true if GalNet is now the active section.
function menu.handleSidebarSelection(sectionID)
  if sectionID == menu.id then
    menu.open(menu.selectedTabID)
    return true
  end

  if menu.isOpen then
    menu.close()
  end
  return false
end

-- Call this from your UI code when a GalNet tab button is clicked.
function menu.handleTabSelection(tabID)
  menu.setTab(tabID)
  return menu.getViewModel()
end

-- Build a renderer-friendly block list.
-- Your actual PlayerInfo renderer can consume this to build rows/frames/widgets.
function menu.buildRenderBlocks()
  local vm = menu.getViewModel()
  local blocks = {}

  blocks[#blocks + 1] = {
    kind = "header",
    title = vm.paneltitle,
    subtitle = vm.panelsubtitle,
    body = vm.panelbody,
  }

  blocks[#blocks + 1] = {
    kind = "tabs",
    tabs = vm.tabs,
    selected = vm.selectedtab,
  }

  blocks[#blocks + 1] = {
    kind = "main",
    title = vm.content.title,
    body = vm.content.body,
    sections = vm.content.sections,
  }

  blocks[#blocks + 1] = {
    kind = "status",
    title = vm.status.title,
    body = vm.status.body,
  }

  blocks[#blocks + 1] = {
    kind = "ticker",
    lines = vm.ticker,
  }

  return blocks
end

-- ============================================================================
-- Rendering example (pseudo-real, but UI-library-agnostic)
-- ============================================================================
-- The idea is:
--   1) Create a header frame with vm.paneltitle / panelsubtitle.
--   2) Draw a horizontal row of 5 tab buttons from vm.tabs.
--   3) Draw the active tab body in the main content region.
--   4) Draw a small footer/status region using vm.status and vm.ticker.
--
-- In your concrete PlayerInfo hook, the flow usually looks like this:
--
--   local entries = menu.injectSidebarEntry(existingEntries)
--   if menu.handleSidebarSelection(currentSectionID) then
--       local blocks = menu.buildRenderBlocks()
--       -- render blocks into the main right-side Player Information pane
--   end
--
-- The two stable parts are the state machine and the view model.
-- The unstable part is only the exact UIX hook/callback name.

for key, value in pairs(menu) do
  GalNetPlayerInfoMenu[key] = value
end

return GalNetPlayerInfoMenu

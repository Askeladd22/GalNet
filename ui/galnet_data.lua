-- ui/galnet_data.lua
-- GalNet 2.0: data-only scaffold for the Player Information UI panel.
-- This file is intentionally UI-agnostic: it only prepares tabs, copy blocks,
-- and small placeholder datasets that the menu renderer can consume.

GalNetUIData = GalNetUIData or {}

GalNetUIData.mode = "galnet"
GalNetUIData.icon = "logbook_news"
GalNetUIData.default_tab = "feed"

GalNetUIData.sidebar_label = 7300
GalNetUIData.sidebar_help = 7309
GalNetUIData.title = 7306
GalNetUIData.subtitle = 7307
GalNetUIData.overview = 7308
GalNetUIData.status_title = 7350
GalNetUIData.status_body = 7351

GalNetUIData.tabs = {
	{
		key = "feed",
		label = 7301,
		strap = 7310,
		summary = 7311,
		blocks = {
			{ title = 7312, body = 7313 },
			{ title = 7314, body = 7315 },
			{ title = 7316, body = 7317 },
		},
	},
	{
		key = "archive",
		label = 7302,
		strap = 7318,
		summary = 7319,
		blocks = {
			{ title = 7320, body = 7321 },
			{ title = 7322, body = 7323 },
			{ title = 7324, body = 7325 },
		},
	},
	{
		key = "dossier",
		label = 7303,
		strap = 7326,
		summary = 7327,
		blocks = {
			{ title = 7328, body = 7329 },
			{ title = 7330, body = 7331 },
			{ title = 7332, body = 7333 },
		},
	},
	{
		key = "atlas",
		label = 7304,
		strap = 7334,
		summary = 7335,
		blocks = {
			{ title = 7336, body = 7337 },
			{ title = 7338, body = 7339 },
			{ title = 7340, body = 7341 },
		},
	},
	{
		key = "chronicles",
		label = 7305,
		strap = 7342,
		summary = 7343,
		blocks = {
			{ title = 7344, body = 7345 },
			{ title = 7346, body = 7347 },
			{ title = 7348, body = 7349 },
		},
	},
}

function GalNetUIData.get_tab(key)
	for _, tab in ipairs(GalNetUIData.tabs) do
		if tab.key == key then
			return tab
		end
	end
	return GalNetUIData.tabs[1]
end


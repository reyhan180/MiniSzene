-- Responsive Layout-Berechnung für Shop, Seitenleiste (Shop-Button + Inventar) und Statusleiste.
-- Reine Funktion: bekommt die nutzbare Bildschirmgröße (ScreenGui.AbsoluteSize, also ohne Topbar)
-- und liefert Größen/Positionen in Pixeln. Dadurch ist das Layout ohne Gerät testbar.
--
-- Regeln:
--   * "compact" bei kleinen Bildschirmen (Smartphone quer): Höhe < 500 oder Breite < 900.
--   * Seitenleiste rechts. Compact: oben rechts (frei von Sprung-Button und Thumbstick),
--     sonst rechts mittig (frei vom Chat oben links).
--   * Shop-Fenster: Desktop mittig, compact links. Überlappt nie die Seitenleiste,
--     passt immer in die Höhe (Item-Liste scrollt).
--   * Buttons mindestens TOUCH_TARGET (44 px) hoch.

local UITheme = require(script.Parent:WaitForChild("UITheme"))

local UILayout = {}

UILayout.MARGIN = 16
UILayout.COMPACT_MAX_HEIGHT = 500
UILayout.COMPACT_MAX_WIDTH = 900
-- Freiraum unten rechts für den mobilen Sprung-Button
UILayout.JUMP_BUTTON_CLEARANCE = 110

UILayout.SIDE_WIDTH = 170
UILayout.SIDE_GAP = 8
UILayout.INVENTORY_HEADER_HEIGHT = 36
UILayout.INVENTORY_ROW_HEIGHT = 22

UILayout.SHOP_MAX_WIDTH = 380
UILayout.SHOP_PADDING = 14
UILayout.SHOP_HEADER_HEIGHT = 60
UILayout.SHOP_STATUS_HEIGHT = 24
UILayout.ROW_HEIGHT = 56
UILayout.ROW_GAP = 6
UILayout.BUY_BUTTON_WIDTH = 100
UILayout.BUY_BUTTON_HEIGHT = UITheme.TOUCH_TARGET

export type Rect = { position: Vector2, size: Vector2 }

export type Layout = {
	compact: boolean,
	screen: Vector2,
	side: Rect, -- komplette Seitenleiste (Shop-Button + Inventar, ausgeklappt)
	shopButtonHeight: number,
	shop: Rect,
	shopListHeight: number,
	inventoryCollapsedByDefault: boolean,
	statusTitleSize: number,
	statusDetailSize: number,
}

function UILayout.isCompact(screen: Vector2): boolean
	return screen.Y < UILayout.COMPACT_MAX_HEIGHT or screen.X < UILayout.COMPACT_MAX_WIDTH
end

function UILayout.sideHeight(itemRows: number, collapsed: boolean): number
	local inventory = UILayout.INVENTORY_HEADER_HEIGHT
	if not collapsed then
		inventory += math.max(itemRows, 1) * UILayout.INVENTORY_ROW_HEIGHT + 8
	end
	return UITheme.TOUCH_TARGET + UILayout.SIDE_GAP + inventory
end

-- screen: nutzbare Größe in Pixeln, itemCount: Anzahl Shop-Items
function UILayout.compute(screen: Vector2, itemCount: number): Layout
	local margin = UILayout.MARGIN
	local compact = UILayout.isCompact(screen)

	-- Seitenleiste (Größe für ausgeklapptes Inventar mit allen Items)
	local sideSize = Vector2.new(UILayout.SIDE_WIDTH, UILayout.sideHeight(itemCount, false))
	local sidePosition
	if compact then
		sidePosition = Vector2.new(screen.X - margin - sideSize.X, margin)
	else
		sidePosition = Vector2.new(screen.X - margin - sideSize.X, (screen.Y - sideSize.Y) / 2)
	end

	-- Shop-Fenster
	local listHeight = itemCount * UILayout.ROW_HEIGHT + math.max(itemCount - 1, 0) * UILayout.ROW_GAP
	local chrome = UILayout.SHOP_HEADER_HEIGHT + UILayout.SHOP_STATUS_HEIGHT + 2 * UILayout.SHOP_PADDING
	local maxWidth = sidePosition.X - 2 * margin -- Platz links neben der Seitenleiste
	local width = math.min(UILayout.SHOP_MAX_WIDTH, maxWidth)
	local height = math.min(chrome + listHeight, screen.Y - 2 * margin)
	local shopPosition
	if compact then
		shopPosition = Vector2.new(margin, (screen.Y - height) / 2)
	else
		local centeredX = (screen.X - width) / 2
		shopPosition = Vector2.new(math.min(centeredX, sidePosition.X - margin - width), (screen.Y - height) / 2)
	end

	return {
		compact = compact,
		screen = screen,
		side = { position = sidePosition, size = sideSize },
		shopButtonHeight = UITheme.TOUCH_TARGET,
		shop = { position = shopPosition, size = Vector2.new(width, height) },
		shopListHeight = height - chrome,
		inventoryCollapsedByDefault = compact,
		statusTitleSize = if compact then UITheme.TEXT_SIZE.Heading else UITheme.TEXT_SIZE.Title,
		statusDetailSize = if compact then UITheme.TEXT_SIZE.Small else UITheme.TEXT_SIZE.Body,
	}
end

return UILayout

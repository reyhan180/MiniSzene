-- Shop- und Inventar-UI (Client).
-- Baut die ScreenGui "ShopGui" per Code auf:
--   * Seitenleiste rechts: "Shop"-Button + einklappbares Inventar (liest player.Inventory)
--   * Shop-Fenster mit scrollbarer Item-Liste aus ShopConfig und je einem "Kaufen"-Button
-- Größen/Positionen kommen aus UILayout (responsive, Smartphone quer bis Desktop).
-- Der Shop öffnet sich außerdem über den Einkaufen-Prompt am Tresen und bleibt während der Runde nutzbar.
-- Kauf: BuyItem:FireServer(itemId). Die Antwort des Servers wird als Statuszeile angezeigt.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local UITheme = require(ReplicatedStorage:WaitForChild("UITheme"))
local UILayout = require(ReplicatedStorage:WaitForChild("UILayout"))
local buyItem = ReplicatedStorage:WaitForChild(ShopConfig.BUY_ITEM_EVENT) :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COLORS = UITheme.COLORS
local FONTS = UITheme.FONTS
local TEXT_SIZE = UITheme.TEXT_SIZE
local PROMPT_TAG = "GasStationPrompt"
local STATUS_SECONDS = 3

local function getCoins(): number
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	return if coins then (coins :: IntValue).Value else 0
end

-- Items nach Preis sortiert, damit die Reihenfolge stabil ist.
local sortedItemIds = {}
for itemId in ShopConfig.ITEMS do
	table.insert(sortedItemIds, itemId)
end
table.sort(sortedItemIds, function(a, b)
	return ShopConfig.ITEMS[a].price < ShopConfig.ITEMS[b].price
end)

-- ===== Aufbau der ScreenGui =====

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- --- Seitenleiste: Shop-Button + Inventar ---
local sidePanel = Instance.new("Frame")
sidePanel.Name = "SidePanel"
sidePanel.BackgroundTransparency = 1
sidePanel.AutomaticSize = Enum.AutomaticSize.Y
sidePanel.Parent = screenGui

local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, UILayout.SIDE_GAP)
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Parent = sidePanel

local shopButton = UITheme.makeButton("ShopButton", "Shop", COLORS.Buy, sidePanel)
shopButton.LayoutOrder = 1
shopButton.Size = UDim2.new(1, 0, 0, UITheme.TOUCH_TARGET)
shopButton.TextSize = TEXT_SIZE.Heading

local inventoryPanel = UITheme.makePanel("InventoryPanel", sidePanel)
inventoryPanel.LayoutOrder = 2
inventoryPanel.Size = UDim2.fromScale(1, 0)
inventoryPanel.AutomaticSize = Enum.AutomaticSize.Y

local inventoryPadding = Instance.new("UIPadding")
inventoryPadding.PaddingLeft = UDim.new(0, 10)
inventoryPadding.PaddingRight = UDim.new(0, 10)
inventoryPadding.PaddingBottom = UDim.new(0, 6)
inventoryPadding.Parent = inventoryPanel

local inventoryLayout = Instance.new("UIListLayout")
inventoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
inventoryLayout.Parent = inventoryPanel

local inventoryHeader = Instance.new("TextButton")
inventoryHeader.Name = "Header"
inventoryHeader.LayoutOrder = 0
inventoryHeader.Size = UDim2.new(1, 0, 0, UILayout.INVENTORY_HEADER_HEIGHT)
inventoryHeader.BackgroundTransparency = 1
inventoryHeader.Font = FONTS.Bold
inventoryHeader.TextSize = TEXT_SIZE.Heading
inventoryHeader.TextColor3 = COLORS.Text
inventoryHeader.TextXAlignment = Enum.TextXAlignment.Left
inventoryHeader.Text = "Inventar"
inventoryHeader.Parent = inventoryPanel

local emptyLabel = UITheme.makeLabel("EmptyLabel", "leer", TEXT_SIZE.Small, inventoryPanel)
emptyLabel.LayoutOrder = 1
emptyLabel.Size = UDim2.new(1, 0, 0, UILayout.INVENTORY_ROW_HEIGHT)
emptyLabel.TextColor3 = COLORS.Muted

local inventoryRows: { [string]: TextLabel } = {}
for index, itemId in sortedItemIds do
	local row = UITheme.makeLabel(itemId, "", TEXT_SIZE.Small, inventoryPanel)
	row.LayoutOrder = index + 1
	row.Size = UDim2.new(1, 0, 0, UILayout.INVENTORY_ROW_HEIGHT)
	row.Visible = false
	inventoryRows[itemId] = row
end

-- --- Shop-Fenster ---
local shopFrame = UITheme.makePanel("ShopFrame", screenGui)
shopFrame.BackgroundTransparency = 0
shopFrame.Visible = false
UITheme.addPadding(shopFrame, UILayout.SHOP_PADDING)

local title = UITheme.makeLabel("Title", "NORDSTERN Shop", TEXT_SIZE.Title, shopFrame)
title.Font = FONTS.Bold
title.Size = UDim2.new(1, -(UITheme.TOUCH_TARGET + 8), 0, 28)

local closeButton = UITheme.makeButton("CloseButton", "X", COLORS.Row, shopFrame)
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.fromScale(1, 0)
closeButton.Size = UDim2.fromOffset(UITheme.TOUCH_TARGET, UITheme.TOUCH_TARGET)

local coinsLabel = UITheme.makeLabel("CoinsLabel", "Coins: 0", TEXT_SIZE.Body, shopFrame)
coinsLabel.Position = UDim2.fromOffset(0, 32)
coinsLabel.Size = UDim2.new(1, -(UITheme.TOUCH_TARGET + 8), 0, 20)
coinsLabel.TextColor3 = COLORS.Muted

local itemList = Instance.new("ScrollingFrame")
itemList.Name = "ItemList"
itemList.BackgroundTransparency = 1
itemList.BorderSizePixel = 0
itemList.Position = UDim2.fromOffset(0, UILayout.SHOP_HEADER_HEIGHT)
itemList.CanvasSize = UDim2.new()
itemList.AutomaticCanvasSize = Enum.AutomaticSize.Y
itemList.ScrollingDirection = Enum.ScrollingDirection.Y
itemList.ScrollBarThickness = 6
itemList.ScrollBarImageColor3 = COLORS.Muted
itemList.Parent = shopFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, UILayout.ROW_GAP)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = itemList

local statusLabel = UITheme.makeLabel("StatusLabel", "", TEXT_SIZE.Small, shopFrame)
statusLabel.AnchorPoint = Vector2.new(0, 1)
statusLabel.Position = UDim2.fromScale(0, 1)
statusLabel.Size = UDim2.new(1, 0, 0, UILayout.SHOP_STATUS_HEIGHT)

local buyButtons: { [string]: TextButton } = {}

for index, itemId in sortedItemIds do
	local item = ShopConfig.ITEMS[itemId]

	local row = Instance.new("Frame")
	row.Name = itemId
	row.LayoutOrder = index
	row.Size = UDim2.new(1, -10, 0, UILayout.ROW_HEIGHT) -- Platz für die Scrollbar
	row.BackgroundColor3 = COLORS.Row
	row.BorderSizePixel = 0
	UITheme.addCorner(row, UITheme.CORNER.Medium)
	UITheme.addPadding(row, (UILayout.ROW_HEIGHT - UILayout.BUY_BUTTON_HEIGHT) / 2)
	row.Parent = itemList

	local nameLabel = UITheme.makeLabel("NameLabel", item.displayName, TEXT_SIZE.Body, row)
	nameLabel.Size = UDim2.new(1, -(UILayout.BUY_BUTTON_WIDTH + 8), 0.5, 0)
	local priceLabel = UITheme.makeLabel("PriceLabel", `{item.price} Coins`, TEXT_SIZE.Small, row)
	priceLabel.Position = UDim2.fromScale(0, 0.5)
	priceLabel.Size = UDim2.new(1, -(UILayout.BUY_BUTTON_WIDTH + 8), 0.5, 0)
	priceLabel.TextColor3 = COLORS.Muted

	local buyButton = UITheme.makeButton("BuyButton", "Kaufen", COLORS.Buy, row)
	buyButton.AnchorPoint = Vector2.new(1, 0.5)
	buyButton.Position = UDim2.fromScale(1, 0.5)
	buyButton.Size = UDim2.fromOffset(UILayout.BUY_BUTTON_WIDTH, UILayout.BUY_BUTTON_HEIGHT)
	buyButton.Activated:Connect(function()
		buyItem:FireServer(itemId)
	end)
	buyButtons[itemId] = buyButton
end

screenGui.Parent = playerGui

-- ===== Layout =====

local inventoryCollapsed = false
local lastCompact: boolean? = nil

local refreshInventory: () -> ()

local function applyLayout()
	local layout = UILayout.compute(screenGui.AbsoluteSize, #sortedItemIds)

	sidePanel.Position = UDim2.fromOffset(layout.side.position.X, layout.side.position.Y)
	sidePanel.Size = UDim2.fromOffset(layout.side.size.X, 0)

	shopFrame.Position = UDim2.fromOffset(layout.shop.position.X, layout.shop.position.Y)
	shopFrame.Size = UDim2.fromOffset(layout.shop.size.X, layout.shop.size.Y)
	itemList.Size = UDim2.new(1, 0, 0, layout.shopListHeight)

	-- Beim Wechsel zwischen kompakt/normal den Standard für das Inventar übernehmen
	if layout.compact ~= lastCompact then
		lastCompact = layout.compact
		inventoryCollapsed = layout.inventoryCollapsedByDefault
		refreshInventory()
	end
end

-- ===== Logik =====

local function refreshShop()
	local coins = getCoins()
	coinsLabel.Text = `Coins: {coins}`
	for itemId, button in buyButtons do
		local affordable = coins >= ShopConfig.ITEMS[itemId].price
		button.BackgroundColor3 = if affordable then COLORS.Buy else COLORS.Disabled
	end
end

function refreshInventory()
	local inventory = player:FindFirstChild("Inventory")
	local total = 0
	for itemId, row in inventoryRows do
		local value = inventory and inventory:FindFirstChild(itemId)
		local count = if value then (value :: IntValue).Value else 0
		total += count
		row.Visible = count > 0 and not inventoryCollapsed
		row.Text = `{ShopConfig.ITEMS[itemId].displayName}  x{count}`
	end
	emptyLabel.Visible = total == 0 and not inventoryCollapsed
	-- "+"/"–" statt Pfeil-Symbolen: die Gotham-Schrift hat keine Pfeil-Glyphen
	local marker = if inventoryCollapsed then "+" else "–"
	inventoryHeader.Text = `{marker} Inventar ({total})`
end

local function setShopOpen(open: boolean)
	shopFrame.Visible = open
	if open then
		refreshShop()
	end
end

shopButton.Activated:Connect(function()
	setShopOpen(not shopFrame.Visible)
end)
closeButton.Activated:Connect(function()
	setShopOpen(false)
end)
inventoryHeader.Activated:Connect(function()
	inventoryCollapsed = not inventoryCollapsed
	refreshInventory()
end)

local statusToken = 0
buyItem.OnClientEvent:Connect(function(success: boolean, _itemId: string?, message: string)
	statusToken += 1
	local token = statusToken
	statusLabel.Text = message
	statusLabel.TextColor3 = if success then COLORS.Success else COLORS.Error
	refreshShop()
	task.delay(STATUS_SECONDS, function()
		if token == statusToken then
			statusLabel.Text = ""
		end
	end)
end)

screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyLayout)
applyLayout()
refreshInventory()

-- Coins beobachten (leaderstats kommt erst nach dem Laden der Daten)
task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats")
	local coins = leaderstats:WaitForChild("Coins") :: IntValue
	coins.Changed:Connect(refreshShop)
	refreshShop()
end)

-- Inventar beobachten
task.spawn(function()
	local inventory = player:WaitForChild("Inventory")
	local function watch(child: Instance)
		if child:IsA("IntValue") then
			child.Changed:Connect(refreshInventory)
		end
		refreshInventory()
	end
	for _, child in inventory:GetChildren() do
		watch(child)
	end
	inventory.ChildAdded:Connect(watch)
	inventory.ChildRemoved:Connect(refreshInventory)
	refreshInventory()
end)

-- Einkaufen-Prompt am Tresen öffnet den Shop
local function bindPrompt(prompt: Instance)
	if prompt:IsA("ProximityPrompt") and prompt:GetAttribute("Interaction") == "Einkaufen" then
		prompt.Triggered:Connect(function()
			setShopOpen(true)
		end)
	end
end
for _, prompt in CollectionService:GetTagged(PROMPT_TAG) do
	bindPrompt(prompt)
end
CollectionService:GetInstanceAddedSignal(PROMPT_TAG):Connect(bindPrompt)

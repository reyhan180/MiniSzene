-- Shop- und Inventar-UI (Client).
-- Baut die ScreenGui "ShopGui" per Code auf:
--   * Button "Shop" unten links zum Öffnen/Schließen
--   * Shop-Fenster mit allen Items aus ShopConfig und je einem "Kaufen"-Button
--   * Inventar-Anzeige rechts (liest player.Inventory, wird vom Server gefüllt)
-- Der Shop öffnet sich außerdem über den Einkaufen-Prompt am Tresen.
-- Kauf: BuyItem:FireServer(itemId). Die Antwort des Servers wird als Statuszeile angezeigt.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local buyItem = ReplicatedStorage:WaitForChild(ShopConfig.BUY_ITEM_EVENT) :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PROMPT_TAG = "GasStationPrompt"
local STATUS_SECONDS = 3

local COLOR_PANEL = Color3.fromRGB(30, 34, 42)
local COLOR_ROW = Color3.fromRGB(45, 50, 60)
local COLOR_TEXT = Color3.fromRGB(240, 240, 240)
local COLOR_MUTED = Color3.fromRGB(160, 165, 175)
local COLOR_BUY = Color3.fromRGB(60, 170, 90)
local COLOR_DISABLED = Color3.fromRGB(90, 95, 105)
local COLOR_SUCCESS = Color3.fromRGB(90, 220, 120)
local COLOR_ERROR = Color3.fromRGB(235, 90, 80)

-- ===== Hilfsfunktionen =====

local function addCorner(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function addPadding(parent: Instance, pixels: number)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, pixels)
	padding.PaddingBottom = UDim.new(0, pixels)
	padding.PaddingLeft = UDim.new(0, pixels)
	padding.PaddingRight = UDim.new(0, pixels)
	padding.Parent = parent
end

local function makeLabel(name: string, text: string, size: UDim2, parent: Instance): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Size = size
	label.BackgroundTransparency = 1
	label.TextColor3 = COLOR_TEXT
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function makeButton(name: string, text: string, size: UDim2, color: Color3, parent: Instance): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Size = size
	button.BackgroundColor3 = color
	button.TextColor3 = COLOR_TEXT
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.AutoButtonColor = true
	addCorner(button, 6)
	button.Parent = parent
	return button
end

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

-- Toggle-Button
local toggleButton = makeButton("ShopButton", "Shop", UDim2.fromOffset(110, 44), COLOR_BUY, screenGui)
toggleButton.AnchorPoint = Vector2.new(0, 1)
toggleButton.Position = UDim2.new(0, 16, 1, -16)

-- Shop-Fenster
local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
shopFrame.Position = UDim2.fromScale(0.5, 0.5)
shopFrame.Size = UDim2.fromOffset(360, 110 + #sortedItemIds * 56)
shopFrame.BackgroundColor3 = COLOR_PANEL
shopFrame.Visible = false
addCorner(shopFrame, 10)
addPadding(shopFrame, 14)
shopFrame.Parent = screenGui

local title = makeLabel("Title", "NORDSTERN Shop", UDim2.new(1, -40, 0, 28), shopFrame)
title.Font = Enum.Font.GothamBold
title.TextSize = 22

local closeButton = makeButton("CloseButton", "X", UDim2.fromOffset(28, 28), COLOR_ROW, shopFrame)
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.fromScale(1, 0)

local coinsLabel = makeLabel("CoinsLabel", "Coins: 0", UDim2.new(1, 0, 0, 20), shopFrame)
coinsLabel.Position = UDim2.fromOffset(0, 32)
coinsLabel.TextColor3 = COLOR_MUTED

local itemList = Instance.new("Frame")
itemList.Name = "ItemList"
itemList.BackgroundTransparency = 1
itemList.Position = UDim2.fromOffset(0, 60)
itemList.Size = UDim2.new(1, 0, 0, #sortedItemIds * 56)
itemList.Parent = shopFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = itemList

local statusLabel = makeLabel("StatusLabel", "", UDim2.new(1, 0, 0, 20), shopFrame)
statusLabel.AnchorPoint = Vector2.new(0, 1)
statusLabel.Position = UDim2.fromScale(0, 1)
statusLabel.TextSize = 14

local buyButtons: { [string]: TextButton } = {}

for index, itemId in sortedItemIds do
	local item = ShopConfig.ITEMS[itemId]

	local row = Instance.new("Frame")
	row.Name = itemId
	row.LayoutOrder = index
	row.Size = UDim2.new(1, 0, 0, 50)
	row.BackgroundColor3 = COLOR_ROW
	addCorner(row, 8)
	addPadding(row, 8)
	row.Parent = itemList

	makeLabel("NameLabel", item.displayName, UDim2.new(1, -110, 0.5, 0), row)
	local priceLabel = makeLabel("PriceLabel", `{item.price} Coins`, UDim2.new(1, -110, 0.5, 0), row)
	priceLabel.Position = UDim2.fromScale(0, 0.5)
	priceLabel.TextColor3 = COLOR_MUTED
	priceLabel.TextSize = 14

	local buyButton = makeButton("BuyButton", "Kaufen", UDim2.new(0, 96, 1, 0), COLOR_BUY, row)
	buyButton.AnchorPoint = Vector2.new(1, 0)
	buyButton.Position = UDim2.fromScale(1, 0)
	buyButton.Activated:Connect(function()
		buyItem:FireServer(itemId)
	end)
	buyButtons[itemId] = buyButton
end

-- Inventar-Anzeige
local inventoryFrame = Instance.new("Frame")
inventoryFrame.Name = "InventoryFrame"
inventoryFrame.AnchorPoint = Vector2.new(1, 0.5)
inventoryFrame.Position = UDim2.new(1, -16, 0.5, 0)
inventoryFrame.Size = UDim2.fromOffset(200, 0)
inventoryFrame.AutomaticSize = Enum.AutomaticSize.Y
inventoryFrame.BackgroundColor3 = COLOR_PANEL
inventoryFrame.BackgroundTransparency = 0.15
addCorner(inventoryFrame, 10)
addPadding(inventoryFrame, 10)
inventoryFrame.Parent = screenGui

local inventoryLayout = Instance.new("UIListLayout")
inventoryLayout.Padding = UDim.new(0, 4)
inventoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
inventoryLayout.Parent = inventoryFrame

local inventoryTitle = makeLabel("Title", "Inventar", UDim2.new(1, 0, 0, 24), inventoryFrame)
inventoryTitle.Font = Enum.Font.GothamBold
inventoryTitle.TextSize = 18
inventoryTitle.LayoutOrder = 0

local emptyLabel = makeLabel("EmptyLabel", "leer", UDim2.new(1, 0, 0, 20), inventoryFrame)
emptyLabel.TextColor3 = COLOR_MUTED
emptyLabel.TextSize = 14
emptyLabel.LayoutOrder = 1

local inventoryRows: { [string]: TextLabel } = {}
for index, itemId in sortedItemIds do
	local row = makeLabel(itemId, "", UDim2.new(1, 0, 0, 20), inventoryFrame)
	row.TextSize = 15
	row.LayoutOrder = index + 1
	row.Visible = false
	inventoryRows[itemId] = row
end

screenGui.Parent = playerGui

-- ===== Logik =====

local function refreshShop()
	local coins = getCoins()
	coinsLabel.Text = `Coins: {coins}`
	for itemId, button in buyButtons do
		local affordable = coins >= ShopConfig.ITEMS[itemId].price
		button.BackgroundColor3 = if affordable then COLOR_BUY else COLOR_DISABLED
	end
end

local function refreshInventory()
	local inventory = player:FindFirstChild("Inventory")
	local hasItems = false
	for itemId, row in inventoryRows do
		local value = inventory and inventory:FindFirstChild(itemId)
		local count = if value then (value :: IntValue).Value else 0
		row.Visible = count > 0
		row.Text = `{ShopConfig.ITEMS[itemId].displayName}  x{count}`
		hasItems = hasItems or count > 0
	end
	emptyLabel.Visible = not hasItems
end

local function setShopOpen(open: boolean)
	shopFrame.Visible = open
	if open then
		refreshShop()
	end
end

toggleButton.Activated:Connect(function()
	setShopOpen(not shopFrame.Visible)
end)
closeButton.Activated:Connect(function()
	setShopOpen(false)
end)

local statusToken = 0
buyItem.OnClientEvent:Connect(function(success: boolean, _itemId: string?, message: string)
	statusToken += 1
	local token = statusToken
	statusLabel.Text = message
	statusLabel.TextColor3 = if success then COLOR_SUCCESS else COLOR_ERROR
	refreshShop()
	task.delay(STATUS_SECONDS, function()
		if token == statusToken then
			statusLabel.Text = ""
		end
	end)
end)

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

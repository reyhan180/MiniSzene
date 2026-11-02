-- Kauf-Validierung für den Shop.
-- Client -> Server:  BuyItem:FireServer(itemId)
-- Server -> Client:  BuyItem:FireClient(player, success, itemId, message)
--
-- Der Client schickt nur die Item-ID. Preis, Kontostand und Inventar kennt allein der Server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local Log = require(ReplicatedStorage:WaitForChild("Log"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local PURCHASE_COOLDOWN = 0.5
local log = Log.new("Shop")

-- Fallback, falls das RemoteEvent nicht über Rojo (BuyItem.model.json) angelegt wurde.
local buyItemEvent = ReplicatedStorage:FindFirstChild(ShopConfig.BUY_ITEM_EVENT) :: RemoteEvent?
if not buyItemEvent then
	local created = Instance.new("RemoteEvent")
	created.Name = ShopConfig.BUY_ITEM_EVENT
	created.Parent = ReplicatedStorage
	buyItemEvent = created
end
local buyItem = buyItemEvent :: RemoteEvent

local lastPurchase: { [Player]: number } = {}

local function reply(player: Player, success: boolean, itemId: string?, message: string)
	buyItem:FireClient(player, success, itemId, message)
	local prefix = if success then "Kauf" else "Kauf abgelehnt"
	log.info(`{prefix}: {player.Name} -> {itemId or "?"} ({message})`)
end

local function onBuyItem(player: Player, itemId: unknown)
	-- 1. Eingabe prüfen (Client-Daten sind nie vertrauenswürdig)
	if type(itemId) ~= "string" then
		reply(player, false, nil, "Ungültige Anfrage")
		return
	end
	local item = ShopConfig.getItem(itemId)
	if not item then
		reply(player, false, itemId, "Unbekanntes Item")
		return
	end

	-- 2. Spam-Schutz
	local now = os.clock()
	if lastPurchase[player] and now - lastPurchase[player] < PURCHASE_COOLDOWN then
		reply(player, false, itemId, "Zu schnell")
		return
	end
	lastPurchase[player] = now

	-- 3. Daten müssen geladen sein
	if not PlayerDataService.isLoaded(player) then
		reply(player, false, itemId, "Daten noch nicht geladen")
		return
	end

	-- 4. Coins prüfen und abziehen, dann Item gutschreiben
	if not PlayerDataService.trySpendCoins(player, item.price) then
		reply(player, false, itemId, `Nicht genug Coins ({item.price} benötigt)`)
		return
	end
	PlayerDataService.addItem(player, itemId, 1)

	reply(player, true, itemId, `{item.displayName} gekauft für {item.price} Coins`)
end

buyItem.OnServerEvent:Connect(onBuyItem)

game:GetService("Players").PlayerRemoving:Connect(function(player)
	lastPurchase[player] = nil
end)

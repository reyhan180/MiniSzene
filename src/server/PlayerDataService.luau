-- Spielerdaten: Laden/Speichern über DataStoreService, leaderstats und Inventar-Ordner.
-- Nur der Server verändert Daten. Andere Server-Skripte nutzen die API unten.
--
-- Gespeichertes Format pro Spieler (Key "Player_<UserId>"):
--   { Coins = number, Inventory = { [itemId] = anzahl } }
--
-- Sichtbar für den Client (repliziert, nur lesend):
--   player.leaderstats.Coins   (IntValue)
--   player.Inventory.<itemId>  (IntValue = Anzahl)

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))

local DATA_STORE_NAME = "PlayerData_v1"
local AUTOSAVE_INTERVAL = 60
local MAX_RETRIES = 3
local RETRY_DELAY = 1

export type PlayerData = {
	Coins: number,
	Inventory: { [string]: number },
}

local PlayerDataService = {}

local dataStore: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(DATA_STORE_NAME)
	end)
	if ok then
		dataStore = result
	else
		warn(`[PlayerData] DataStore nicht verfügbar, Daten werden nicht gespeichert: {result}`)
	end
end

local sessionData: { [Player]: PlayerData } = {}
-- Nur speichern, wenn das Laden geklappt hat. Sonst würden echte Daten mit Defaults überschrieben.
local canSave: { [Player]: boolean } = {}

local function getKey(player: Player): string
	return `Player_{player.UserId}`
end

local function withRetries<T>(label: string, callback: () -> T): (boolean, T | string)
	local lastError
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(callback)
		if ok then
			return true, result
		end
		lastError = result
		warn(`[PlayerData] {label} fehlgeschlagen (Versuch {attempt}/{MAX_RETRIES}): {result}`)
		if attempt < MAX_RETRIES then
			task.wait(RETRY_DELAY)
		end
	end
	return false, lastError
end

-- Gespeicherte Daten bereinigen: fehlende Felder ergänzen, unbekannte Items verwerfen.
local function reconcile(raw: any): PlayerData
	local data: PlayerData = { Coins = ShopConfig.START_COINS, Inventory = {} }
	if type(raw) ~= "table" then
		return data
	end
	if type(raw.Coins) == "number" and raw.Coins >= 0 then
		data.Coins = math.floor(raw.Coins)
	end
	if type(raw.Inventory) == "table" then
		for itemId, count in raw.Inventory do
			if ShopConfig.getItem(itemId) and type(count) == "number" and count > 0 then
				data.Inventory[itemId] = math.floor(count)
			end
		end
	end
	return data
end

local function savePlayer(player: Player)
	local data = sessionData[player]
	if not data or not canSave[player] or not dataStore then
		return
	end
	local store = dataStore :: DataStore
	local ok = withRetries(`Speichern von {player.Name}`, function()
		store:UpdateAsync(getKey(player), function()
			return data
		end)
	end)
	if ok then
		print(`[PlayerData] {player.Name} gespeichert (Coins: {data.Coins})`)
	end
end

local function createValueObjects(player: Player, data: PlayerData)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.Coins
	coins.Parent = leaderstats
	leaderstats.Parent = player

	local inventory = Instance.new("Folder")
	inventory.Name = "Inventory"
	for itemId, count in data.Inventory do
		local value = Instance.new("IntValue")
		value.Name = itemId
		value.Value = count
		value.Parent = inventory
	end
	inventory.Parent = player
end

local function loadPlayer(player: Player)
	local raw = nil
	local loaded = false
	if dataStore then
		local store = dataStore :: DataStore
		local ok, result = withRetries(`Laden von {player.Name}`, function()
			return store:GetAsync(getKey(player))
		end)
		loaded = ok
		if ok then
			raw = result
		end
	end

	if not player.Parent then
		return -- Spieler hat während des Ladens verlassen.
	end

	local data = reconcile(raw)
	sessionData[player] = data
	canSave[player] = loaded
	if not loaded then
		warn(`[PlayerData] {player.Name}: Laden fehlgeschlagen, Sitzung läuft mit Startwerten ohne Speichern.`)
	end
	createValueObjects(player, data)
	player:SetAttribute("DataLoaded", true)
	print(`[PlayerData] {player.Name} geladen (Coins: {data.Coins}, neu: {raw == nil})`)
end

local function onPlayerRemoving(player: Player)
	savePlayer(player)
	sessionData[player] = nil
	canSave[player] = nil
end

-- ===== Öffentliche API (nur Server) =====

function PlayerDataService.isLoaded(player: Player): boolean
	return sessionData[player] ~= nil
end

function PlayerDataService.getCoins(player: Player): number?
	local data = sessionData[player]
	return data and data.Coins
end

function PlayerDataService.addCoins(player: Player, amount: number)
	local data = sessionData[player]
	if not data then
		return
	end
	data.Coins = math.max(0, data.Coins + math.floor(amount))
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins then
		(coins :: IntValue).Value = data.Coins
	end
end

-- Zieht Coins nur ab, wenn genug vorhanden sind. Gibt true bei Erfolg zurück.
function PlayerDataService.trySpendCoins(player: Player, amount: number): boolean
	local data = sessionData[player]
	if not data or amount < 0 or data.Coins < amount then
		return false
	end
	PlayerDataService.addCoins(player, -amount)
	return true
end

function PlayerDataService.addItem(player: Player, itemId: string, amount: number?)
	local data = sessionData[player]
	if not data then
		return
	end
	local newCount = (data.Inventory[itemId] or 0) + (amount or 1)
	data.Inventory[itemId] = newCount

	local inventory = player:FindFirstChild("Inventory")
	if inventory then
		local value = inventory:FindFirstChild(itemId) :: IntValue?
		if not value then
			local created = Instance.new("IntValue")
			created.Name = itemId
			created.Parent = inventory
			value = created
		end
		(value :: IntValue).Value = newCount
	end
end

function PlayerDataService.getItemCount(player: Player, itemId: string): number
	local data = sessionData[player]
	return data and data.Inventory[itemId] or 0
end

-- ===== Start =====

function PlayerDataService.start()
	Players.PlayerAdded:Connect(loadPlayer)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(loadPlayer, player)
	end

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in sessionData do
				task.spawn(savePlayer, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in sessionData do
			pending += 1
			task.spawn(function()
				savePlayer(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + (RunService:IsStudio() and 5 or 25)
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return PlayerDataService

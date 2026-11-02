-- Release-Prüfung beim Serverstart.
-- Prüft Konfiguration und Map auf Werte, die im Live-Betrieb zu Fehlern führen würden,
-- und meldet das Ergebnis in der Konsole:
--   [ReleaseCheck] OK – N Prüfungen bestanden
--   [ReleaseCheck] <Problem>  (als Warnung, je Problem eine Zeile)
-- Ändert selbst nichts am Spiel.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Log = require(ReplicatedStorage:WaitForChild("Log"))
local RoundConfig = require(ReplicatedStorage:WaitForChild("RoundConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local SoundConfig = require(ReplicatedStorage:WaitForChild("SoundConfig"))

local log = Log.new("ReleaseCheck")
local EVENT_TIMEOUT = 10
local LANDSCAPE = {
	[Enum.ScreenOrientation.LandscapeSensor] = true,
	[Enum.ScreenOrientation.LandscapeLeft] = true,
	[Enum.ScreenOrientation.LandscapeRight] = true,
}

local checks, problems = 0, 0

local function check(condition: boolean, problem: string)
	checks += 1
	if not condition then
		problems += 1
		log.warn(problem)
	end
end

local function countSpawns(path: { string }): number
	local folder: Instance? = workspace
	for _, name in path do
		folder = folder and folder:FindFirstChild(name)
	end
	local count = 0
	if folder then
		for _, child in folder:GetChildren() do
			if child:IsA("BasePart") then
				count += 1
			end
		end
	end
	return count
end

local function isPositiveInteger(value: any): boolean
	return type(value) == "number" and value > 0 and value % 1 == 0
end

-- Runden-Konfiguration
for _, key in { "INTERMISSION_SECONDS", "COUNTDOWN_SECONDS", "ROUND_SECONDS", "ROUND_END_SECONDS" } do
	check(isPositiveInteger(RoundConfig[key]), `RoundConfig.{key} muss eine positive ganze Zahl sein`)
end
check(RoundConfig.WARNING_SECONDS < RoundConfig.ROUND_SECONDS, "WARNING_SECONDS muss kleiner als ROUND_SECONDS sein")
check(isPositiveInteger(RoundConfig.WIN_REWARD), "WIN_REWARD muss positiv sein")
check(isPositiveInteger(RoundConfig.PARTICIPATION_REWARD), "PARTICIPATION_REWARD muss positiv sein")
check(
	RoundConfig.WIN_REWARD >= RoundConfig.PARTICIPATION_REWARD,
	"WIN_REWARD sollte mindestens so hoch sein wie PARTICIPATION_REWARD"
)
check(RoundConfig.MIN_PLAYERS >= 2, "MIN_PLAYERS sollte live mindestens 2 sein")

-- Spielerzahl & Startpunkte
local maxPlayers = Players.MaxPlayers
check(RoundConfig.MIN_PLAYERS <= maxPlayers, `MIN_PLAYERS ({RoundConfig.MIN_PLAYERS}) > MaxPlayers ({maxPlayers})`)
local arenaSpawns = countSpawns(RoundConfig.ARENA_SPAWNS_PATH)
local lobbySpawns = countSpawns(RoundConfig.LOBBY_SPAWNS_PATH)
check(arenaSpawns >= maxPlayers, `Nur {arenaSpawns} Arena-Startpunkte für MaxPlayers = {maxPlayers}`)
check(lobbySpawns >= maxPlayers, `Nur {lobbySpawns} Lobby-Plätze für MaxPlayers = {maxPlayers}`)

-- Shop
check(type(ShopConfig.START_COINS) == "number" and ShopConfig.START_COINS >= 0, "START_COINS muss >= 0 sein")
for itemId, item in ShopConfig.ITEMS do
	check(isPositiveInteger(item.price), `Item {itemId}: Preis muss eine positive ganze Zahl sein`)
	check(type(item.displayName) == "string" and item.displayName ~= "", `Item {itemId}: displayName fehlt`)
end

-- RemoteEvents
for _, name in { ShopConfig.BUY_ITEM_EVENT, RoundConfig.ANNOUNCEMENT_EVENT } do
	local event = ReplicatedStorage:WaitForChild(name, EVENT_TIMEOUT)
	check(event ~= nil and event:IsA("RemoteEvent"), `RemoteEvent ReplicatedStorage.{name} fehlt`)
end

-- Sounds
for name, info in SoundConfig.SOUNDS do
	check(string.match(info.id, "^rbxassetid://%d+$") ~= nil, `Sound {name}: ungültige ID "{info.id}"`)
end

-- Mobile: Querformat
check(LANDSCAPE[StarterGui.ScreenOrientation] == true, "StarterGui.ScreenOrientation ist nicht auf Querformat gestellt")

if problems == 0 then
	log.info(`OK – {checks} Prüfungen bestanden (MaxPlayers {maxPlayers}, {arenaSpawns} Arena-/{lobbySpawns} Lobby-Startpunkte)`)
else
	log.warn(`{problems} von {checks} Prüfungen fehlgeschlagen`)
end
if RunService:IsStudio() then
	log.info(`Studio-Modus: MIN_PLAYERS_STUDIO = {RoundConfig.MIN_PLAYERS_STUDIO} statt {RoundConfig.MIN_PLAYERS}`)
end

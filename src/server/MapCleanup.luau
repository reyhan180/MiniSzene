-- Map- & State-Cleanup nach Rundenende (Server).
--
-- 1. Entfernt alles, was während einer Runde gespawnt wurde:
--    * Inhalt von Workspace.RoundObjects (Ablage für Runden-Objekte)
--    * alle Instanzen mit dem Tag SPAWNED_TAG ("RoundSpawned"), egal wo sie liegen
--    * lose Tools/Accessories direkt in Workspace (z. B. fallen gelassene Gegenstände)
-- 2. Setzt die Tankstellen-Interaktionen zurück:
--    * ProximityPrompts mit Tag "GasStationPrompt" -> Enabled-Zustand vom Serverstart
--    * Zapfsäulen-Displays und Kassen-Display -> Farbe vom Serverstart
--
-- Neue Systeme, die während einer Runde Objekte erzeugen, rufen MapCleanup.registerSpawned(obj) auf.

local CollectionService = game:GetService("CollectionService")

local MapCleanup = {}

MapCleanup.SPAWNED_TAG = "RoundSpawned"
local ROUND_FOLDER_NAME = "RoundObjects"
local PROMPT_TAG = "GasStationPrompt"
local PUMP_DETAILS_NAME = "ZapfsäulenDetails"
local CASH_DISPLAY_NAME = "KassenDisplay"

export type CleanupStats = {
	removedObjects: number,
	promptsReset: number,
	displaysReset: number,
}

-- Ausgangszustand, beim Serverstart erfasst
local baselinePrompts: { [ProximityPrompt]: boolean } = {}
local baselineColors: { [BasePart]: Color3 } = {}
local initialized = false

local function getRoundFolder(): Folder
	local folder = workspace:FindFirstChild(ROUND_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = ROUND_FOLDER_NAME
		folder.Parent = workspace
	end
	return folder :: Folder
end

local function collectDisplays(): { BasePart }
	local displays = {}
	local props = workspace:FindFirstChild("Environment") and workspace.Environment:FindFirstChild("Props")
	if not props then
		return displays
	end
	local pumpDetails = props:FindFirstChild(PUMP_DETAILS_NAME)
	if pumpDetails then
		for _, part in pumpDetails:GetChildren() do
			if part:IsA("BasePart") and part.Name:find("_Display") then
				table.insert(displays, part)
			end
		end
	end
	for _, part in props:GetDescendants() do
		if part:IsA("BasePart") and part.Name == CASH_DISPLAY_NAME then
			table.insert(displays, part)
		end
	end
	return displays
end

local function capturePrompt(prompt: Instance)
	if prompt:IsA("ProximityPrompt") and baselinePrompts[prompt] == nil then
		baselinePrompts[prompt] = prompt.Enabled
	end
end

-- Erfasst den Ausgangszustand. Muss beim Serverstart laufen, bevor eine Runde beginnt.
function MapCleanup.init()
	if initialized then
		return
	end
	initialized = true
	getRoundFolder()
	for _, prompt in CollectionService:GetTagged(PROMPT_TAG) do
		capturePrompt(prompt)
	end
	CollectionService:GetInstanceAddedSignal(PROMPT_TAG):Connect(capturePrompt)
	for _, part in collectDisplays() do
		baselineColors[part] = part.Color
	end
end

-- Markiert ein Objekt als Runden-Objekt. Ohne eigenen Parent landet es in Workspace.RoundObjects.
function MapCleanup.registerSpawned(instance: Instance, parent: Instance?): Instance
	CollectionService:AddTag(instance, MapCleanup.SPAWNED_TAG)
	instance.Parent = parent or instance.Parent or getRoundFolder()
	return instance
end

function MapCleanup.cleanup(): CleanupStats
	local stats: CleanupStats = { removedObjects = 0, promptsReset = 0, displaysReset = 0 }

	-- 1. Gespawnte Objekte entfernen
	local toDestroy: { [Instance]: boolean } = {}
	for _, child in getRoundFolder():GetChildren() do
		toDestroy[child] = true
	end
	for _, tagged in CollectionService:GetTagged(MapCleanup.SPAWNED_TAG) do
		toDestroy[tagged] = true
	end
	for _, child in workspace:GetChildren() do
		if child:IsA("Tool") or child:IsA("Accessory") then
			toDestroy[child] = true
		end
	end
	for instance in toDestroy do
		if instance.Parent then
			instance:Destroy()
			stats.removedObjects += 1
		end
	end

	-- 2. Tankstellen-Interaktionen zurücksetzen
	for prompt, enabled in baselinePrompts do
		if prompt.Parent then
			prompt.Enabled = enabled
			stats.promptsReset += 1
		else
			baselinePrompts[prompt] = nil
		end
	end
	for part, color in baselineColors do
		if part.Parent then
			part.Color = color
			stats.displaysReset += 1
		end
	end

	print(
		`[Cleanup] {stats.removedObjects} Objekte entfernt, {stats.promptsReset} Prompts und {stats.displaysReset} Displays zurückgesetzt`
	)
	return stats
end

return MapCleanup

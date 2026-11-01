-- Interaktionen an der Tankstelle: Einkaufen am Shop-Tresen, Tanken an den Zapfsäulen.
-- Die ProximityPrompts liegen in Workspace und sind mit PROMPT_TAG markiert.
-- Das Attribut "Interaction" ("Einkaufen" oder "Tanken") bestimmt die Logik.

local CollectionService = game:GetService("CollectionService")

local PROMPT_TAG = "GasStationPrompt"
local REFUEL_SECONDS = 3
local CHECKOUT_SECONDS = 1
local ACTIVE_COLOR = Color3.fromRGB(80, 220, 120)

local function getPumpDisplays(pump: BasePart): { BasePart }
	local details = workspace.Environment.Props:FindFirstChild("ZapfsäulenDetails")
	local displays = {}
	if details then
		for _, part in details:GetChildren() do
			if part:IsA("BasePart") and part.Name:find("^" .. pump.Name .. "_Display") then
				table.insert(displays, part)
			end
		end
	end
	return displays
end

local function flashParts(parts: { BasePart }, color: Color3, seconds: number)
	local originalColors = {}
	for _, part in parts do
		originalColors[part] = part.Color
		part.Color = color
	end
	task.wait(seconds)
	for part, originalColor in originalColors do
		part.Color = originalColor
	end
end

local function onRefuel(prompt: ProximityPrompt, player: Player)
	local pump = prompt:FindFirstAncestorWhichIsA("BasePart")
	if not pump then
		return
	end
	prompt.Enabled = false
	print(`[Tankstelle] {player.Name} tankt an {pump.Name}`)
	flashParts(getPumpDisplays(pump), ACTIVE_COLOR, REFUEL_SECONDS)
	player:SetAttribute("Tankvorgaenge", (player:GetAttribute("Tankvorgaenge") or 0) + 1)
	prompt.Enabled = true
end

local function onCheckout(prompt: ProximityPrompt, player: Player)
	local counter = prompt:FindFirstAncestorWhichIsA("Model")
	local display = counter and counter:FindFirstChild("KassenDisplay")
	prompt.Enabled = false
	print(`[Tankstelle] {player.Name} kauft im Shop ein`)
	player:SetAttribute("Einkaeufe", (player:GetAttribute("Einkaeufe") or 0) + 1)
	if display and display:IsA("BasePart") then
		flashParts({ display }, ACTIVE_COLOR, CHECKOUT_SECONDS)
	end
	prompt.Enabled = true
end

local HANDLERS = {
	Tanken = onRefuel,
	Einkaufen = onCheckout,
}

local function bindPrompt(prompt: Instance)
	if not prompt:IsA("ProximityPrompt") then
		return
	end
	local handler = HANDLERS[prompt:GetAttribute("Interaction")]
	if not handler then
		warn(`[Tankstelle] Unbekannte Interaktion an {prompt:GetFullName()}`)
		return
	end
	prompt.Triggered:Connect(function(player)
		handler(prompt, player)
	end)
end

for _, prompt in CollectionService:GetTagged(PROMPT_TAG) do
	bindPrompt(prompt)
end
CollectionService:GetInstanceAddedSignal(PROMPT_TAG):Connect(bindPrompt)

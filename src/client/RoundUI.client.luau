-- Statusanzeige des Runden-Systems (Client).
-- Liest nur die vom Server gesetzten Attribute (siehe RoundConfig) und zeigt sie oben in der Mitte an.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoundConfig = require(ReplicatedStorage:WaitForChild("RoundConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local STATES = RoundConfig.STATES

local COLOR_PANEL = Color3.fromRGB(30, 34, 42)
local COLOR_TEXT = Color3.fromRGB(240, 240, 240)
local COLOR_MUTED = Color3.fromRGB(170, 175, 185)
local COLOR_ACCENT = Color3.fromRGB(255, 200, 70)
local COLOR_SUCCESS = Color3.fromRGB(90, 220, 120)

-- ===== Aufbau =====

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RoundGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = -1 -- unter der ShopGui

local frame = Instance.new("Frame")
frame.Name = "StatusFrame"
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.Position = UDim2.new(0.5, 0, 0, 8)
frame.Size = UDim2.fromOffset(0, 0)
frame.AutomaticSize = Enum.AutomaticSize.XY
frame.BackgroundColor3 = COLOR_PANEL
frame.BackgroundTransparency = 0.15
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 18)
padding.PaddingRight = UDim.new(0, 18)
padding.Parent = frame

local layout = Instance.new("UIListLayout")
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 2)
layout.Parent = frame

local function makeLabel(name: string, order: number, textSize: number, font: Enum.Font, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.LayoutOrder = order
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Size = UDim2.fromOffset(0, 0)
	label.Font = font
	label.TextSize = textSize
	label.TextColor3 = color
	label.Text = ""
	label.Parent = frame
	return label
end

local titleLabel = makeLabel("TitleLabel", 1, 22, Enum.Font.GothamBold, COLOR_TEXT)
local detailLabel = makeLabel("DetailLabel", 2, 16, Enum.Font.GothamMedium, COLOR_MUTED)

screenGui.Parent = playerGui

-- ===== Anzeige =====

local function formatTime(seconds: number): string
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function refresh()
	local state = ReplicatedStorage:GetAttribute(RoundConfig.ATTR_STATE)
	local timeLeft = ReplicatedStorage:GetAttribute(RoundConfig.ATTR_TIME_LEFT) or 0
	local inRound = player:GetAttribute(RoundConfig.ATTR_IN_ROUND) == true
	local points = player:GetAttribute(RoundConfig.ATTR_POINTS) or 0

	titleLabel.TextColor3 = COLOR_TEXT
	detailLabel.TextColor3 = COLOR_MUTED

	if state == STATES.Waiting then
		local needed = ReplicatedStorage:GetAttribute(RoundConfig.ATTR_MIN_PLAYERS) or RoundConfig.MIN_PLAYERS
		titleLabel.Text = `Warte auf Spieler ({#Players:GetPlayers()}/{needed})`
		detailLabel.Text = "Die Runde startet, sobald genug Spieler da sind"
	elseif state == STATES.Intermission then
		titleLabel.Text = `Nächste Runde in {formatTime(timeLeft)}`
		detailLabel.Text = "Lobby – Tanken & Einkaufen bringt in der Runde Punkte"
	elseif state == STATES.Countdown then
		titleLabel.TextColor3 = COLOR_ACCENT
		titleLabel.Text = `Runde startet in {timeLeft}`
		detailLabel.Text = if inRound then "Mach dich bereit!" else "Du bist in der nächsten Runde dabei"
	elseif state == STATES.Playing then
		titleLabel.Text = `Runde läuft – {formatTime(timeLeft)}`
		if inRound then
			detailLabel.TextColor3 = COLOR_ACCENT
			detailLabel.Text = `Deine Punkte: {points}`
		else
			detailLabel.Text = "Zuschauer – du bist in der nächsten Runde dabei"
		end
	elseif state == STATES.RoundEnd then
		local reward = player:GetAttribute(RoundConfig.ATTR_REWARD) or 0
		titleLabel.TextColor3 = COLOR_SUCCESS
		titleLabel.Text = ReplicatedStorage:GetAttribute(RoundConfig.ATTR_MESSAGE) or "Runde vorbei"
		detailLabel.Text = if reward > 0 then `Deine Punkte: {points}  |  +{reward} Coins` else "Keine Belohnung in dieser Runde"
	else
		titleLabel.Text = "Lade Runde ..."
		detailLabel.Text = ""
	end
end

for _, attribute in {
	RoundConfig.ATTR_STATE,
	RoundConfig.ATTR_TIME_LEFT,
	RoundConfig.ATTR_MESSAGE,
	RoundConfig.ATTR_MIN_PLAYERS,
} do
	ReplicatedStorage:GetAttributeChangedSignal(attribute):Connect(refresh)
end
for _, attribute in { RoundConfig.ATTR_IN_ROUND, RoundConfig.ATTR_POINTS, RoundConfig.ATTR_REWARD } do
	player:GetAttributeChangedSignal(attribute):Connect(refresh)
end
Players.PlayerAdded:Connect(refresh)
Players.PlayerRemoving:Connect(function()
	task.defer(refresh)
end)

refresh()

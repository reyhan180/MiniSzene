-- Statusanzeige des Runden-Systems (Client).
-- Liest nur die vom Server gesetzten Attribute (siehe RoundConfig) und zeigt sie oben in der Mitte an.
-- Schriftgrößen passen sich über UILayout an kleine Bildschirme an.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoundConfig = require(ReplicatedStorage:WaitForChild("RoundConfig"))
local UITheme = require(ReplicatedStorage:WaitForChild("UITheme"))
local UILayout = require(ReplicatedStorage:WaitForChild("UILayout"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local STATES = RoundConfig.STATES
local COLORS = UITheme.COLORS

-- ===== Aufbau =====

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RoundGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = -1 -- unter der ShopGui

local frame = UITheme.makePanel("StatusFrame", screenGui)
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.Position = UDim2.new(0.5, 0, 0, 8)
frame.Size = UDim2.fromOffset(0, 0)
frame.AutomaticSize = Enum.AutomaticSize.XY

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 6)
padding.PaddingBottom = UDim.new(0, 6)
padding.PaddingLeft = UDim.new(0, 16)
padding.PaddingRight = UDim.new(0, 16)
padding.Parent = frame

local layout = Instance.new("UIListLayout")
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 2)
layout.Parent = frame

local function makeLabel(name: string, order: number, font: Enum.Font): TextLabel
	local label = UITheme.makeLabel(name, "", UITheme.TEXT_SIZE.Body, frame)
	label.LayoutOrder = order
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Size = UDim2.fromOffset(0, 0)
	label.Font = font
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextTruncate = Enum.TextTruncate.None
	return label
end

local titleLabel = makeLabel("TitleLabel", 1, UITheme.FONTS.Bold)
local detailLabel = makeLabel("DetailLabel", 2, UITheme.FONTS.Regular)

screenGui.Parent = playerGui

local function applyLayout()
	local computed = UILayout.compute(screenGui.AbsoluteSize, 1)
	titleLabel.TextSize = computed.statusTitleSize
	detailLabel.TextSize = computed.statusDetailSize
end
screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyLayout)
applyLayout()

-- ===== Anzeige =====

local function formatTime(seconds: number): string
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function refresh()
	local state = ReplicatedStorage:GetAttribute(RoundConfig.ATTR_STATE)
	local timeLeft = ReplicatedStorage:GetAttribute(RoundConfig.ATTR_TIME_LEFT) or 0
	local inRound = player:GetAttribute(RoundConfig.ATTR_IN_ROUND) == true
	local points = player:GetAttribute(RoundConfig.ATTR_POINTS) or 0

	titleLabel.TextColor3 = COLORS.Text
	detailLabel.TextColor3 = COLORS.Muted

	if state == STATES.Waiting then
		local needed = ReplicatedStorage:GetAttribute(RoundConfig.ATTR_MIN_PLAYERS) or RoundConfig.MIN_PLAYERS
		titleLabel.Text = `Warte auf Spieler ({#Players:GetPlayers()}/{needed})`
		detailLabel.Text = "Die Runde startet, sobald genug Spieler da sind"
	elseif state == STATES.Intermission then
		titleLabel.Text = `Nächste Runde in {formatTime(timeLeft)}`
		detailLabel.Text = "Lobby – Tanken & Einkaufen bringt in der Runde Punkte"
	elseif state == STATES.Countdown then
		titleLabel.TextColor3 = COLORS.Accent
		titleLabel.Text = `Runde startet in {timeLeft}`
		detailLabel.Text = if inRound then "Mach dich bereit!" else "Du bist in der nächsten Runde dabei"
	elseif state == STATES.Playing then
		titleLabel.Text = `Runde läuft – {formatTime(timeLeft)}`
		if inRound then
			detailLabel.TextColor3 = COLORS.Accent
			detailLabel.Text = `Deine Punkte: {points}`
		else
			detailLabel.Text = "Zuschauer – du bist in der nächsten Runde dabei"
		end
	elseif state == STATES.RoundEnd then
		local reward = player:GetAttribute(RoundConfig.ATTR_REWARD) or 0
		titleLabel.TextColor3 = COLORS.Success
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

-- Bildschirmfüllende Runden-Ankündigungen (Client).
-- Empfängt RoundAnnouncement:FireAllClients(phase, title, subtitle, duration) vom Server
-- und zeigt ein Banner über dem ganzen Bildschirm (abgedunkelter Hintergrund, großer Text).
-- Eine neue Ankündigung ersetzt sofort die laufende. Klicks gehen durch das Banner hindurch.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RoundConfig = require(ReplicatedStorage:WaitForChild("RoundConfig"))
local announcement = ReplicatedStorage:WaitForChild(RoundConfig.ANNOUNCEMENT_EVENT) :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PHASES = RoundConfig.PHASES
local FADE_IN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FADE_OUT = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local OVERLAY_TRANSPARENCY = 0.55
local MAX_DURATION = 10

-- Akzentfarbe je Phase
local PHASE_COLORS = {
	[PHASES.Lobby] = Color3.fromRGB(110, 170, 255),
	[PHASES.Countdown] = Color3.fromRGB(255, 200, 70),
	[PHASES.InGame] = Color3.fromRGB(90, 220, 120),
	[PHASES.RoundEnd] = Color3.fromRGB(255, 215, 90),
}
-- Kurzer Phasen-Name über dem Titel
local PHASE_LABELS = {
	[PHASES.Lobby] = "LOBBY",
	[PHASES.Countdown] = "COUNTDOWN",
	[PHASES.InGame] = "IN GAME",
	[PHASES.RoundEnd] = "RUNDENENDE",
}

-- ===== Aufbau =====

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AnnouncementGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 10 -- über RoundGui und ShopGui

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.Active = false
overlay.Interactable = false
overlay.Visible = false
overlay.Parent = screenGui

local function makeLabel(name: string, posY: number, sizeY: number, font: Enum.Font, maxTextSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, posY)
	label.Size = UDim2.fromScale(0.9, sizeY)
	label.BackgroundTransparency = 1
	label.Font = font
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextTransparency = 1
	label.TextStrokeTransparency = 1
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = overlay
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = maxTextSize
	constraint.Parent = label
	return label
end

local phaseLabel = makeLabel("PhaseLabel", 0.36, 0.05, Enum.Font.GothamBold, 26)
local titleLabel = makeLabel("TitleLabel", 0.47, 0.16, Enum.Font.GothamBlack, 110)
local subtitleLabel = makeLabel("SubtitleLabel", 0.58, 0.05, Enum.Font.GothamMedium, 30)

screenGui.Parent = playerGui

-- ===== Anzeige =====

local labels = { phaseLabel, titleLabel, subtitleLabel }
local showToken = 0

local function tweenAll(info: TweenInfo, overlayTransparency: number, textTransparency: number): Tween
	local last = TweenService:Create(overlay, info, { BackgroundTransparency = overlayTransparency })
	last:Play()
	for _, label in labels do
		TweenService:Create(label, info, {
			TextTransparency = textTransparency,
			TextStrokeTransparency = if textTransparency >= 1 then 1 else 0.6,
		}):Play()
	end
	return last
end

local function show(phase: string, title: string, subtitle: string, duration: number)
	showToken += 1
	local token = showToken
	duration = math.clamp(duration, 0.5, MAX_DURATION)

	local color = PHASE_COLORS[phase] or Color3.new(1, 1, 1)
	phaseLabel.Text = PHASE_LABELS[phase] or phase
	phaseLabel.TextColor3 = color
	titleLabel.Text = title
	titleLabel.TextColor3 = color
	subtitleLabel.Text = subtitle
	subtitleLabel.Visible = subtitle ~= ""

	-- Countdown-Zahlen ohne dunklen Hintergrund, damit die Sicht frei bleibt
	local overlayTarget = if phase == PHASES.Countdown then 1 else OVERLAY_TRANSPARENCY

	overlay.Visible = true
	tweenAll(FADE_IN, overlayTarget, 0)

	task.delay(duration, function()
		if token ~= showToken then
			return -- schon durch eine neuere Ankündigung ersetzt
		end
		local fade = tweenAll(FADE_OUT, 1, 1)
		fade.Completed:Wait()
		if token == showToken then
			overlay.Visible = false
		end
	end)
end

announcement.OnClientEvent:Connect(function(phase: string, title: string, subtitle: string?, duration: number?)
	if type(phase) ~= "string" or type(title) ~= "string" then
		return
	end
	show(phase, title, subtitle or "", tonumber(duration) or 3)
end)

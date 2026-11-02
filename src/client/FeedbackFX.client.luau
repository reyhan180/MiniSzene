-- Sound- und Popup-Feedback (Client, nur lokal).
--
-- Sounds (IDs in SoundConfig):
--   Kauf erfolgreich / abgelehnt   <- BuyItem:OnClientEvent
--   Punkt erhalten                 <- Attribut RoundPoints steigt (nur als Teilnehmer)
--   Countdown-Tick, Rundenstart    <- RoundAnnouncement (Phase Countdown / InGame "LOS!")
--   Sieg / Teilnahme-Coins         <- Attribut RoundReward am Rundenende
-- Popups: "+1 Punkt" bzw. "+50 Coins" steigen in der Bildschirmmitte auf und verblassen.

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local RoundConfig = require(ReplicatedStorage:WaitForChild("RoundConfig"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local SoundConfig = require(ReplicatedStorage:WaitForChild("SoundConfig"))
local UITheme = require(ReplicatedStorage:WaitForChild("UITheme"))
local Log = require(ReplicatedStorage:WaitForChild("Log"))

local buyItem = ReplicatedStorage:WaitForChild(ShopConfig.BUY_ITEM_EVENT) :: RemoteEvent
local announcement = ReplicatedStorage:WaitForChild(RoundConfig.ANNOUNCEMENT_EVENT) :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local log = Log.new("Feedback")

local POPUP_RISE = 70
local POPUP_SECONDS = 1.1

-- ===== Sounds =====

local soundFolder = Instance.new("Folder")
soundFolder.Name = "FeedbackSounds"
soundFolder.Parent = SoundService

local sounds: { [string]: Sound } = {}
for name, info in SoundConfig.SOUNDS do
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = info.id
	sound.Volume = info.volume
	sound.PlaybackSpeed = info.playbackSpeed or 1
	sound.Parent = soundFolder
	sounds[name] = sound
end

task.spawn(function()
	local list = {}
	for _, sound in sounds do
		table.insert(list, sound)
	end
	ContentProvider:PreloadAsync(list, function(contentId: string, status: Enum.AssetFetchStatus)
		if status ~= Enum.AssetFetchStatus.Success then
			log.warn(`Sound konnte nicht geladen werden: {contentId} ({status.Name})`)
		end
	end)
end)

local function playSound(name: string)
	local sound = sounds[name]
	if sound then
		SoundService:PlayLocalSound(sound)
	end
end

-- ===== Popups =====

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FeedbackGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 5 -- über Shop/Status, unter Ankündigungen
screenGui.Parent = playerGui

local function showPopup(text: string, color: Color3)
	local label = Instance.new("TextLabel")
	label.Name = "Popup"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.68)
	label.Size = UDim2.fromOffset(260, 48)
	label.BackgroundTransparency = 1
	label.Font = UITheme.FONTS.Heavy
	label.TextSize = 36
	label.TextColor3 = color
	label.TextStrokeColor3 = UITheme.COLORS.Stroke
	label.TextStrokeTransparency = 0.4
	label.Text = text
	label.Parent = screenGui

	local tween = TweenService:Create(
		label,
		TweenInfo.new(POPUP_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = label.Position - UDim2.fromOffset(0, POPUP_RISE),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}
	)
	tween.Completed:Once(function()
		label:Destroy()
	end)
	tween:Play()
end

-- ===== Ereignisse =====

buyItem.OnClientEvent:Connect(function(success: boolean)
	playSound(if success then "PurchaseSuccess" else "PurchaseFail")
end)

local lastPoints = player:GetAttribute(RoundConfig.ATTR_POINTS) or 0
player:GetAttributeChangedSignal(RoundConfig.ATTR_POINTS):Connect(function()
	local points = player:GetAttribute(RoundConfig.ATTR_POINTS) or 0
	local gained = points - lastPoints
	lastPoints = points
	if gained > 0 and player:GetAttribute(RoundConfig.ATTR_IN_ROUND) == true then
		playSound("Point")
		showPopup(`+{gained} Punkt`, UITheme.COLORS.Accent)
	end
end)

player:GetAttributeChangedSignal(RoundConfig.ATTR_REWARD):Connect(function()
	local reward = player:GetAttribute(RoundConfig.ATTR_REWARD) or 0
	if reward <= 0 then
		return
	end
	playSound(if reward >= RoundConfig.WIN_REWARD then "Victory" else "Reward")
	showPopup(`+{reward} Coins`, UITheme.COLORS.Gold)
end)

announcement.OnClientEvent:Connect(function(phase: string, title: string)
	if phase == RoundConfig.PHASES.Countdown then
		playSound("CountdownTick")
	elseif phase == RoundConfig.PHASES.InGame and title == "LOS!" then
		playSound("RoundStart")
	end
end)

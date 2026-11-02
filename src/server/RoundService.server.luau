-- Runden-System als State Machine (Server).
--
-- Ablauf (Endlosschleife):
--   Waiting      bis genug Spieler da sind (RoundConfig.MIN_PLAYERS)
--   Intermission Pause in der Lobby (Gang hinter dem Shop)
--   Countdown    Teilnehmer werden zur Tankstelle teleportiert und kurz eingefroren
--   Playing      60 s: jede Interaktion (Tanken/Einkaufen) = 1 Punkt
--   RoundEnd     Gewinner bestimmen, Coins vergeben, alle zurück in die Lobby
--
-- Fallen in Intermission/Countdown zu viele Spieler weg, geht es zurück zu Waiting.
-- Phasenwechsel werden über das RemoteEvent RoundAnnouncement an alle Clients gemeldet,
-- Rundendaten über RoundAnalytics geloggt, nach Rundenende räumt MapCleanup die Map auf.
-- Den Zustand bestimmt allein der Server. Clients lesen nur die Attribute (siehe RoundConfig).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RoundConfig = require(ReplicatedStorage:WaitForChild("RoundConfig"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local MapCleanup = require(script.Parent:WaitForChild("MapCleanup"))
local RoundAnalytics = require(script.Parent:WaitForChild("RoundAnalytics"))

local STATES = RoundConfig.STATES
local PHASES = RoundConfig.PHASES
local PROMPT_TAG = "GasStationPrompt"
local SCORING_INTERACTIONS = { Tanken = true, Einkaufen = true }
local TELEPORT_HEIGHT = 3
local MIN_PLAYERS = if RunService:IsStudio() then RoundConfig.MIN_PLAYERS_STUDIO else RoundConfig.MIN_PLAYERS

local currentState: string? = nil
-- Aktive Teilnehmer der laufenden Runde (beigetreten bei Countdown, noch am Leben und im Spiel)
local participants: { [Player]: boolean } = {}
-- Ursprüngliche Bewegungswerte eingefrorener Spieler
local frozenHumanoids: { [Humanoid]: { walkSpeed: number, jumpPower: number, jumpHeight: number } } = {}

-- ===== State Machine =====

local function setState(newState: string): boolean
	if currentState ~= nil then
		local allowed = RoundConfig.TRANSITIONS[currentState]
		if not (allowed and allowed[newState]) then
			warn(`[Runde] Ungültiger Übergang {currentState} -> {newState} verhindert`)
			return false
		end
	end
	print(`[Runde] {currentState or "Start"} -> {newState}`)
	currentState = newState
	ReplicatedStorage:SetAttribute(RoundConfig.ATTR_STATE, newState)
	return true
end

local function setTimeLeft(seconds: number)
	ReplicatedStorage:SetAttribute(RoundConfig.ATTR_TIME_LEFT, seconds)
end

-- Fallback, falls das RemoteEvent nicht über Rojo (RoundAnnouncement.model.json) angelegt wurde.
local announcementEvent = ReplicatedStorage:FindFirstChild(RoundConfig.ANNOUNCEMENT_EVENT) :: RemoteEvent?
if not announcementEvent then
	local created = Instance.new("RemoteEvent")
	created.Name = RoundConfig.ANNOUNCEMENT_EVENT
	created.Parent = ReplicatedStorage
	announcementEvent = created
end
local announcement = announcementEvent :: RemoteEvent

-- Globale Ankündigung an alle Clients (bildschirmfüllendes Banner, siehe AnnouncementUI)
local function announce(phase: string, title: string, subtitle: string?, duration: number)
	announcement:FireAllClients(phase, title, subtitle or "", duration)
end

-- Zählt die Zeit sekundenweise herunter. Gibt false zurück, wenn shouldAbort() vorher true liefert.
-- onTick(timeLeft) wird zu Beginn jeder Sekunde aufgerufen.
local function runTimer(seconds: number, shouldAbort: (() -> boolean)?, onTick: ((number) -> ())?): boolean
	for timeLeft = seconds, 1, -1 do
		setTimeLeft(timeLeft)
		if onTick then
			onTick(timeLeft)
		end
		task.wait(1)
		if shouldAbort and shouldAbort() then
			return false
		end
	end
	setTimeLeft(0)
	return true
end

-- ===== Hilfsfunktionen Spieler =====

local function getHumanoid(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function isAlive(player: Player): boolean
	local humanoid = getHumanoid(player)
	return humanoid ~= nil and humanoid.Health > 0 and player.Character:FindFirstChild("HumanoidRootPart") ~= nil
end

local function enoughPlayers(): boolean
	return #Players:GetPlayers() >= MIN_PLAYERS
end

local function getParticipantList(): { Player }
	local list = {}
	for player in participants do
		table.insert(list, player)
	end
	table.sort(list, function(a, b)
		return a.UserId < b.UserId
	end)
	return list
end

local function activeCount(): number
	return #getParticipantList()
end

local function getSpawnPoints(path: { string }): { BasePart }
	local folder: Instance? = workspace
	for _, name in path do
		folder = folder and folder:FindFirstChild(name)
	end
	local points = {}
	if folder then
		for _, child in folder:GetChildren() do
			if child:IsA("BasePart") then
				table.insert(points, child)
			end
		end
	end
	table.sort(points, function(a, b)
		return a.Name < b.Name
	end)
	if #points == 0 then
		warn(`[Runde] Keine Startpunkte unter Workspace.{table.concat(path, ".")}`)
	end
	return points
end

-- Verteilt die Spieler reihum auf die Startpunkte.
local function teleportPlayers(players: { Player }, points: { BasePart })
	if #points == 0 then
		return
	end
	for index, player in players do
		local character = player.Character
		if character and isAlive(player) then
			local point = points[(index - 1) % #points + 1]
			character:PivotTo(point.CFrame + Vector3.new(0, TELEPORT_HEIGHT, 0))
		end
	end
end

local function setFrozen(player: Player, frozen: boolean)
	local humanoid = getHumanoid(player)
	if not humanoid then
		return
	end
	if frozen and not frozenHumanoids[humanoid] then
		frozenHumanoids[humanoid] = {
			walkSpeed = humanoid.WalkSpeed,
			jumpPower = humanoid.JumpPower,
			jumpHeight = humanoid.JumpHeight,
		}
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	elseif not frozen and frozenHumanoids[humanoid] then
		local original = frozenHumanoids[humanoid]
		humanoid.WalkSpeed = original.walkSpeed
		humanoid.JumpPower = original.jumpPower
		humanoid.JumpHeight = original.jumpHeight
		frozenHumanoids[humanoid] = nil
	end
end

local function removeParticipant(player: Player, reason: string)
	if not participants[player] then
		return
	end
	participants[player] = nil
	setFrozen(player, false)
	if player.Parent then
		player:SetAttribute(RoundConfig.ATTR_IN_ROUND, false)
	end
	print(`[Runde] {player.Name} scheidet aus ({reason})`)
	if currentState == STATES.Playing then
		RoundAnalytics.playerEliminated(player, reason)
	end
end

local function returnToLobby(players: { Player })
	for _, player in players do
		setFrozen(player, false)
	end
	teleportPlayers(players, getSpawnPoints(RoundConfig.LOBBY_SPAWNS_PATH))
end

-- ===== Punkte über die bestehenden Tankstellen-Prompts =====

local function bindPrompt(prompt: Instance)
	if not prompt:IsA("ProximityPrompt") then
		return
	end
	if not SCORING_INTERACTIONS[prompt:GetAttribute("Interaction")] then
		return
	end
	prompt.Triggered:Connect(function(player: Player)
		if currentState ~= STATES.Playing or not participants[player] then
			return
		end
		local points = (player:GetAttribute(RoundConfig.ATTR_POINTS) or 0) + RoundConfig.POINTS_PER_INTERACTION
		player:SetAttribute(RoundConfig.ATTR_POINTS, points)
		print(`[Runde] {player.Name}: +{RoundConfig.POINTS_PER_INTERACTION} Punkt ({prompt:GetAttribute("Interaction")}), gesamt {points}`)
	end)
end

for _, prompt in CollectionService:GetTagged(PROMPT_TAG) do
	bindPrompt(prompt)
end
CollectionService:GetInstanceAddedSignal(PROMPT_TAG):Connect(bindPrompt)

-- ===== Spieler-Events =====

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		removeParticipant(player, "gestorben")
	end)
end

local function onPlayerAdded(player: Player)
	player:SetAttribute(RoundConfig.ATTR_IN_ROUND, false)
	player:SetAttribute(RoundConfig.ATTR_POINTS, 0)
	player:SetAttribute(RoundConfig.ATTR_REWARD, 0)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
Players.PlayerRemoving:Connect(function(player)
	removeParticipant(player, "Spiel verlassen")
end)

-- ===== Phasen =====

local function runIntermission(): boolean
	setState(STATES.Intermission)
	ReplicatedStorage:SetAttribute(RoundConfig.ATTR_MESSAGE, "")
	announce(PHASES.Lobby, "Lobby", `Nächste Runde in {RoundConfig.INTERMISSION_SECONDS} Sekunden`, 3)
	return runTimer(RoundConfig.INTERMISSION_SECONDS, function()
		return not enoughPlayers()
	end)
end

-- Gibt zurück, ob der Countdown durchlief, und wie viele Teilnehmer zu Beginn erfasst wurden.
local function runCountdown(): (boolean, number)
	setState(STATES.Countdown)

	-- Teilnehmer erfassen: alle Spieler, die jetzt im Spiel sind und leben
	participants = {}
	for _, player in Players:GetPlayers() do
		player:SetAttribute(RoundConfig.ATTR_POINTS, 0)
		player:SetAttribute(RoundConfig.ATTR_REWARD, 0)
		if isAlive(player) then
			participants[player] = true
			player:SetAttribute(RoundConfig.ATTR_IN_ROUND, true)
		end
	end

	local list = getParticipantList()
	print(`[Runde] {#list} Teilnehmer`)
	teleportPlayers(list, getSpawnPoints(RoundConfig.ARENA_SPAWNS_PATH))
	for _, player in list do
		setFrozen(player, true)
	end

	local completed = #list >= MIN_PLAYERS
		and runTimer(RoundConfig.COUNTDOWN_SECONDS, function()
			return activeCount() < MIN_PLAYERS
		end, function(timeLeft)
			announce(PHASES.Countdown, tostring(timeLeft), "Runde startet", 0.9)
		end)

	for _, player in getParticipantList() do
		setFrozen(player, false)
	end
	return completed, #list
end

-- Gibt den Grund für das Rundenende zurück: "timer" oder "no_survivors".
local function runPlaying(): string
	setState(STATES.Playing)
	RoundAnalytics.roundStarted(getParticipantList())
	announce(PHASES.InGame, "LOS!", `{RoundConfig.ROUND_SECONDS} Sekunden – Tanken & Einkaufen bringt Punkte`, 2.5)
	local completed = runTimer(RoundConfig.ROUND_SECONDS, function()
		return activeCount() == 0
	end, function(timeLeft)
		if timeLeft == RoundConfig.WARNING_SECONDS then
			announce(PHASES.InGame, `Noch {timeLeft} Sekunden!`, "", 2)
		end
	end)
	return if completed then "timer" else "no_survivors"
end

-- Gewinner: meiste Punkte unter den Überlebenden. Hat niemand gepunktet, gewinnen alle Überlebenden.
local function determineWinners(survivors: { Player }): ({ Player }, number)
	local bestPoints = 0
	for _, player in survivors do
		bestPoints = math.max(bestPoints, player:GetAttribute(RoundConfig.ATTR_POINTS) or 0)
	end
	local winners = {}
	for _, player in survivors do
		if (player:GetAttribute(RoundConfig.ATTR_POINTS) or 0) == bestPoints then
			table.insert(winners, player)
		end
	end
	return winners, bestPoints
end

local function runRoundEnd(endReason: string)
	local survivors = getParticipantList()
	local winners, bestPoints = determineWinners(survivors)
	local isWinner = {}
	for _, player in winners do
		isWinner[player] = true
	end

	-- Belohnungen (nur Server, über PlayerDataService)
	local coinsAwarded = 0
	for _, player in survivors do
		local reward = if isWinner[player] then RoundConfig.WIN_REWARD else RoundConfig.PARTICIPATION_REWARD
		coinsAwarded += reward
		PlayerDataService.addCoins(player, reward)
		player:SetAttribute(RoundConfig.ATTR_REWARD, reward)
		print(`[Runde] {player.Name}: {player:GetAttribute(RoundConfig.ATTR_POINTS) or 0} Punkte, +{reward} Coins`)
	end

	local message
	if #survivors == 0 then
		message = "Runde vorbei – niemand hat überlebt"
	else
		local names = {}
		for _, player in winners do
			table.insert(names, player.DisplayName)
		end
		local reason = if bestPoints > 0 then `{bestPoints} Punkte` else "überlebt"
		message = `Gewinner: {table.concat(names, ", ")} ({reason})`
	end
	ReplicatedStorage:SetAttribute(RoundConfig.ATTR_MESSAGE, message)
	setState(STATES.RoundEnd)
	print(`[Runde] {message}`)
	local rewardInfo = if #survivors > 0
		then `Gewinner +{RoundConfig.WIN_REWARD} Coins · Teilnehmer +{RoundConfig.PARTICIPATION_REWARD} Coins`
		else "Keine Belohnung"
	announce(PHASES.RoundEnd, message, rewardInfo, 5)

	RoundAnalytics.roundEnded({
		survivors = survivors,
		winners = if #survivors > 0 then winners else {},
		bestPoints = bestPoints,
		endReason = endReason,
		coinsAwarded = coinsAwarded,
	})

	returnToLobby(survivors)
	for _, player in survivors do
		player:SetAttribute(RoundConfig.ATTR_IN_ROUND, false)
	end
	participants = {}

	-- Map & Tankstelle für die nächste Runde zurücksetzen (Spieler sind schon in der Lobby)
	MapCleanup.cleanup()

	runTimer(RoundConfig.ROUND_END_SECONDS)
end

local function goToWaiting(skipAnnouncement: boolean?)
	if currentState ~= STATES.Waiting then
		setState(STATES.Waiting)
		if not skipAnnouncement then
			announce(PHASES.Lobby, "Warte auf Spieler", `Mindestens {MIN_PLAYERS} Spieler benötigt`, 3)
		end
	end
	setTimeLeft(0)
	while not enoughPlayers() do
		task.wait(1)
	end
end

-- ===== Game Loop =====

MapCleanup.init()
ReplicatedStorage:SetAttribute(RoundConfig.ATTR_MIN_PLAYERS, MIN_PLAYERS)
ReplicatedStorage:SetAttribute(RoundConfig.ATTR_MESSAGE, "")
setState(STATES.Waiting)

while true do
	if not enoughPlayers() then
		goToWaiting()
	end

	if runIntermission() then
		local countdownCompleted, countdownParticipants = runCountdown()
		if countdownCompleted then
			local endReason = runPlaying()
			runRoundEnd(endReason)
		else
			-- Abbruch im Countdown: Teilnehmer zurück in die Lobby, neu warten
			local list = getParticipantList()
			returnToLobby(list)
			for _, player in list do
				player:SetAttribute(RoundConfig.ATTR_IN_ROUND, false)
			end
			participants = {}
			print("[Runde] Countdown abgebrochen, zu wenige Spieler")
			RoundAnalytics.roundAborted("too_few_players", countdownParticipants)
			announce(PHASES.Lobby, "Runde abgebrochen", "Zu wenige Spieler – warte auf neue Spieler", 3)
			MapCleanup.cleanup()
			goToWaiting(true)
		end
	else
		goToWaiting()
	end
end

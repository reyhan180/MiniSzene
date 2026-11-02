-- Analytics-Logging für das Runden-System (Server).
--
-- Erfasst pro Runde: Dauer, Teilnehmerzahl, Überlebende, Gewinner, Ende-Grund, vergebene Coins.
-- Jedes Event wird als eine Zeile in die Konsole geschrieben:
--   [Analytics] <event> {JSON}
-- Zusätzlich bleibt ein Verlauf der letzten Runden im Speicher (getHistory / getSessionSummary).
-- Beim Herunterfahren des Servers wird eine Zusammenfassung der Sitzung geloggt.
--
-- Events: round_started, player_eliminated, round_ended, round_aborted, session_summary

local HttpService = game:GetService("HttpService")

local RoundAnalytics = {}

local LOG_PREFIX = "[Analytics]"
local MAX_HISTORY = 50

export type RoundSummary = {
	roundId: number,
	durationSeconds: number,
	participantCount: number,
	survivorCount: number,
	winners: { string },
	bestPoints: number,
	endReason: string,
	coinsAwarded: number,
}

type CurrentRound = {
	roundId: number,
	startClock: number,
	participantCount: number,
	eliminations: number,
}

local roundCounter = 0
local currentRound: CurrentRound? = nil
local history: { RoundSummary } = {}

local function playerNames(players: { Player }): { string }
	local names = {}
	for _, player in players do
		table.insert(names, player.Name)
	end
	return names
end

local function round1(value: number): number
	return math.round(value * 10) / 10
end

local function log(eventName: string, data: { [string]: any })
	data.event = eventName
	data.timestamp = os.time()
	local ok, json = pcall(HttpService.JSONEncode, HttpService, data)
	print(`{LOG_PREFIX} {eventName} {if ok then json else "<nicht serialisierbar>"}`)
end

-- Rundenstart (Beginn von "Playing"). Gibt die Runden-ID zurück.
function RoundAnalytics.roundStarted(participants: { Player }): number
	roundCounter += 1
	currentRound = {
		roundId = roundCounter,
		startClock = os.clock(),
		participantCount = #participants,
		eliminations = 0,
	}
	log("round_started", {
		roundId = roundCounter,
		participantCount = #participants,
		participants = playerNames(participants),
	})
	return roundCounter
end

function RoundAnalytics.playerEliminated(player: Player, reason: string)
	local round = currentRound
	if not round then
		return -- Ausscheiden außerhalb einer laufenden Runde wird nicht erfasst
	end
	round.eliminations += 1
	log("player_eliminated", {
		roundId = round.roundId,
		player = player.Name,
		reason = reason,
		secondsIntoRound = round1(os.clock() - round.startClock),
	})
end

function RoundAnalytics.roundEnded(result: {
	survivors: { Player },
	winners: { Player },
	bestPoints: number,
	endReason: string,
	coinsAwarded: number,
}): RoundSummary?
	local round = currentRound
	if not round then
		warn(`{LOG_PREFIX} roundEnded ohne laufende Runde`)
		return nil
	end
	currentRound = nil

	local summary: RoundSummary = {
		roundId = round.roundId,
		durationSeconds = round1(os.clock() - round.startClock),
		participantCount = round.participantCount,
		survivorCount = #result.survivors,
		winners = playerNames(result.winners),
		bestPoints = result.bestPoints,
		endReason = result.endReason,
		coinsAwarded = result.coinsAwarded,
	}
	log("round_ended", table.clone(summary))

	table.insert(history, summary)
	if #history > MAX_HISTORY then
		table.remove(history, 1)
	end
	return summary
end

-- Runde kam nicht zustande (z. B. zu wenige Spieler im Countdown)
function RoundAnalytics.roundAborted(reason: string, participantCount: number)
	log("round_aborted", { reason = reason, participantCount = participantCount })
end

function RoundAnalytics.getHistory(): { RoundSummary }
	return table.clone(history)
end

function RoundAnalytics.getSessionSummary(): { [string]: any }
	local totalDuration, totalParticipants = 0, 0
	local winsByPlayer: { [string]: number } = {}
	for _, summary in history do
		totalDuration += summary.durationSeconds
		totalParticipants += summary.participantCount
		for _, name in summary.winners do
			winsByPlayer[name] = (winsByPlayer[name] or 0) + 1
		end
	end
	local rounds = #history
	return {
		roundsPlayed = rounds,
		avgDurationSeconds = if rounds > 0 then round1(totalDuration / rounds) else 0,
		avgParticipants = if rounds > 0 then round1(totalParticipants / rounds) else 0,
		winsByPlayer = winsByPlayer,
	}
end

function RoundAnalytics.logSessionSummary()
	log("session_summary", RoundAnalytics.getSessionSummary())
end

game:BindToClose(function()
	RoundAnalytics.logSessionSummary()
end)

return RoundAnalytics

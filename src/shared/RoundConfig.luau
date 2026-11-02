-- Konfiguration des Runden-Systems (Server + Client).
-- Alle Zeiten in Sekunden.

local RoundConfig = {}

-- Spieleranzahl
RoundConfig.MIN_PLAYERS = 2
-- Im Studio-Solo-Test reicht 1 Spieler, damit der Loop allein testbar ist.
RoundConfig.MIN_PLAYERS_STUDIO = 1

-- Phasen-Dauer
RoundConfig.INTERMISSION_SECONDS = 15
RoundConfig.COUNTDOWN_SECONDS = 5
RoundConfig.ROUND_SECONDS = 60
RoundConfig.ROUND_END_SECONDS = 8

-- Belohnungen (Coins)
RoundConfig.WIN_REWARD = 50
RoundConfig.PARTICIPATION_REWARD = 10

-- Punkte pro Interaktion (Tanken / Einkaufen) während "Playing"
RoundConfig.POINTS_PER_INTERACTION = 1

-- Zustände der State Machine
RoundConfig.STATES = {
	Waiting = "Waiting",
	Intermission = "Intermission",
	Countdown = "Countdown",
	Playing = "Playing",
	RoundEnd = "RoundEnd",
}

-- Erlaubte Übergänge: [von] = { [nach] = true }
RoundConfig.TRANSITIONS = {
	Waiting = { Intermission = true },
	Intermission = { Countdown = true, Waiting = true },
	Countdown = { Playing = true, Waiting = true },
	Playing = { RoundEnd = true },
	RoundEnd = { Intermission = true, Waiting = true },
}

-- Namen der replizierten Attribute
-- An ReplicatedStorage:
RoundConfig.ATTR_STATE = "RoundState" -- string, einer der STATES
RoundConfig.ATTR_TIME_LEFT = "RoundTimeLeft" -- number, Sekunden
RoundConfig.ATTR_MIN_PLAYERS = "RoundMinPlayers" -- number
RoundConfig.ATTR_MESSAGE = "RoundMessage" -- string, Ergebnis am Rundenende
-- Am Player:
RoundConfig.ATTR_IN_ROUND = "InRound" -- boolean, aktiver Teilnehmer
RoundConfig.ATTR_POINTS = "RoundPoints" -- number, Punkte der aktuellen Runde
RoundConfig.ATTR_REWARD = "RoundReward" -- number, Coins der letzten Runde

-- Globale Ankündigungen (Server -> alle Clients)
-- RoundAnnouncement:FireAllClients(phase, title, subtitle, duration)
RoundConfig.ANNOUNCEMENT_EVENT = "RoundAnnouncement"
RoundConfig.PHASES = {
	Lobby = "Lobby", -- Waiting / Intermission / Abbruch
	Countdown = "Countdown", -- Countdown-Zahlen
	InGame = "InGame", -- Rundenstart, Restzeit-Warnung
	RoundEnd = "RoundEnd", -- Siegesnachricht
}
RoundConfig.WARNING_SECONDS = 10 -- Ankündigung "Noch 10 Sekunden!"

-- Startpunkte in Workspace (in Studio angelegt, unsichtbare Parts)
RoundConfig.ARENA_SPAWNS_PATH = { "GamePlay", "RoundSpawns" }
RoundConfig.LOBBY_SPAWNS_PATH = { "GamePlay", "LobbySpawns" }

return RoundConfig

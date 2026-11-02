-- Zentrales Logging für Server und Client.
--
-- Level: DEBUG < INFO < WARN
--   Studio: DEBUG (alles sichtbar)
--   Live:   INFO  (keine Detail-Logs wie einzelne Punkte, Autosaves, Cleanup)
-- Zur Laufzeit überschreibbar über das Attribut "LogLevel" an ReplicatedStorage ("DEBUG"/"INFO"/"WARN").
--
-- Verwendung:
--   local log = Log.new("Runde")
--   log.info("Waiting -> Intermission")   --> [Runde] Waiting -> Intermission
--
-- Analytics-Zeilen ([Analytics]) laufen bewusst NICHT hierüber und sind immer sichtbar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LEVELS = {
	DEBUG = 1,
	INFO = 2,
	WARN = 3,
}
local DEFAULT_LEVEL = if RunService:IsStudio() then "DEBUG" else "INFO"
local OVERRIDE_ATTRIBUTE = "LogLevel"

export type Logger = {
	debug: (message: string) -> (),
	info: (message: string) -> (),
	warn: (message: string) -> (),
}

local Log = {}
Log.LEVELS = LEVELS

local function currentLevel(): number
	local override = ReplicatedStorage:GetAttribute(OVERRIDE_ATTRIBUTE)
	return LEVELS[override] or LEVELS[DEFAULT_LEVEL]
end

function Log.new(tag: string): Logger
	local prefix = `[{tag}]`
	return {
		debug = function(message: string)
			if currentLevel() <= LEVELS.DEBUG then
				print(prefix, message)
			end
		end,
		info = function(message: string)
			if currentLevel() <= LEVELS.INFO then
				print(prefix, message)
			end
		end,
		warn = function(message: string)
			warn(prefix, message)
		end,
	}
end

return Log

-- Sound-Effekte (kostenlose Audio aus dem Roblox Creator Store / Toolbox).
-- Abgespielt nur lokal auf dem Client (FeedbackFX.client.luau).
-- Zum Austauschen nur die ID ändern.

export type SoundInfo = {
	id: string,
	volume: number,
	playbackSpeed: number?,
}

local SoundConfig = {}

SoundConfig.SOUNDS = {
	-- Shop
	PurchaseSuccess = { id = "rbxassetid://133570405319995", volume = 0.6 }, -- "Coin Clinking Sound"
	PurchaseFail = { id = "rbxassetid://87519554692663", volume = 0.5 }, -- "ui-simple-negative-error"
	-- Runde
	Point = { id = "rbxassetid://607665037", volume = 0.6 }, -- "coins_get"
	CountdownTick = { id = "rbxassetid://117751546358455", volume = 0.5 }, -- "Countdown beep"
	RoundStart = { id = "rbxassetid://117751546358455", volume = 0.6, playbackSpeed = 1.5 }, -- gleicher Beep, höher
	Victory = { id = "rbxassetid://1836860398", volume = 0.5 }, -- "Winning Spirit" (APMOfficial)
	Reward = { id = "rbxassetid://133570405319995", volume = 0.5, playbackSpeed = 1.2 }, -- Teilnahme-Coins
} :: { [string]: SoundInfo }

return SoundConfig

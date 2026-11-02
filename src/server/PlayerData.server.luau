-- Startet das Laden/Speichern der Spielerdaten (Coins + Inventar).
-- Logik siehe PlayerDataService.luau.

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

PlayerDataService.start()

-- Client-Start (Rojo: init.client.luau, Container für die übrigen Client-Skripte).
-- Erzwingt das Querformat auf Mobilgeräten (Entscheidung Praxisprojekt 04).
-- Zusätzlich ist StarterGui.ScreenOrientation in Studio auf LandscapeSensor gesetzt.

local Players = game:GetService("Players")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
playerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor

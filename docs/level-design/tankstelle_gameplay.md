# Praxisprojekt 01 – Gas Station Gameplay (Task 04)

Stand: 01.11.2026 | Task 04 abgeschlossen | Grundlage: `tankstelle_blockout.md` (Task 02), `tankstelle_environment.md` (Task 03) | Task: `tasks/completed/task_04.md`

## 1. Überblick
Die Tankstellen-Map hat jetzt Gameplay-Logik: einen fest konfigurierten Spawn, eine rundum gesicherte Kartengrenze, interaktive ProximityPrompts an Tresen und Zapfsäulen sowie einen Performance- und Kollisions-Feinschliff. Jede Änderung wurde im Playtest in Roblox Studio geprüft.

## 2. Spawn

| Eigenschaft | Wert |
|---|---|
| Pfad | `Workspace.GamePlay.Spawns.SpawnLocation` |
| Position | (66.5, 1.22, −23.5), Nordseite hinter dem Shop |
| Orientierung | (0, 90, 0): Spieler schauen beim Spawn nach Westen zum Ausgang des Gangs (Parkplatz/Insel), nicht mehr auf den Zaun |
| `Neutral` / `Duration` | `true` / `0` (kein ForceField) |
| `Enabled` / `AllowTeamChangeOnTouch` | `true` / `false` |
| Sichtbarkeit von der Straße | 0/60 |

Es gibt genau eine SpawnLocation und keine Teams.

## 3. Kartengrenzen
Begehbare Fläche: x −49.5 bis 101.5, z −26.5 bis 123.5 (Bodenplatte, Baseplate und Straße). Alle Teile liegen unter `Props/Begrenzung`.

| Kante | Sichtbar | Unsichtbare Wand |
|---|---|---|
| Nord | Maschendrahtzaun über die ganze Kante (`ZaunNord`) | `ZaunNord/UnsichtbareWand` |
| Ost, Gang hinter dem Shop | Zaunstück (`ZaunNord/GitterOst`) | `ZaunNord/UnsichtbareWandOst` |
| Ost, gesamt | Leitplanke am Straßenende (`LeitplankeOst`) | `Waende/UnsichtbareWandOstGesamt` |
| West | Leitplanke am Straßenende (`LeitplankeWest`) | `Waende/UnsichtbareWandWest` |
| Süd | – (Straßenrand) | `Waende/UnsichtbareWandSued` |

- Unsichtbare Wände: 30 Studs hoch, 0.5 dick, `Transparency = 1`, `CanCollide = true`, `CanQuery = false` (keine Auswirkung auf Raycasts und Sichtachsen), `CastShadow = false`. Die Wände überlappen an den Ecken.
- Leitplanken: Metallpfosten alle 3 Studs, Planke, orangefarbener Neon-Reflektorstreifen.

**Kollisionstest im Playtest** (Figur läuft mit 8 Sprüngen gegen die Kante):

| Kante | Endposition | Kante bei | Ergebnis |
|---|---|---|---|
| Nord | z = −25.98 | −26.5 | gehalten |
| Ost (Gang) | x = 99.96 | 100.5 | gehalten |
| West (Wiese) | x = −48.98 | −49.5 | gehalten |
| West (Straßenende) | x = −48.99 | −49.5 | gehalten |
| Süd (Straße) | z = 122.98 | 123.5 | gehalten |
| Ost (Wiese) | x = 100.97 | 101.5 | gehalten |
| Ost (Straßenende) | x = 100.98 | 101.5 | gehalten |

## 4. Interaktionen (ProximityPrompts)

| Prompt | Ort | ActionText / ObjectText | Halten | Reichweite | Line of Sight |
|---|---|---|---|---|---|
| `EinkaufenPrompt` | `Props/Shop/Innenraum/Tresen/Platte/PromptAttachment` (Kundenseite) | Einkaufen / NORDSTERN Shop | 0 s | 8 | an |
| `TankenPrompt` | `Props/Gas01/PromptAttachment` | Tanken / Zapfsäule 1 | 1 s | 8 | aus |
| `TankenPrompt` | `Props/Gas02/PromptAttachment` | Tanken / Zapfsäule 2 | 1 s | 8 | aus |

- Alle Prompts nutzen die Taste E, das Tag `GasStationPrompt` und das Attribut `Interaction` („Einkaufen“ / „Tanken“).
- Logik: `src/server/GasStationInteractions.server.luau`. Das Skript bindet alle getaggten Prompts, auch später hinzugefügte (`GetInstanceAddedSignal`).
  - **Tanken:** Prompt 3 s gesperrt, die Neon-Displays der Säule leuchten grün, Spieler-Attribut `Tankvorgaenge` +1.
  - **Einkaufen:** Kassen-Display leuchtet 1 s grün, Spieler-Attribut `Einkaeufe` +1.
- Playtest: Beide Prompts werden angezeigt und lösen aus, auch mit echter Tastatureingabe (E 1.5 s gehalten). Das Display wechselt während des Tankens auf Grün und danach zurück, die Attribute zählen hoch. Die Konsole zeigt keine Fehler aus dem Skript.
- Hinweis: Prompts erscheinen nur, wenn sie im Kamerabild liegen. Steht die Kamera zwischen Säule und Figur, sieht der Spieler den Prompt erst nach Drehen der Kamera. Das ist Standardverhalten von Roblox.

## 5. Performance & Collision Polish

| Prüfung | Ergebnis |
|---|---|
| Parts unter `Environment` | 196, alle `Anchored = true` (keine Korrektur nötig) |
| `CanCollide = false` | 76 Parts: alle Deko-Kleinteile (Displays, Leuchten, Ölflecken, Waren, Gasflaschen, Lichter am Auto, Fahrbahn- und Parkmarkierungen …). Neu umgestellt: `Parkplatz/Markierung01–03` |
| `CastShadow = false` | 88 Parts. Neu umgestellt: Parkmarkierungen, Gasflaschen, `Mülleimer01` und flache Bodenplatten (`Bodenplatte`, `MainRoad`, `VorplatzBoden`, `ParkplatzBoden`, `Fundament`, `ShopFloor`) |
| Unverändert kollidierbar | Deckung (`Mauer01`, `Kiste01`, Auto, Regale, Tresen), Gebäude, Zapfsäulen, Säulen, Laternenmasten, Zäune, Wände |
| Lichtquellen | 10 (Budget 15), Shadows unverändert an |
| Sichtachsen nach dem Polish (60 Straßenpunkte) | Gas01 4 · Gas02 6 · Tür 25 · Shop Mitte 15 · Shop hinten 9 · Regale 0 · Tresen 0 · Mauer 0 · Kiste 1 · Freifläche 29 · Auto 35 · Spawn 0, identisch zu Task 03 |

## 6. Rojo-Projektstruktur
- **Problem:** `default.project.json` mappte `src/client` direkt auf `StarterPlayerScripts`. Weil der Ordner ein `init.client.luau` enthält, hat Rojo daraus ein LocalScript namens `StarterPlayerScripts` gemacht. Es lag in Studio neben dem echten Container.
- **Fix:** `src/client` wird jetzt als Unterordner gemappt (`StarterPlayerScripts/Client`). Das falsche LocalScript wurde in Studio entfernt. `rojo build` (Rojo 7.7.1) erzeugt die erwartete Struktur: Container `StarterPlayerScripts` mit LocalScript `Client`.
- **Wirkung im Playtest:** `PlayerScripts` enthält jetzt neben `Client` auch das Standardskript `RbxCharacterSounds`, das vorher fehlte. Die Kamera folgt der Figur.

## 7. Bekannte Punkte
- Konsole: `rbxassetid://203785492 failed due to: Asset type does not match requested type`. Das Asset wird im Place nicht referenziert, die Quelle ist vermutlich ein Plugin oder CoreScript. Für das Spiel ist die Meldung ohne Auswirkung.
- Die Place-Datei (Map, Prompts, Wände) wird nicht über Git versioniert. Sie muss in Roblox Studio gespeichert bzw. veröffentlicht werden. Git enthält `src/`, `docs/`, `tasks/` und `default.project.json`.
- Backlog aus Task 03: Zapfsäulen verbreitern, Schatten bei Shop-Innenlicht/Laternen abschalten, Eistruhe, Einkaufswagen, Reifenstapel, schiefes Straßenschild.

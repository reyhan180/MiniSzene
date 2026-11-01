# Task 04 – Gameplay Integration, Interaction & Final Polish

* **Status:** Completed (01.11.2026)
* **Projekt:** Praxisprojekt 01 – Gas Station Environment
* **Verantwortlich:** Junior Developer / AI Agent
* **Source of Truth:** Repository (`src/`, `docs/`, `tasks/`)

---

## 1. Zielstellung
In dieser finalen Phase von Projekt 01 wird die Tankstellen-Map mit Gameplay-Logik angereichert. Dazu gehören interaktive Elemente (ProximityPrompts), Trigger-Zonen, die Feinabstimmung von Kollisionen und die Performance-Optimierung für einen sauberen Release-Kandidaten.

---

## 2. Aufgabenstellung (Acceptance Criteria)

- [x] 1. **Spawn & Map Boundaries:**
  - SpawnLocation auf der geschützten Nordseite final konfigurieren (Neutral = true, Duration = 0).
  - Invisible Walls und Zäune am Kartenrand auf korrekte Kollision prüfen.

- [x] 2. **Interaktive Prompts (Gameplay):**
  - `ProximityPrompt` am Shop-Tresen einrichten (*„Einkaufen“*).
  - `ProximityPrompt` an den Zapfsäulen einrichten (*„Tanken“*).

- [x] 3. **Performance & Collision Polish:**
  - Alle Parts unter `Environment` auf `Anchored = true` validieren.
  - Nicht-kollidierbare Deko-Parts auf `CanCollide = false` stellen.
  - Licht-Schattenwurf (CastShadow) bei kleinen Deko-Parts deaktivieren.

- [x] 4. **Doku & Final Commit:**
  - Ergebnisse in `docs/level-design/tankstelle_gameplay.md` dokumentieren.
  - Task auf `Completed` setzen, nach `tasks/completed/task_04.md` verschieben und pushen.

---

## 3. Agent Execution Log & Results
*(Wird während der Bearbeitung ergänzt)*

### Punkt 1 – Spawn & Map Boundaries (01.11.2026)
- `Workspace.GamePlay.Spawns.SpawnLocation` bei (66.5, −23.5) hinter dem Shop: `Neutral = true`, `Duration = 0`, `Enabled = true`, `AllowTeamChangeOnTouch = false`, `Anchored = true`. Es gibt genau eine SpawnLocation und keine Teams.
- Playtest: Der Spieler erscheint am Spawn, ohne ForceField (Duration 0 greift).
- Grenzen (`Props/Begrenzung/ZaunNord`): Gitter, Pfosten und unsichtbare Wände sind `CanCollide = true`. Die unsichtbaren Wände sind 30 Studs hoch, `Transparency = 1`, `CanQuery = false`.
- Kollisionstest im Playtest: Figur läuft mit wiederholtem Springen gegen die Wände. Sie stoppt an der Nordwand bei z = −25.98 (Kante −26.5) und an der Ostwand bei x = 99.96 (Kante 100.5). Kein Durchkommen.
- Hinweis: Gesichert sind nur die Nordkante und das Ostende des Gangs hinter dem Shop. West-, Süd- und restliche Ostkante (u. a. Straßenenden) sind offen, dort kann man von der Karte fallen.

### Punkt 2 – ProximityPrompts (01.11.2026)
| Prompt | Ort | ActionText / ObjectText | HoldDuration | Reichweite | Line of Sight |
|---|---|---|---|---|---|
| `EinkaufenPrompt` | `Props/Shop/Innenraum/Tresen/Platte/PromptAttachment` (Kundenseite) | Einkaufen / NORDSTERN Shop | 0 s | 8 | an |
| `TankenPrompt` | `Props/Gas01/PromptAttachment` | Tanken / Zapfsäule 1 | 1 s | 8 | aus |
| `TankenPrompt` | `Props/Gas02/PromptAttachment` | Tanken / Zapfsäule 2 | 1 s | 8 | aus |

- Alle Prompts haben das Tag `GasStationPrompt` und das Attribut `Interaction` („Einkaufen“ bzw. „Tanken“), Taste E.
- Logik in `src/server/GasStationInteractions.server.luau`, in Studio gespiegelt nach `ServerScriptService.ServerScriptService.GasStationInteractions` (Rojo lief nicht).
  - Tanken: Prompt 3 s gesperrt, die Displays der Säule leuchten grün, Spieler-Attribut `Tankvorgaenge` +1.
  - Einkaufen: Kassen-Display leuchtet 1 s grün, Spieler-Attribut `Einkaeufe` +1.
- Playtest: Beide Prompts werden angezeigt und lösen aus. Konsole: `[Tankstelle] … tankt an Gas01`, `[Tankstelle] … kauft im Shop ein`, Attribute danach je 1. Keine Fehler aus dem Skript.

### Gefundene Probleme (außerhalb von Punkt 1–2)
- **Rojo-Mapping:** `src/client/init.client.luau` ist direkt auf `StarterPlayerScripts` gemappt. Dadurch hat Rojo ein LocalScript namens `StarterPlayerScripts` neben dem echten Container angelegt. Fix erfordert eine Änderung an `default.project.json`, laut AGENTS.md nur nach Rücksprache. → Freigegeben und behoben, siehe unten.
- Konsole: `rbxassetid://203785492 failed due to: Asset type does not match requested type` (3×). Stammt nicht aus den neuen Skripten. → Im Place nicht referenziert, vermutlich Plugin/CoreScript.

### Rojo-Fix (01.11.2026, nach Freigabe)
- `default.project.json`: `StarterPlayerScripts` → `Client` → `$path: src/client`. `rojo build` (7.7.1) erzeugt jetzt Container `StarterPlayerScripts` mit LocalScript `Client`.
- In Studio: das falsche LocalScript `StarterPlayer.StarterPlayerScripts` gelöscht (Inhalt war identisch mit `src/client/init.client.luau`).
- Playtest: `PlayerScripts` enthält jetzt `Client` und `RbxCharacterSounds` (fehlte vorher). Die Kamera folgt der Figur.
- **Korrektur meiner früheren Diagnose:** Dass Prompts im ersten Test nicht erschienen, lag nicht an einem fehlenden `PlayerModule`. Die Kamera stand in Laufrichtung vor der Figur, der Prompt lag damit außerhalb des Bildes. Ein `PlayerModule` ist in `PlayerScripts` aus dem Plugin-Kontext auch nach dem Fix nicht sichtbar. Kamera und Steuerung funktionieren trotzdem.

### Kartengrenzen rundum (01.11.2026)
- Neu: `Props/Begrenzung/Waende` mit unsichtbaren Wänden West, Süd und Ost über die gesamte Länge (30 Studs hoch, `CanQuery = false`), dazu `LeitplankeWest`/`LeitplankeOst` an den Straßenenden.
- Kollisionstest im Playtest an 5 weiteren Stellen (West Wiese/Straße, Süd Straße, Ost Wiese/Straße), jeweils mit 8 Sprüngen: Alle Kanten halten (Endposition ca. 0.5 Studs vor der Kante).
- Spawn zusätzlich um 90° gedreht: Spieler schauen beim Spawn nach Westen zum Ausgang des Gangs statt auf den Zaun.

### Punkt 3 – Performance & Collision Polish (01.11.2026)
- 196 Parts unter `Environment` geprüft, alle `Anchored = true`.
- `CanCollide = false` neu für `Parkplatz/Markierung01–03`. Alle übrigen Deko-Kleinteile waren bereits nicht kollidierbar (insgesamt 76).
- `CastShadow = false` neu für 14 Parts: Parkmarkierungen, Gasflaschen, `Mülleimer01` und flache Bodenplatten (insgesamt 88).
- Deckungs- und Strukturteile bewusst unverändert. Sichtachsen danach identisch zu Task 03.
- Playtest mit echter Tastatureingabe: Taste E an Gas02 1.5 s gehalten → Display grün, danach zurück, `Tankvorgaenge` = 1.

### Punkt 4 – Doku & Abschluss
- `docs/level-design/tankstelle_gameplay.md` erstellt.
- Task nach `tasks/completed/task_04.md` verschoben, Commit und Push nach ausdrücklicher Freigabe.
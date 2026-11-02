# Praxisprojekt 02 – Runden-System (Game Loop & State Machine)

Stand: 02.11.2026 | Task: `tasks/completed/task_02P2.md` | Baut auf: `systems_overview.md` (DataStore, Shop)

## 1. Überblick
Ein Server-Skript führt das Spiel in einer Endlosschleife durch feste Phasen. Teilnehmer werden von der Lobby (Gang hinter dem Shop) zur Tankstelle teleportiert, sammeln 60 s lang Punkte durch Tanken und Einkaufen und bekommen am Ende Coins. Clients zeigen den Zustand nur an.

## 2. Zustände & Übergänge

```
            genug Spieler                    15 s                 5 s                 60 s / alle raus
 Waiting ────────────────► Intermission ──────────► Countdown ──────────► Playing ──────────────────► RoundEnd
    ▲                         │    ▲                    │                                              │
    │   zu wenige Spieler     │    │                    │ zu wenige Teilnehmer                         │ 8 s
    ├─────────────────────────┘    └────────────────────┼──────────────────────────────────────────────┤ (genug Spieler)
    │                                                   │                                              │
    └───────────────────────────────────────────────────┴──────────────────────────────────────────────┘
                                                                                          (zu wenige Spieler)
```

| Zustand | Was passiert | Weiter nach |
|---|---|---|
| `Waiting` | Wartet, bis `MIN_PLAYERS` Spieler im Spiel sind | `Intermission` |
| `Intermission` | 15 s Pause in der Lobby | `Countdown`, oder `Waiting` bei zu wenigen Spielern |
| `Countdown` | Teilnehmer werden erfasst (alle lebenden Spieler), Punkte auf 0 gesetzt, zur Tankstelle teleportiert und 5 s eingefroren | `Playing`, oder `Waiting` (Teilnehmer zurück in die Lobby) |
| `Playing` | 60 s. Tanken/Einkaufen = 1 Punkt. Endet früher, wenn kein Teilnehmer mehr aktiv ist | `RoundEnd` |
| `RoundEnd` | Gewinner bestimmen, Coins vergeben, Überlebende zurück in die Lobby, 8 s Ergebnisanzeige | `Intermission` oder `Waiting` |

Erlaubte Übergänge stehen in `RoundConfig.TRANSITIONS`. `setState` verhindert jeden anderen Übergang und schreibt eine Warnung (`[Runde] Ungültiger Übergang … verhindert`).

## 3. Dateien

| Datei (`src/`) | Ziel in Studio | Aufgabe |
|---|---|---|
| `shared/RoundConfig.luau` | `ReplicatedStorage.RoundConfig` | Zeiten, Belohnungen, Zustände, Übergänge, Attributnamen |
| `server/RoundService.server.luau` | `ServerScriptService.ServerScriptService.RoundService` | State Machine, Game Loop, Teleport, Punkte, Belohnung |
| `client/RoundUI.client.luau` | `StarterPlayerScripts.Client.RoundUI` | Statusanzeige `RoundGui` oben in der Mitte |

In Studio angelegt (nicht in `src/`, da Workspace nicht über Rojo läuft):

| Instanz | Inhalt |
|---|---|
| `Workspace.GamePlay.RoundSpawns` | `Start01`–`Start08`, unsichtbare Parts rund um die Zapfsäuleninsel, Blick zu den Zapfsäulen |
| `Workspace.GamePlay.LobbySpawns` | `Lobby01`–`Lobby07`, im Gang hinter dem Shop entlang x = 54.5–78.5, z = −23.5, Blick nach Westen |

Alle Marker: `Anchored`, `Transparency = 1`, `CanCollide/CanQuery/CanTouch = false`. Die Positionen wurden per Raycast (Boden) und Overlap-Check (keine Hindernisse) geprüft.

## 4. Konfiguration (`RoundConfig`)

| Konstante | Wert |
|---|---|
| `MIN_PLAYERS` | 2 (live) |
| `MIN_PLAYERS_STUDIO` | 1 (nur in Studio, damit der Loop allein testbar ist) |
| `INTERMISSION_SECONDS` / `COUNTDOWN_SECONDS` / `ROUND_SECONDS` / `ROUND_END_SECONDS` | 15 / 5 / 60 / 8 |
| `WIN_REWARD` / `PARTICIPATION_REWARD` | 50 / 10 Coins |
| `POINTS_PER_INTERACTION` | 1 |

## 5. Regeln
- **Teilnehmer:** Alle Spieler, die beim Start des Countdowns leben. Wer später beitritt, ist Zuschauer bis zur nächsten Runde.
- **Ausscheiden:** Tod (`Humanoid.Died`) oder Verlassen des Spiels. Wer stirbt, respawnt am normalen Spawn (= Lobby).
- **Punkte:** Der Server hört auf die bestehenden Prompts (Tag `GasStationPrompt`, `Interaction` = `Tanken`/`Einkaufen`). Nur während `Playing` und nur für aktive Teilnehmer gibt es Punkte. Die Tankstellen-Logik (`GasStationInteractions`) bleibt unverändert, dadurch gilt die 3-s-Sperre beim Tanken weiter.
- **Gewinner:** Meiste Punkte unter den Überlebenden. Bei Gleichstand gewinnen alle Punktgleichen. Hat niemand gepunktet, gewinnen alle Überlebenden („überlebt“).
- **Belohnung:** Gewinner +50 Coins, andere Überlebende +10, über `PlayerDataService.addCoins` (wird mit gespeichert). Ausgeschiedene bekommen nichts.

## 6. Replizierte Attribute (nur lesend für Clients)

| Wo | Attribut | Typ |
|---|---|---|
| `ReplicatedStorage` | `RoundState` | string (Zustand) |
| `ReplicatedStorage` | `RoundTimeLeft` | number (Sekunden) |
| `ReplicatedStorage` | `RoundMinPlayers` | number |
| `ReplicatedStorage` | `RoundMessage` | string (Ergebnistext am Rundenende) |
| `Player` | `InRound` | boolean (aktiver Teilnehmer) |
| `Player` | `RoundPoints` | number |
| `Player` | `RoundReward` | number (Coins der letzten Runde) |

## 7. Status-UI (`RoundGui`)
Box oben in der Mitte mit Titel und Detailzeile. `DisplayOrder = -1`, liegt also unter der `ShopGui`.

| Zustand | Titel | Detail |
|---|---|---|
| Waiting | Warte auf Spieler (1/2) | Die Runde startet, sobald genug Spieler da sind |
| Intermission | Nächste Runde in 0:15 | Lobby – Tanken & Einkaufen bringt in der Runde Punkte |
| Countdown | Runde startet in 5 (gelb) | Mach dich bereit! / Du bist in der nächsten Runde dabei |
| Playing | Runde läuft – 0:43 | Deine Punkte: 2 / Zuschauer – … |
| RoundEnd | Gewinner: … (2 Punkte) (grün) | Deine Punkte: 2 \| +50 Coins / Keine Belohnung in dieser Runde |

## 8. Testergebnisse (02.11.2026, Studio-Playtest, 1 Spieler, `MIN_PLAYERS_STUDIO = 1`)

| Test | Ergebnis |
|---|---|
| Start | `Start -> Waiting -> Intermission`, UI „Nächste Runde in 0:15“ |
| Countdown | Teleport zu `Start01` (22, 43), WalkSpeed/JumpHeight = 0, `InRound = true`, UI „Runde startet in 4“ |
| Rundenstart | WalkSpeed wieder 16. Zur Zapfsäule gelaufen, 2× Taste E gehalten → `+1 Punkt (Tanken)` ×2, UI „Deine Punkte: 2“ |
| Rundenende (Timer) | „Gewinner: devirl_2 (2 Punkte)“, Coins 15 → 65, Teleport zu `Lobby01`, `InRound = false` |
| Loop | `RoundEnd -> Intermission` automatisch |
| Einkaufen in der Pause | Tankstellen-Logik läuft (`Einkaeufe = 1`), aber **kein** Rundenpunkt |
| Neue Runde | `RoundPoints` beim Countdown auf 0 zurückgesetzt |
| Tod während `Playing` | „scheidet aus (gestorben)“, Runde endet nach 1 s, „niemand hat überlebt“, keine Coins |

Keine Skriptfehler in der Konsole.

**Nicht getestet** (braucht einen Local Server mit 2 Spielern, über das MCP nicht startbar):
- `MIN_PLAYERS = 2` live: Waiting „1/2“ → Start beim zweiten Spieler
- Spieler verlässt das Spiel im Countdown → Abbruch, zurück zu `Waiting`
- Spieler tritt während `Playing` bei → Zuschauer, nächste Runde Teilnehmer
- Zwei Teilnehmer: Gewinner 50 / anderer 10 Coins, Gleichstand
- Der Schutz vor ungültigen Übergängen ist im Code vorhanden, wurde im normalen Ablauf aber nie ausgelöst.

# Praxisprojekt 03 – Map-Cleanup, Status-Broadcasts & Analytics

Stand: 02.11.2026 | Task: `tasks/completed/task_02P3.md` | Baut auf: `round_system.md`, `systems_overview.md`

## 1. Überblick
Das Runden-System (`RoundService`) hat drei Erweiterungen bekommen:

| System | Datei | Aufgabe |
|---|---|---|
| Map- & State-Cleanup | `src/server/MapCleanup.luau` | Nach jeder Runde gespawnte Objekte entfernen und die Tankstelle zurücksetzen |
| Status-Broadcasts | `src/shared/RoundAnnouncement.model.json`, `src/client/AnnouncementUI.client.luau` | Bildschirmfüllende Ankündigungen der Rundenphasen für alle Spieler |
| Analytics | `src/server/RoundAnalytics.luau` | Rundendauer, Teilnehmer, Gewinner usw. als strukturierte Log-Zeilen |

```
RoundService (State Machine)
 ├─ announce(...)            -> RoundAnnouncement:FireAllClients -> AnnouncementUI (Banner)
 ├─ RoundAnalytics.*         -> [Analytics] <event> {JSON} in der Server-Konsole
 └─ MapCleanup.cleanup()     -> RoundObjects / Tag RoundSpawned / Prompts / Displays
```

## 2. Map- & State-Cleanup (`MapCleanup`)

### API
| Funktion | Beschreibung |
|---|---|
| `init()` | Einmal beim Serverstart (von `RoundService` aufgerufen). Erfasst den Ausgangszustand und legt `Workspace.RoundObjects` an |
| `registerSpawned(obj, parent?)` | Markiert ein Objekt mit dem Tag `RoundSpawned`. Ohne Parent landet es in `Workspace.RoundObjects` |
| `cleanup()` | Räumt auf und gibt `{ removedObjects, promptsReset, displaysReset }` zurück |

### Was `cleanup()` macht
1. **Entfernt:**
   - alle Kinder von `Workspace.RoundObjects`
   - alle Instanzen mit dem Tag `RoundSpawned`, egal wo sie liegen
   - lose `Tool`/`Accessory` direkt in Workspace (fallen gelassene Gegenstände)
2. **Setzt zurück** (auf den Zustand bei `init()`):
   - `Enabled` aller Prompts mit Tag `GasStationPrompt` (3 Stück: 2× Tanken, 1× Einkaufen)
   - Farbe der Displays: `ZapfsäulenDetails/*_Display*` (4) und `KassenDisplay` (1)
3. Loggt `[Cleanup] X Objekte entfernt, Y Prompts und Z Displays zurückgesetzt`.

### Wann
- In `RoundEnd`, **nachdem** die Überlebenden in die Lobby teleportiert wurden.
- Nach einem Abbruch im Countdown.

### Bewusst nicht zurückgesetzt
- Die Sitzungszähler `Tankvorgaenge`/`Einkaeufe` am Player (Statistik, keine Rundendaten).
- `RoundPoints` wird nicht vom Cleanup genullt, sondern beim nächsten Countdown. So bleibt der Punktestand während `RoundEnd` sichtbar.

### Regel für neue Systeme
Alles, was während einer Runde in die Welt gespawnt wird (Items, Props, Effekte), **muss** über `MapCleanup.registerSpawned(obj)` angemeldet werden. Sonst bleibt es nach der Runde liegen.

## 3. Status-Broadcasts

### RemoteEvent
- `ReplicatedStorage.RoundAnnouncement` (Rojo: `RoundAnnouncement.model.json`, Fallback: `RoundService` legt es an).
- Nur Server → Client: `FireAllClients(phase, title, subtitle, duration)`. Der Server hört nicht auf `OnServerEvent`, Clients können nichts auslösen.

### Phasen (`RoundConfig.PHASES`)
| Phase | Ausgelöst bei | Titel / Untertitel | Dauer |
|---|---|---|---|
| `Lobby` | Start der Intermission | „Lobby“ / „Nächste Runde in 15 Sekunden“ | 3 s |
| `Lobby` | Wechsel nach Waiting | „Warte auf Spieler“ / „Mindestens N Spieler benötigt“ | 3 s |
| `Lobby` | Abbruch im Countdown | „Runde abgebrochen“ / „Zu wenige Spieler – warte auf neue Spieler“ | 3 s |
| `Countdown` | jede Countdown-Sekunde | „5“ … „1“ / „Runde startet“ | 0.9 s |
| `InGame` | Start von Playing | „LOS!“ / „60 Sekunden – Tanken & Einkaufen bringt Punkte“ | 2.5 s |
| `InGame` | 10 s Restzeit (`WARNING_SECONDS`) | „Noch 10 Sekunden!“ | 2 s |
| `RoundEnd` | Rundenende | Siegesnachricht / Belohnungen bzw. „Keine Belohnung“ | 5 s |

### Client (`AnnouncementUI`)
- `ScreenGui` `AnnouncementGui`: `DisplayOrder = 10` (über `RoundGui` und `ShopGui`), `IgnoreGuiInset = true`.
- Abgedunkelter Vollbild-Hintergrund (55 % Transparenz) mit Phasen-Label, großem Titel (max. 110 px) und Untertitel. Farbe je Phase: Lobby blau, Countdown gelb, InGame grün, RoundEnd gold.
- Countdown-Zahlen ohne Abdunklung, damit die Sicht frei bleibt.
- Einblenden 0.2 s, Ausblenden 0.4 s. Eine neue Ankündigung ersetzt die laufende sofort.
- `Interactable = false`: Klicks gehen durch das Banner (z. B. Shop-Button bleibt bedienbar).
- Die dauerhafte Statusleiste `RoundGui` (Zustand + Restzeit oben) bleibt unverändert, das Banner ergänzt sie.

## 4. Analytics (`RoundAnalytics`)

Eigenes ModuleScript statt Roblox-`AnalyticsService`. Grund: funktioniert auch in Studio ohne veröffentlichtes Spiel und braucht keinen Spieler-Kontext für Runden-Metriken.

### Log-Format
```
[Analytics] <event> {JSON}
```
Jedes Event enthält `event` und `timestamp` (Unix-Zeit).

### Events
| Event | Wann | Felder |
|---|---|---|
| `round_started` | Start von Playing | `roundId`, `participantCount`, `participants` |
| `player_eliminated` | Tod/Verlassen während Playing | `roundId`, `player`, `reason` (gestorben / Spiel verlassen), `secondsIntoRound` |
| `round_ended` | RoundEnd | `roundId`, `durationSeconds`, `participantCount`, `survivorCount`, `winners`, `bestPoints`, `endReason` (`timer` / `no_survivors`), `coinsAwarded` |
| `round_aborted` | Abbruch im Countdown | `reason` (`too_few_players`), `participantCount` (Stand bei Countdown-Start) |
| `session_summary` | Server fährt herunter (`BindToClose`) | `roundsPlayed`, `avgDurationSeconds`, `avgParticipants`, `winsByPlayer` |

### API
| Funktion | Beschreibung |
|---|---|
| `roundStarted(participants)` | gibt `roundId` zurück |
| `playerEliminated(player, reason)` | nur während einer laufenden Runde |
| `roundEnded(result)` | gibt die Zusammenfassung zurück und speichert sie im Verlauf |
| `roundAborted(reason, participantCount)` | |
| `getHistory()` / `getSessionSummary()` | Verlauf der letzten 50 Runden im Speicher |

Beispiel aus dem Test:
```
[Analytics] round_ended {"bestPoints":0,"winners":["devirl_2"],"coinsAwarded":50,"durationSeconds":60.7,"survivorCount":1,"endReason":"timer","participantCount":1,"roundId":1,...}
```

**Grenze:** Die Daten liegen nur in der Konsole und im Speicher des Servers. Für Auswertungen über Server hinweg müsste man später an Roblox `AnalyticsService` oder einen DataStore/externen Dienst weiterleiten.

## 5. Geänderte Dateien

| Datei | Änderung |
|---|---|
| `src/shared/RoundConfig.luau` | `ANNOUNCEMENT_EVENT`, `PHASES`, `WARNING_SECONDS` |
| `src/server/RoundService.server.luau` | `announce()`, `runTimer(…, onTick)`, Analytics- und Cleanup-Aufrufe, `runPlaying` gibt `endReason` zurück, `runCountdown` gibt Teilnehmerzahl zurück |
| `src/server/MapCleanup.luau` | neu |
| `src/server/RoundAnalytics.luau` | neu |
| `src/shared/RoundAnnouncement.model.json` | neu (RemoteEvent) |
| `src/client/AnnouncementUI.client.luau` | neu |

## 6. Integrationstest (02.11.2026, Studio-Playtest, 1 Spieler)

| Test | Ergebnis |
|---|---|
| Banner Lobby / Countdown „5“ / „Noch 10 Sekunden!“ / Gewinner | angezeigt (Screenshots im Test geprüft) |
| Shop-Klick bei sichtbarem Banner | Shop öffnet sich, Banner blockiert nicht |
| Cleanup: Objekt in `RoundObjects`, getaggtes Objekt in `Props`, loses Tool | alle 3 nach Rundenende entfernt |
| Cleanup: `TankenPrompt` (Gas02) deaktiviert, 2 Displays rot gefärbt | wieder `Enabled = true` und Originalfarbe |
| Analytics volle Runde | `round_started` → `round_ended` (60.7 s, `timer`, 50 Coins) |
| Analytics Tod im Countdown | `round_aborted` (`participantCount: 1` nach Fix) |
| Analytics Tod in der Runde | `player_eliminated` (3.1 s) → `round_ended` (`no_survivors`, 0 Coins) |
| Play stoppen | `session_summary` (2 Runden, Ø 32.4 s) |

Keine Skriptfehler. Gefundener und behobener Fehler: `round_aborted` meldete zuerst `participantCount: 0` (siehe Task-Log).

**Nicht durch den Agenten getestet:** Mehrspieler (Local Server, 2 Spieler). Das Studio-MCP kann keinen Local Server starten.

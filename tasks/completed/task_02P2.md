# Task 02 – Runden-System (Game Loop & State Machine)

* **Status:** Completed
* **Projekt:** Praxisprojekt 02 – Game Mechanics & Systems Architecture
* **Verantwortlich:** Junior Developer / AI Agent
* **Source of Truth:** Repository (`src/`, `docs/`, `tasks/`)
* **Baut auf:** Task 01 (`tasks/completed/task_01P2.md`): `PlayerDataService`, `ShopConfig`, RemoteEvents

---

## 1. Zielstellung
Aufbau eines serverseitigen Runden-Systems als **State Machine**. Das Spiel durchläuft feste Zustände (Warten → Countdown → Runde läuft → Rundenende) in einer Endlosschleife. Den Zustand bestimmt allein der Server, Clients zeigen ihn nur an. Am Rundenende gibt es Coins über den bestehenden `PlayerDataService`.

---

## 2. Aufgabenstellung (Acceptance Criteria)

- [x] 1. **State Machine & Konfiguration (Server/Shared):**
  - `src/shared/RoundConfig.luau` mit allen Zeiten und Grenzwerten als Konstanten (z. B. `MIN_PLAYERS`, `INTERMISSION_SECONDS`, `COUNTDOWN_SECONDS`, `ROUND_SECONDS`, `ROUND_END_SECONDS`, Coin-Belohnungen).
  - Zustände als feste Liste: `Waiting`, `Intermission`, `Countdown`, `Playing`, `RoundEnd`.
  - Server-Skript `src/server/RoundService.server.luau` (Logik ggf. als Modul) mit klar definierten Übergängen. Ungültige Übergänge werden verhindert und geloggt.

- [x] 2. **Game Loop (Server):**
  - Endlosschleife: `Waiting` (bis `MIN_PLAYERS` erreicht) → `Intermission` → `Countdown` → `Playing` → `RoundEnd` → zurück.
  - Fallen während `Intermission`/`Countdown` zu viele Spieler weg, zurück zu `Waiting`.
  - `Playing` endet bei Zeitablauf oder wenn keine aktiven Spieler mehr übrig sind (z. B. alle gestorben/verlassen).
  - Spieler, die während einer laufenden Runde beitreten, warten auf die nächste Runde.
  - Rundenbeginn: Teilnehmer erfassen und zum Spielbereich teleportieren. Rundenende: zurück zum Lobby-Spawn.

- [x] 3. **Replikation & Status-UI (ReplicatedStorage/Client):**
  - Aktueller Zustand und Restzeit für alle Clients lesbar (z. B. Attribute `RoundState` / `TimeLeft` an `ReplicatedStorage` oder ein `RemoteEvent` `RoundStateChanged`).
  - LocalScript `src/client/RoundUI.client.luau`: Statusanzeige oben in der Mitte (z. B. „Warte auf Spieler (1/2)“, „Runde startet in 5“, „Runde läuft – 1:23“, „Runde vorbei“).
  - Bestehende `ShopGui` darf nicht überlagert werden.

- [x] 4. **Belohnung, Test & Doku:**
  - Am Rundenende Coins über `PlayerDataService.addCoins` vergeben (Teilnahme + Bonus für „Gewinner“). Clients können keine Belohnung auslösen.
  - Funktionstest im 2-Spieler-Local-Server: kompletter Durchlauf, Spieler verlässt mitten im Countdown/in der Runde, Spieler tritt während laufender Runde bei.
  - Dokumentation in `docs/architecture/round_system.md` (Zustandsdiagramm, Übergänge, Konfiguration, Testergebnisse). Verweis in `docs/architecture/systems_overview.md` ergänzen.

---

## 3. Entscheidungen (02.11.2026, vom User festgelegt)

**Siegbedingung**
- Rundendauer: `ROUND_SECONDS = 60`.
- Punkte: Jede Interaktion während `Playing` gibt 1 Punkt: Tanken an einer Zapfsäule oder Einkaufen am Tresen (bestehende Prompts mit Tag `GasStationPrompt`). Außerhalb von `Playing` und für Nicht-Teilnehmer gibt es keine Punkte.
- Gewinner bei Timer-Ablauf: Wer die meisten Punkte hat **und** noch lebt und im Spiel ist.
- Hat niemand gepunktet (alle 0), gewinnen alle Teilnehmer, die bis zum Ablauf überlebt haben.
- Gleichstand: Alle punktgleichen Spitzenreiter gewinnen.
- Rundenpunkte werden getrennt von den dauerhaften Attributen `Tankvorgaenge`/`Einkaeufe` gezählt und zu Rundenbeginn auf 0 gesetzt. Für die UI sind sie lesbar (z. B. Attribut `RoundPoints` am Player).

**Map & Lobby**
- Hauptspielbereich: Tankstellen-Gelände (Zapfsäulen, Shop, Parkplatz).
- Lobby/Wartebereich: Gang hinter dem Shop beim bestehenden Spawn (`Workspace.GamePlay.Spawns.SpawnLocation`, ca. (66.5, 1.22, −23.5)).
- Rundenbeginn: Teilnehmer zu Startpunkten im Spielbereich teleportieren (eigene Startpunkte anlegen, nicht übereinander). Rundenende: zurück in die Lobby.
- In der Lobby dürfen Prompts keine Punkte geben (ergibt sich aus der Regel „nur während `Playing`“).

**Belohnung**
- Gewinner: `WIN_REWARD = 50` Coins.
- Alle anderen Teilnehmer: `PARTICIPATION_REWARD = 10` Coins.
- Belohnungen gibt es nur für Spieler, die bei Rundenbeginn dabei waren und bei Rundenende noch im Spiel sind.

---

## 4. Agent Execution Log & Results

### Umsetzung Punkt 1–3 (02.11.2026)
- `src/shared/RoundConfig.luau`: Zeiten (15/5/60/8 s), `MIN_PLAYERS = 2` (Studio: 1), Belohnungen 50/10, Zustände, erlaubte Übergänge, Attributnamen.
- `src/server/RoundService.server.luau`: State Machine mit `setState` (ungültige Übergänge werden verhindert und geloggt), Game Loop, Teilnehmer-Erfassung beim Countdown, Teleport und Einfrieren, Punkte über die `GasStationPrompt`-Prompts (nur während `Playing`), Ausscheiden bei Tod oder Verlassen, Gewinner-Ermittlung und Belohnung über `PlayerDataService.addCoins`.
- `src/client/RoundUI.client.luau`: `RoundGui` oben in der Mitte (Zustand, Restzeit, eigene Punkte, Ergebnis, Belohnung).
- In Studio angelegt: `Workspace.GamePlay.RoundSpawns` (Start01–08 rund um die Zapfsäulen) und `Workspace.GamePlay.LobbySpawns` (Lobby01–07 im Gang hinter dem Shop). Positionen per Raycast und Overlap-Check geprüft.
- Skripte per MCP nach Studio übertragen (Rojo-Struktur). Byte-Länge = Dateigröße.

### Punkt 4 – Test & Doku (02.11.2026)
- Solo-Playtest (2 komplette Runden): Intermission → Countdown (Teleport, eingefroren) → Playing (2× Tanken per Taste E = 2 Punkte) → RoundEnd („Gewinner: devirl_2 (2 Punkte)“, 15 → 65 Coins, zurück in die Lobby) → Intermission. Einkaufen in der Pause gibt keinen Punkt. Tod während der Runde → Runde endet sofort, „niemand hat überlebt“, keine Coins. Keine Skriptfehler.
- `docs/architecture/round_system.md` erstellt, Verweis in `systems_overview.md` ergänzt.
- 2-Spieler-Test auf lokalem Server (MIN_PLAYERS = 2, Verlassen im Countdown, Beitritt während der Runde, 50/10-Verteilung, Gleichstand): über das MCP nicht startbar, vom Agenten nicht durchgeführt. Task auf Wunsch des Users abgeschlossen.

### Abschluss (02.11.2026)
- Place in Studio vom User gespeichert. Task nach `tasks/completed/task_02P2.md` verschoben, Commit und Push nach ausdrücklicher Freigabe.

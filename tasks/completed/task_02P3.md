# Task 02 – Game Loop Extension, State Cleanup & Analytics

* **Status:** Completed
* **Projekt:** Praxisprojekt 03 – Game Loop, Matchmaking & Analytics
* **Verantwortlich:** Junior Developer / AI Agent
* **Source of Truth:** Repository (`src/`, `docs/`, `tasks/`)

---

## 1. Zielstellung
Erweiterung des bestehenden Runden-Systems um automatisches Map-Cleanup nach Rundenende, bildschirmfüllende Status-Benachrichtigungen für alle Spieler sowie ein grundlegendes Event-Analytics-System.

---

## 2. Aufgabenstellung (Acceptance Criteria)

- [x] 1. **Map- & State-Cleanup (Server):**
  - Funktion schreiben, die nach Rundenende alle gespawnten Items/Props entfernt und Tankstellen-Interaktionen zurücksetzt.

- [x] 2. **UI-Status-Broadcasts (Client/Server):**
  - RemoteEvent für globale Runden-Ankündigungen nutzen.
  - UI-Textfeld für Countdown, Runden-Phasen (`Lobby`, `InGame`, `RoundEnd`) und Siegesnachrichten anzeigen.

- [x] 3. **Analytics-Tracking:**
  - `AnalyticsService` oder custom ModuleScript anlegen, um Rundendauer, Teilnehmerzahl und Gewinner in der Konsole/Log zu erfassen.

- [x] 4. **Dokumentation & Test:**
  - Dokumentation in `docs/architecture/analytics_and_cleanup.md` erstellen.
  - Integrationstest durchführen.

---

## 3. Agent Execution Log & Results

### Punkt 1 – Map- & State-Cleanup (02.11.2026)
- Neu: `src/server/MapCleanup.luau` (ModuleScript).
  - `init()` beim Serverstart: erfasst den Ausgangszustand aller `GasStationPrompt`-Prompts (3× `Enabled`) und der Displays (4× Zapfsäulen-`_Display`, 1× `KassenDisplay`). Legt `Workspace.RoundObjects` an.
  - `registerSpawned(obj)`: markiert Runden-Objekte mit dem Tag `RoundSpawned` (ohne Parent → `Workspace.RoundObjects`). Künftige Systeme, die Items/Props spawnen, müssen das nutzen.
  - `cleanup()`: entfernt den Inhalt von `RoundObjects`, alle `RoundSpawned`-Instanzen und lose Tools/Accessories in Workspace. Setzt Prompts und Display-Farben auf den Startzustand zurück. Loggt `[Cleanup] …`.
- Aufruf in `RoundService` nach Rundenende (nachdem die Spieler in der Lobby sind) und nach einem Abbruch im Countdown.
- Nicht zurückgesetzt: die Sitzungszähler `Tankvorgaenge`/`Einkaeufe` am Player (Statistik, keine Rundendaten). `RoundPoints` wird wie bisher beim Countdown genullt.

### Punkt 2 – UI-Status-Broadcasts (02.11.2026)
- Neu: RemoteEvent `ReplicatedStorage.RoundAnnouncement` (`src/shared/RoundAnnouncement.model.json`, Fallback im Server). Nur Server → Client: `FireAllClients(phase, title, subtitle, duration)`.
- `RoundConfig`: `ANNOUNCEMENT_EVENT`, `PHASES` (`Lobby`, `Countdown`, `InGame`, `RoundEnd`), `WARNING_SECONDS = 10`.
- Ankündigungen in `RoundService`: Lobby (Intermission-Start, „Warte auf Spieler“, „Runde abgebrochen“), Countdown 5…1, InGame („LOS!“, „Noch 10 Sekunden!“), RoundEnd (Siegesnachricht + Belohnungen).
- Neu: `src/client/AnnouncementUI.client.luau`: bildschirmfüllendes Banner (`AnnouncementGui`, DisplayOrder 10) mit Phasen-Label, großem Titel, Untertitel und Ein-/Ausblenden. Countdown-Zahlen ohne Abdunklung. `Interactable = false`, Klicks gehen durch. Die bestehende `RoundGui` (dauerhafte Statusleiste) bleibt.

### Punkt 3 – Analytics (02.11.2026)
- Neu: `src/server/RoundAnalytics.luau` (eigenes ModuleScript, kein Roblox-`AnalyticsService`, damit es in Studio ohne veröffentlichtes Spiel funktioniert).
- Konsolen-Format: `[Analytics] <event> {JSON}`. Events: `round_started` (ID, Teilnehmer), `player_eliminated` (Grund, Sekunden in der Runde), `round_ended` (Dauer, Teilnehmer, Überlebende, Gewinner, beste Punkte, `endReason` timer/no_survivors, vergebene Coins), `round_aborted`, `session_summary` (beim Herunterfahren: Runden, Ø-Dauer, Ø-Teilnehmer, Siege pro Spieler).
- Verlauf der letzten 50 Runden im Speicher (`getHistory`, `getSessionSummary`).

### Übertragung & Test Punkt 1–3 (02.11.2026)
- Per MCP nach Studio übertragen (`multi_edit`). Prüfsumme aller 5 Skripte in Studio = Datei in `src/`. `rojo build` erfolgreich.
- Solo-Playtest:
  - Banner Lobby, Countdown „5“, „Noch 10 Sekunden!“ und „Gewinner: … (überlebt)“ werden angezeigt. Ein Shop-Klick während des sichtbaren Banners öffnet den Shop.
  - Cleanup: 3 Testobjekte (in `RoundObjects`, getaggt in `Props`, loses Tool) entfernt. Deaktivierter `TankenPrompt` und 2 rot gefärbte Displays nach Rundenende zurückgesetzt.
  - Analytics: `round_started`/`round_ended` (60.7 s, timer), `round_aborted` (Tod im Countdown), `player_eliminated` (3.1 s) + `round_ended` (no_survivors), `session_summary` beim Stoppen.
- Gefundener Fehler und Fix: `round_aborted` meldete `participantCount: 0`, weil der gestorbene Spieler schon aus der Liste entfernt war. `runCountdown` gibt jetzt die Teilnehmerzahl vom Countdown-Start zurück. Nachtest: `participantCount: 1`.
- Hinweis: Im Solo-Test (1 Spieler reicht) folgt nach „Runde abgebrochen“ sofort die nächste Intermission, deshalb ersetzt das Lobby-Banner die Abbruch-Meldung schnell. Mit 2 Spielern bleibt der Server in Waiting.

### Punkt 4 – Dokumentation & Test (02.11.2026)
- `docs/architecture/analytics_and_cleanup.md` erstellt (API, Cleanup-Regeln, Phasen-Tabelle, Event-Schema, Testergebnisse). Verweise in `systems_overview.md` und `round_system.md` ergänzt.
- Integrationstest: Solo-Playtest aus Punkt 1–3 inkl. Nachtest des Fixes (siehe oben). Logik vom User bestätigt.
- Mehrspieler-Test (Local Server) wurde vom Agenten nicht durchgeführt, weil er über das MCP nicht startbar ist.

### Abschluss (02.11.2026)
- Place in Studio vom User gespeichert. Task nach `tasks/completed/task_02P3.md` verschoben, Commit und Push nach ausdrücklicher Freigabe.

# Task 01 – Release Candidate, Polish & Mobile-Optimierung

* **Status:** Completed
* **Projekt:** Praxisprojekt 04 – Release Candidate, Polish & Mobile-Optimierung
* **Verantwortlich:** Junior Developer / AI Agent
* **Source of Truth:** Repository (`src/`, `docs/`, `tasks/`)
* **Baut auf:** `task_01P2` (DataStore/Shop), `task_02P2` (Runden-System), `task_02P3` (Cleanup, Broadcasts, Analytics)

---

## 1. Zielstellung
Das Spiel wird zu einem veröffentlichungsfähigen **Release Candidate (RC1)**: Altlasten entfernen, Konfiguration für Live-Betrieb absichern, UI auf Smartphones/Tablets bedienbar machen, Spielgefühl mit Feedback (Sound/Animation) verbessern. Abschluss mit einem vollständigen Mehrspieler-Test und Release-Doku.

---

## 2. Bestandsaufnahme (vom Agenten am 02.11.2026 geprüft)

**Altlasten / Release-Hygiene**
- `src/shared/Hello.luau` (Template-Modul, wird nirgends genutzt), `src/client/init.client.luau` („Hello world“), `src/server/init.server.luau` (Lade-Print mit `task.wait(2)`).
- In Studio, außerhalb von Rojo: `ServerScriptService.Server` (altes Skript, gibt „Hello world, from server!“ aus), `ReplicatedStorage.Shared` (Ordner mit `Hello`), `ReplicatedStorage.Hello`.
- 17 `print`-Aufrufe in `src/` (`[Runde]`, `[Shop]`, `[PlayerData]`, `[Cleanup]`, `[Analytics]`) ohne Möglichkeit, sie live zu reduzieren.
- Bekannter Konsolenfehler: `rbxassetid://203785492 failed … Asset type does not match` (3× pro Start, Herkunft ungeklärt, laut Task 04 vermutlich Plugin/CoreScript).
- `README.md` enthält nur den Titel.

**Konfiguration / Skalierung**
- `Players.MaxPlayers = 60`, aber nur 8 Startpunkte (`RoundSpawns`) und 7 Lobby-Plätze. Ab dem 9. Spieler landen mehrere auf demselben Punkt.
- `MIN_PLAYERS_STUDIO = 1` gilt nur in Studio (`RunService:IsStudio()`), live 2. Vor dem Release bestätigen.
- `StreamingEnabled = true`: Teleport und Prompts funktionieren solo, mit Streaming über Distanz aber nicht geprüft.

**Mobile (aus dem Code abgeleitet, noch nicht im Emulator getestet)**
- `ShopButton` unten links (16 px Rand) überlappt den Touch-Thumbstick.
- `InventoryFrame` (200 px, rechts mittig) und `ShopFrame` (360 × 334 px) haben feste Pixelgrößen und kein `UIScale`. Auf Smartphones im Querformat (~375 px Höhe abzüglich Topbar) wird es eng.
- `ShopFrame` hat keine Scrollfläche. Mehr Items würden aus dem Fenster laufen.
- Die feste Schriftgröße in `RoundGui`/`ShopGui` (14–22 px) ist auf kleinen Displays eventuell zu klein.
- `AnnouncementGui` ist bereits skalierend (`TextScaled` + Max-Größe).

---

## 3. Aufgabenstellung (Acceptance Criteria)

- [x] 1. **Code-Cleanup & Release-Hygiene:**
  - Template-Reste aus `src/` entfernen (`Hello.luau`, Hello-Prints in `init.*.luau`). Die Studio-Reste (`ServerScriptService.Server`, `ReplicatedStorage.Shared`, `ReplicatedStorage.Hello`) nach Rücksprache löschen.
  - Zentrales Logging (z. B. `src/shared/Log.luau` mit Level `DEBUG`/`INFO`/`WARN`). Live nur `INFO`+, `[Analytics]` bleibt immer an.
  - Herkunft des Asset-Fehlers `203785492` klären (Plugins deaktiviert testen) und dokumentieren oder beheben.

- [x] 2. **Konfiguration für Live-Betrieb:**
  - `MaxPlayers` passend zu Startpunkten und Map festlegen (oder Startpunkte erweitern bzw. Versatz bei Mehrfachbelegung).
  - Zentrale Release-Prüfung der Configs (`ShopConfig`, `RoundConfig`): Werte, DataStore-Name `PlayerData_v1`, Studio-Sonderregeln.
  - Mit `StreamingEnabled` prüfen: Teleport in Arena/Lobby, Prompts und Displays werden zuverlässig geladen.

- [x] 3. **Mobile-Optimierung (UI):**
  - Shop-Button aus dem Thumbstick-Bereich verschieben (z. B. oben links unter der Topbar oder rechts über dem Sprung-Button).
  - `ShopGui` und `RoundGui` skalierend machen (`UIScale` nach Bildschirmgröße oder Scale-Größen). Item-Liste als `ScrollingFrame`.
  - Inventar auf kleinen Bildschirmen einklappbar oder kompakter.
  - Touch-Ziele mindestens 44 × 44 px. Lesbare Schrift auf dem Smartphone.
  - Test im Studio **Device Emulator**: mindestens 1 Smartphone quer, 1 Tablet, 1 Desktop. Screenshots in die Doku.

- [x] 4. **Polish & Spielgefühl:**
  - Sound-Feedback: Kauf (Erfolg/Fehler), Punkt erhalten, Countdown-Ticks, Rundenstart, Sieg.
  - Visuelles Feedback beim Punkt („+1“-Popup am Bildschirm oder über der Zapfsäule).
  - Einheitliches UI-Styling über alle Guis (Farben, Ecken, Schriften) aus einer gemeinsamen Quelle.
  - Kleine Bugs aus den Playtests sammeln und beheben.

- [x] 5. **Release Candidate – Test & Doku:**
  - Vollständiger Mehrspieler-Test (Local Server, mind. 2–3 Spieler): komplette Runde, Shop, Speichern/Laden, Abbruch, Beitritt während der Runde, Mobile-Emulator.
  - Release-Checkliste und Known Issues in `docs/release/release_candidate.md`. `README.md` mit Projektbeschreibung, Setup (Rojo/Aftman), Systemübersicht und Links zu `docs/`.
  - Nach Freigabe: Commit/Push und Git-Tag `v1.0.0-rc1`.

---

## 4. Entscheidungen (02.11.2026, vom User festgelegt)
- **MaxPlayers = 8**, passend zu den 8 Startpunkten.
- **Nur Querformat** (Landscape) erzwingen.
- **Sounds:** kostenlose Standard-Audio aus der Roblox-Toolbox.
- **Shop bleibt während der Runde benutzbar** (schnelle Käufe zwischendurch).
- Versionsname: `v1.0.0-rc1` (Vorschlag, Tag erst nach Freigabe).

---

## 5. Agent Execution Log & Results

### Umsetzung (02.11.2026)
Details, Tabellen und Testergebnisse: `docs/release/release_candidate.md`.

**Punkt 1 – Cleanup & Hygiene**
- `src/shared/Hello.luau` gelöscht. `init.server.luau` = reiner Container, `init.client.luau` = Querformat. In Studio `ServerScriptService.Server`, `ReplicatedStorage.Shared`, `ReplicatedStorage.Hello` gelöscht (Inhalt vorher geprüft: nur Hello-World).
- Neu `src/shared/Log.luau` (DEBUG/INFO/WARN, Studio DEBUG, live INFO, Attribut `LogLevel`). 26 Aufrufe in 5 Server-Dateien per Skript umgestellt (jede Ersetzung genau 1×).
- Asset `203785492` = Audio „Pop Close Sound“. Kein Verweis im Place (309 Instanzen gescannt) → Plugin/CoreScript, Known Issue. Ein Test mit deaktivierten Plugins ist über das MCP nicht möglich (das MCP selbst ist ein Plugin).

**Punkt 2 – Live-Konfiguration**
- `Players.MaxPlayers` ist per Skript schreibgeschützt → **User muss 8 in Game Settings setzen**.
- `LobbySpawns/Lobby08` ergänzt (Platz per Raycast/Overlap geprüft). Überlauf-Versatz in `teleportPlayers`.
- Neu `src/server/ReleaseCheck.server.luau` (31 Prüfungen). Aktuell 29/31: die 2 Warnungen betreffen nur MaxPlayers = 60.
- Streaming: Prompts und Zapfsäule nach dem Teleport beim Client vorhanden.

**Punkt 3 – Mobile**
- `StarterGui.ScreenOrientation = LandscapeSensor` + Client-Start.
- Neu `src/shared/UILayout.luau` (responsive, reine Funktion). `ShopUI` neu aufgebaut (Seitenleiste rechts, einklappbares Inventar, scrollbare Item-Liste, 44-px-Buttons). `RoundUI` mit kompakten Schriftgrößen.
- Layout-Rechnung für 6 Geräte (Desktop bis Android 640×360): 6/6 OK.
- Der Device Emulator ist über das MCP nicht steuerbar → Sichtprüfung im Emulator durch den User offen.

**Punkt 4 – Polish**
- Neu `src/shared/UITheme.luau` (gemeinsames Styling für alle 4 Client-Guis), `src/shared/SoundConfig.luau`, `src/client/FeedbackFX.client.luau` (7 Sounds, Popups „+1 Punkt“/„+X Coins“).
- Behobene Bugs: Pfeil-Glyphen als Kästchen → `–`/`+`. „(1 Punkte)“ → „(1 Punkt)“.

**Punkt 5 – Release-Test & Doku**
- Übertragung nach Studio per `multi_edit`. Prüfsumme aller 20 Skripte = `src/`. `rojo build` OK. (Ein HTTP-Sync aus Studio war nicht möglich, weil HTTP-Requests in den Experience Settings deaktiviert sind. Die Einstellung wurde bewusst nicht geändert.)
- Solo-Playtest: Kauf, Runde mit `LogLevel = INFO`, Punkt per Taste E, Rundenende +50 Coins mit Popup, alle Sounds geladen, keine Skriptfehler.
- Doku: `docs/release/release_candidate.md` (inkl. Release-Checkliste, Known Issues), `docs/README.md` (Projektübersicht, Setup). Die Root-`README.md` liegt außerhalb der laut `AGENTS.md` erlaubten Ordner → nicht geändert, Rücksprache nötig.
- **Offen (manuell durch den User):** MaxPlayers = 8 setzen, Device-Emulator-Sichtprüfung, Mehrspieler-Test (Local Server 2–3 Spieler), Place speichern/veröffentlichen. Danach Commit/Push und Tag `v1.0.0-rc1` nach Freigabe.

### Abschluss (02.11.2026)
- MaxPlayers = 8 vom User im Creator Hub eingestellt und gespeichert. Nicht vom Agenten nachgeprüft, weil Studio zu diesem Zeitpunkt geschlossen war. Beim nächsten Start sollte `[ReleaseCheck] OK – 31 Prüfungen bestanden` erscheinen.
- Root-`README.md` nach Freigabe durch den User aktualisiert (Features, Setup, Struktur, Doku-Links).
- Device-Emulator-Sichtprüfung und Mehrspieler-Test (Local Server) wurden vom Agenten nicht durchgeführt (über MCP nicht möglich). Task auf Wunsch des Users abgeschlossen.
- Task nach `tasks/completed/task_01P4.md` verschoben, Commit, Push und Tag `v1.0.0-rc1` nach ausdrücklicher Freigabe.

# Release Candidate v1.0.0-rc1 – MiniSzene

Stand: 02.11.2026 | Task: `tasks/completed/task_01P4.md` (Praxisprojekt 04)

## 1. Umfang
Rundenbasiertes Tankstellen-Spiel für bis zu 8 Spieler: In 60-Sekunden-Runden sammeln die Spieler Punkte durch Tanken und Einkaufen. Gewinner bekommen 50 Coins, die übrigen Teilnehmer 10. Coins und Inventar werden gespeichert, im Shop gibt es 4 Items.

| System | Doku |
|---|---|
| DataStore, Shop, Inventar | `docs/architecture/systems_overview.md` |
| Runden-System (State Machine) | `docs/architecture/round_system.md` |
| Map-Cleanup, Status-Broadcasts, Analytics | `docs/architecture/analytics_and_cleanup.md` |
| Release-Hygiene, Mobile, Polish | dieses Dokument |

## 2. Änderungen in Praxisprojekt 04

### 2.1 Aufräumen & Release-Hygiene
- Entfernt: `src/shared/Hello.luau`, „Hello world“-Ausgaben in `init.server.luau`/`init.client.luau`. In Studio: `ServerScriptService.Server`, `ReplicatedStorage.Shared`, `ReplicatedStorage.Hello` (alles Template-Reste, Inhalt vorher geprüft).
- `init.server.luau` ist jetzt ein reines Container-Skript, `init.client.luau` erzwingt das Querformat.
- **Zentrales Logging** `src/shared/Log.luau`: `Log.new("Tag")` → `log.debug/info/warn`. Studio = DEBUG, live = INFO. Umschaltbar zur Laufzeit über das Attribut `LogLevel` an `ReplicatedStorage`. Alle 26 `print`/`warn` in `src/server` umgestellt, `[Analytics]` bleibt immer sichtbar.

  | Level | Beispiele |
  |---|---|
  | DEBUG | einzelne Punkte, Teilnehmerzahl, Tankstellen-Aktionen, Autosave, Cleanup |
  | INFO | Zustandswechsel, Käufe, Laden der Daten, Ausscheiden, Gewinner/Belohnungen |
  | WARN | DataStore-Fehler, ungültige Übergänge, fehlende Startpunkte, ReleaseCheck-Probleme |
- **Asset-Fehler `rbxassetid://203785492`** geklärt: Es ist eine Audio-Datei („Pop Close Sound“, Ersteller Zyleak), die irgendwo als Bild angefordert wird. Ein Scan aller 309 Instanzen im Place (Content-Properties und Skript-Quellcode) fand keinen Verweis. Der Fehler kommt also aus einem Studio-Plugin oder aus CoreScripts, nicht aus dem Spiel. → Known Issue, kein Handlungsbedarf im Spiel.

### 2.2 Live-Konfiguration
- **MaxPlayers 8** (Entscheidung). `Players.MaxPlayers` ist per Skript schreibgeschützt und muss in Studio über *Game Settings → Places → Server Size* gesetzt werden (siehe Checkliste).
- 8. Lobby-Platz `Workspace.GamePlay.LobbySpawns.Lobby08` (x 50.5, z −23.5) ergänzt → 8 Arena- und 8 Lobby-Startpunkte.
- Überlauf-Schutz: Sind mehr Spieler als Startpunkte da, wird jede weitere Belegung um 3 Studs seitlich versetzt (`RoundService.teleportPlayers`).
- **Release-Prüfung** `src/server/ReleaseCheck.server.luau`: 31 Prüfungen beim Serverstart (Zeiten, Belohnungen, `MIN_PLAYERS`, Startpunkte ≥ MaxPlayers, Shop-Items, RemoteEvents, Sound-IDs, Querformat). Ergebnis: `[ReleaseCheck] OK – …` oder je Problem eine Warnung.
- `StreamingEnabled = true` geprüft: Nach dem Teleport zur Tankstelle hat der Client alle 3 Prompts und `Gas01`. Tanken per Taste E funktioniert.

### 2.3 Mobile-Optimierung
- **Querformat erzwungen**: `StarterGui.ScreenOrientation = LandscapeSensor` (Studio) und `PlayerGui.ScreenOrientation` im Client-Start.
- **Responsive Layout** `src/shared/UILayout.luau` (reine Funktion, testbar):
  - „compact“ bei Höhe < 500 oder Breite < 900 px.
  - Seitenleiste rechts (Shop-Button + einklappbares Inventar). Compact: oben rechts, Inventar standardmäßig eingeklappt. Desktop: rechts mittig.
  - Shop-Button nicht mehr unten links (vorher im Thumbstick-Bereich).
  - Shop-Fenster: Desktop mittig, compact links. Überlappt nie die Seitenleiste. Item-Liste ist ein `ScrollingFrame`.
  - Alle Buttons (Kaufen, Shop, Schließen) 44 px hoch.
  - Statusleiste: kleinere Schrift im compact-Modus (18/14 statt 22/16).
- **Layout-Test** (berechnet mit `UILayout.compute`, nutzbare Fläche = Gerät minus Topbar):

  | Gerät | compact | Shop | sichtbare Item-Zeilen | Seitenleiste (Ende y) | Ergebnis |
  |---|---|---|---|---|---|
  | Desktop 1920×1080 | nein | 380×354 mittig | 4 | rechts mittig | OK |
  | Desktop 1280×720 | nein | 380×354 mittig | 4 | rechts mittig | OK |
  | iPad 1024×768 | nein | 380×354 mittig | 4 | rechts mittig | OK |
  | iPhone 14 quer 844×390 | ja | 380×322 links | 3.5 (scrollt) | 104 / 200 | OK |
  | iPhone SE quer 667×375 | ja | 380×307 links | 3.2 (scrollt) | 104 / 200 | OK |
  | Android 640×360 | ja | 380×292 links | 3.0 (scrollt) | 104 / 200 | OK |

  Geprüft wurde je Gerät: im Bildschirm, keine Überlappung Shop/Seitenleiste, mindestens 1 Item-Zeile sichtbar, Buttons ≥ 44 px, Seitenleiste mindestens 110 px über dem unteren Rand (Sprung-Button). Seitenleiste-Ende = eingeklappt / ausgeklappt.

### 2.4 Polish
- **Einheitliches Styling** `src/shared/UITheme.luau`: Farben, Schriften, Größen, Ecken und Bau-Helfer. Wird von ShopUI, RoundUI, AnnouncementUI und FeedbackFX genutzt.
- **Sounds** `src/shared/SoundConfig.luau` + `src/client/FeedbackFX.client.luau` (kostenlose Creator-Store-Audio, nur lokal abgespielt):

  | Ereignis | Sound | Asset-ID | Länge |
  |---|---|---|---|
  | Kauf erfolgreich | Coin Clinking Sound | 133570405319995 | 1.0 s |
  | Kauf abgelehnt | ui-simple-negative-error | 87519554692663 | 0.3 s |
  | Punkt erhalten | coins_get | 607665037 | 0.5 s |
  | Countdown-Tick | Countdown beep | 117751546358455 | 1.0 s |
  | Rundenstart „LOS!“ | Countdown beep (×1.5) | 117751546358455 | 1.0 s |
  | Sieg | Winning Spirit (APMOfficial) | 1836860398 | 5.7 s |
  | Teilnahme-Coins | Coin Clinking (×1.2) | 133570405319995 | 1.0 s |

  Alle 7 laden im Playtest (`IsLoaded = true`). Bei der Auswahl wurden Audios mit Bezug zu fremden Spielen/Marken (z. B. „Squid Game“, „Subway Surfers“, „Final Fantasy“) bewusst ausgelassen.
- **Popups**: „+1 Punkt“ (gelb) und „+50 Coins“ / „+10 Coins“ (gold) steigen in der Bildschirmmitte auf und verblassen (`FeedbackGui`, DisplayOrder 5).
- Behobene Bugs aus den Playtests:
  - Pfeil-Symbole `▾`/`▸` im Inventar wurden in der Gotham-Schrift als Kästchen angezeigt → `–`/`+`.
  - Siegesmeldung „(1 Punkte)“ → „(1 Punkt)“ (`formatPoints`).

## 3. Konfiguration für den Release

| Wert | Datei | Release-Wert |
|---|---|---|
| `MIN_PLAYERS` / `MIN_PLAYERS_STUDIO` | `RoundConfig` | 2 / 1 (nur Studio) |
| Zeiten (Pause/Countdown/Runde/Ende) | `RoundConfig` | 15 / 5 / 60 / 8 s |
| Belohnung Sieg / Teilnahme | `RoundConfig` | 50 / 10 Coins |
| Startcoins | `ShopConfig` | 100 |
| DataStore | `PlayerDataService` | `PlayerData_v1` |
| Log-Level | `Log` | live INFO, Studio DEBUG |
| MaxPlayers | Game Settings | 8 |
| ScreenOrientation | StarterGui + Client | LandscapeSensor |

## 4. Testergebnisse RC1 (02.11.2026, Studio, 1 Spieler)

| Test | Ergebnis |
|---|---|
| Synchronität `src/` ↔ Studio | Prüfsumme aller 20 Skripte identisch, `rojo build` OK |
| Start | keine „Hello world“-Ausgaben, ReleaseCheck 29/31 OK (die 2 offenen Punkte betreffen MaxPlayers, s. u.) |
| Sounds | alle 7 geladen |
| Desktop-Layout | Seitenleiste rechts, Shop mittig, kein Überlappen (Screenshot geprüft) |
| Kauf per Mausklick | 115 → 105 Coins, Status grün, Inventar aktualisiert |
| Runde mit `LogLevel = INFO` | nur INFO-Zeilen + Analytics in der Konsole, keine DEBUG-Zeilen |
| Streaming nach Teleport | 3 Prompts + Zapfsäule beim Client vorhanden |
| Punkt (Taste E an Gas01) | „Deine Punkte: 1“, Popup „+1 Punkt“ |
| Rundenende | +50 Coins (105 → 155), Popup „+50 Coins“, Analytics `round_ended` |
| Layout-Rechnung 6 Geräte | 6/6 OK (Tabelle 2.3) |

## 5. Release-Checkliste

| # | Punkt | Status |
|---|---|---|
| 1 | Template-Reste entfernt (src + Studio) | ✅ |
| 2 | Zentrales Logging, live INFO | ✅ |
| 3 | Herkunft Asset-Fehler geklärt | ✅ (Plugin/CoreScript, Known Issue) |
| 4 | 8 Arena- + 8 Lobby-Startpunkte | ✅ |
| 5 | **MaxPlayers = 8** (Creator Hub) | ✅ vom User gesetzt (02.11.2026) |
| 6 | Querformat erzwungen | ✅ |
| 7 | Responsive UI, Touch-Ziele ≥ 44 px | ✅ (berechnet) |
| 8 | **Device Emulator** (Smartphone quer, Tablet, Desktop) sichtbar prüfen | ⚠️ manuell (Emulator über MCP nicht steuerbar) |
| 9 | Sounds + Popups | ✅ |
| 10 | **Mehrspieler-Test** Local Server 2–3 Spieler (Runde, Shop, Speichern, Abbruch, Beitritt während der Runde) | ⚠️ manuell |
| 11 | Place speichern + veröffentlichen | ⚠️ manuell |
| 12 | Commit, Push, Git-Tag `v1.0.0-rc1` | ✅ |

## 6. Known Issues
- `rbxassetid://203785492 … Asset type does not match` (3× pro Start in Studio): nicht aus dem Spiel, siehe 2.1.
- Das Countdown-Banner liegt kurz über einem geöffneten Shop-Fenster (gewollt: Ankündigungen haben Vorrang, der Shop bleibt bedienbar).
- Analytics liegen nur in der Server-Konsole und im Speicher (keine serverübergreifende Auswertung).
- Auf der Map kann man aktuell nicht sterben. „Überleben“ betrifft daher nur das Verlassen oder Zurücksetzen der Figur.
- Workspace-Inhalte (Startpunkte, Map) sind nicht in Rojo/`src/`, sondern nur im Place gespeichert.

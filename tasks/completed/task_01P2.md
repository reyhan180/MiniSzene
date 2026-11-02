# Task 01 – DataStore, RemoteEvents & Shop-System

* **Status:** Completed
* **Projekt:** Praxisprojekt 02 – Game Mechanics & Systems Architecture
* **Verantwortlich:** Junior Developer / AI Agent
* **Source of Truth:** Repository (`src/`, `docs/`, `tasks/`)

---

## 1. Zielstellung
Aufbau der grundlegenden System-Architektur für Praxisprojekt 02. Dazu gehören eine sichere Datenspeicherung über den DataStoreService, client-server-getrennte Kommunikation via RemoteEvents sowie ein funktionales Shop- und Inventar-System mit UI.

---

## 2. Aufgabenstellung (Acceptance Criteria)

- [x] 1. **DataStore & Player Data (Server):**
  - `DataStoreService` für automatisches Speichern/Laden von Coins und Items aufsetzen.
  - `Leaderstats`-Ordner beim Spawn des Spielers mit dem Wert `Coins` erstellen.

- [x] 2. **RemoteEvents & Kauf-Logik (Server/ReplicatedStorage):**
  - `RemoteEvent` namens `BuyItem` unter `ReplicatedStorage` anlegen.
  - Server-Skript zur Kauf-Validierung schreiben (prüfen ob genug Coins da sind, Coins abziehen, Item zum Inventar hinzufügen).

- [x] 3. **UI & Interaktion (Client):**
  - `ScreenGui` mit Shop-Fenster (Buy-Button) und Inventar-Anzeige aufbauen.
  - LocalScript zur Button-Ansteuerung und Auslösung des RemoteEvents erstellen.

- [x] 4. **Integration & Doku:**
  - Funktionstest im 2-Spieler-Local-Server durchführen.
  - Dokumentation in `docs/architecture/systems_overview.md` erstellen.

---

## 3. Agent Execution Log & Results

### Punkt 1 – DataStore & Player Data (02.11.2026)
- `src/server/PlayerDataService.luau` (ModuleScript): Laden/Speichern über DataStore `PlayerData_v1`, Key `Player_<UserId>`, Format `{ Coins, Inventory = { [itemId] = anzahl } }`.
  - Laden mit 3 Versuchen (`GetAsync`), Speichern über `UpdateAsync` bei `PlayerRemoving`, Autosave alle 60 s und in `BindToClose`.
  - Schlägt das Laden fehl, läuft die Sitzung mit Startwerten, **ohne** zu speichern (kein Überschreiben echter Daten).
  - Gespeicherte Daten werden bereinigt: fehlende Felder ergänzt, unbekannte Items verworfen.
  - Erstellt `player.leaderstats.Coins` (IntValue) und `player.Inventory.<itemId>` (IntValue) für die Anzeige am Client. Attribut `DataLoaded = true` nach dem Laden.
  - Server-API: `isLoaded`, `getCoins`, `addCoins`, `trySpendCoins`, `addItem`, `getItemCount`.
- `src/server/PlayerData.server.luau`: startet den Service.
- `src/shared/ShopConfig.luau` (ReplicatedStorage): Startcoins (100) und Item-Katalog `Wasser` 10, `Kaffee` 15, `Snack` 25, `Kanister` 50.

### Punkt 2 – RemoteEvents & Kauf-Logik (02.11.2026)
- `src/shared/BuyItem.model.json` → `ReplicatedStorage.BuyItem` (RemoteEvent). Das Server-Skript legt es zusätzlich an, falls es fehlt (z. B. ohne Rojo).
- `src/server/ShopService.server.luau`: Kauf-Validierung.
  - Client → Server: `BuyItem:FireServer(itemId)`. Der Client schickt nur die Item-ID, der Preis kommt immer aus `ShopConfig`.
  - Prüfungen: Typ der ID, Item existiert, Cooldown 0.5 s, Daten geladen, genug Coins. Dann Coins abziehen und Item gutschreiben.
  - Server → Client: `BuyItem:FireClient(player, success, itemId, message)` für die UI-Rückmeldung (Punkt 3).
- `rojo build` (7.7.1) erfolgreich: `BuyItem` und `ShopConfig` in ReplicatedStorage, `PlayerData`, `PlayerDataService`, `ShopService` in ServerScriptService.
- Playtest: siehe Punkt 4.

### Übertragung nach Studio (02.11.2026)
- Rojo lief nicht. Die Skripte wurden per Studio-MCP in dieselbe Struktur übertragen, die `rojo build` erzeugt: `ReplicatedStorage.ShopConfig`, `ReplicatedStorage.BuyItem`, `ServerScriptService.ServerScriptService.{PlayerDataService, PlayerData, ShopService}`, `StarterPlayerScripts.Client.ShopUI`.
- Byte-Länge aller 5 Skripte in Studio = Dateigröße in `src/`.

### Punkt 3 – UI & Interaktion (02.11.2026)
- `src/client/ShopUI.client.luau`: erzeugt die ScreenGui `ShopGui` mit Shop-Button (unten links), Shop-Fenster (Items aus `ShopConfig`, je ein „Kaufen“-Button, Coins, Statuszeile, Schließen) und Inventar-Anzeige (rechts).
- Kaufen-Button → `BuyItem:FireServer(itemId)`. Die Antwort des Servers wird 3 s lang grün/rot angezeigt.
- Zu teure Items haben einen grauen Button. Der Einkaufen-Prompt am Tresen öffnet den Shop ebenfalls.

### Punkt 4 – Integration & Doku (02.11.2026)
- Playtest (1 Spieler, echte Mausklicks/Taste E): Kauf, Ablehnung bei zu wenig Coins, manipulierte Anfragen (unbekanntes Item, Zahl, Tabelle), Spam-Schutz, Speichern/Laden nach Neustart (15 Coins + 3 Items wiederhergestellt), Tresen-Prompt, Schließen-Button. Alles bestanden, keine Skriptfehler. Details in der Doku, Abschnitt 7.
- `docs/architecture/systems_overview.md` erstellt.
- 2-Spieler-Test auf lokalem Server: konnte über das MCP nicht gestartet werden und wurde vom Agenten nicht durchgeführt. Task auf Wunsch des Users abgeschlossen.
- Hinweis: Der Testspieler `devirl_2` hat jetzt gespeicherte Daten (15 Coins, 3 Items) im DataStore `PlayerData_v1`.

### Abschluss (02.11.2026)
- Place in Studio vom User gespeichert. Task nach `tasks/completed/task_01P2.md` verschoben, Commit und Push nach ausdrücklicher Freigabe.

# Praxisprojekt 02 – Systems Overview: DataStore, RemoteEvents & Shop

Stand: 02.11.2026 | Task: `tasks/completed/task_01P2.md`

## 1. Überblick
Der Spieler hat Coins und ein Inventar, die per `DataStoreService` gespeichert werden. Im Shop (Fenster oder Tresen-Prompt) kauft er Items. Der Client sendet nur einen Kaufwunsch, alles Weitere entscheidet der Server.

```
Client (ShopUI)                    ReplicatedStorage                 Server
-----------------                  -----------------                 ------
Klick "Kaufen"  -- FireServer(itemId) -->  BuyItem  -->  ShopService: prüft & bucht
                                                              |
                                                     PlayerDataService (Session-Daten)
                                                              |
leaderstats.Coins / Inventory  <-- Replikation --  IntValues am Player   --> DataStore
Statuszeile     <-- FireClient(success, itemId, message) --  BuyItem
```

## 2. Dateien

| Datei (`src/`) | Ziel in Studio (Rojo) | Typ | Aufgabe |
|---|---|---|---|
| `shared/ShopConfig.luau` | `ReplicatedStorage.ShopConfig` | ModuleScript | Startcoins, Item-Katalog mit Preisen, Name des RemoteEvents |
| `shared/BuyItem.model.json` | `ReplicatedStorage.BuyItem` | RemoteEvent | Kaufanfrage und Antwort |
| `server/PlayerDataService.luau` | `ServerScriptService.ServerScriptService.PlayerDataService` | ModuleScript | Laden/Speichern, leaderstats, Inventar, Server-API |
| `server/PlayerData.server.luau` | `ServerScriptService.ServerScriptService.PlayerData` | Script | Startet `PlayerDataService` |
| `server/ShopService.server.luau` | `ServerScriptService.ServerScriptService.ShopService` | Script | Kauf-Validierung |
| `client/ShopUI.client.luau` | `StarterPlayer.StarterPlayerScripts.Client.ShopUI` | LocalScript | Baut `ShopGui` auf, Buttons, Inventar-Anzeige |

## 3. Datenhaltung (DataStore)

| Eigenschaft | Wert |
|---|---|
| DataStore | `PlayerData_v1` |
| Key | `Player_<UserId>` |
| Format | `{ Coins = number, Inventory = { [itemId] = anzahl } }` |
| Startwerte | 100 Coins, leeres Inventar |
| Laden | `GetAsync` beim Beitritt, bis zu 3 Versuche |
| Speichern | `UpdateAsync` bei `PlayerRemoving`, Autosave alle 60 s, `BindToClose` |

- **Schutz vor Datenverlust:** Schlägt das Laden fehl, spielt der Spieler mit Startwerten weiter, es wird aber nicht gespeichert. So überschreibt ein DataStore-Ausfall keine echten Daten.
- **Bereinigung:** Fehlende Felder werden ergänzt, Items, die nicht mehr in `ShopConfig` stehen, werden beim Laden verworfen.
- **Für den Client sichtbar** (nur lesend, vom Server gesetzt):
  - `player.leaderstats.Coins` (IntValue, erscheint in der Spielerliste)
  - `player.Inventory.<itemId>` (IntValue = Anzahl)
  - Attribut `DataLoaded = true`, sobald die Daten geladen sind
- **Server-API** (`PlayerDataService`): `isLoaded`, `getCoins`, `addCoins`, `trySpendCoins`, `addItem`, `getItemCount`. Andere Server-Systeme (z. B. Coin-Belohnungen) sollen Daten nur über diese Funktionen ändern.
- In Studio muss *Game Settings → Security → Enable Studio Access to API Services* aktiv sein.

## 4. Items (`ShopConfig.ITEMS`)

| Item-ID | Anzeigename | Preis |
|---|---|---|
| `Wasser` | Wasserflasche | 10 |
| `Kaffee` | Kaffee | 15 |
| `Snack` | Schokoriegel | 25 |
| `Kanister` | Benzinkanister | 50 |

Neue Items: nur in `ShopConfig.luau` eintragen. Shop-Fenster und Inventar-Anzeige bauen sich daraus automatisch auf.

## 5. Kauf-Ablauf & Validierung (`BuyItem`)
- Client → Server: `BuyItem:FireServer(itemId)`. Es wird **nur die Item-ID** geschickt, niemals ein Preis.
- Server → Client: `BuyItem:FireClient(player, success, itemId, message)`.

Prüfreihenfolge in `ShopService`:
1. `itemId` ist ein String → sonst „Ungültige Anfrage“
2. Item existiert in `ShopConfig` → sonst „Unbekanntes Item“
3. Cooldown 0.5 s seit dem letzten Kauf → sonst „Zu schnell“
4. Spielerdaten sind geladen → sonst „Daten noch nicht geladen“
5. Genug Coins (`trySpendCoins`) → sonst „Nicht genug Coins (X benötigt)“
6. Coins abziehen, Item +1, Erfolgsmeldung

Jede Anfrage wird in der Server-Konsole als `[Shop] Kauf: …` oder `[Shop] Kauf abgelehnt: …` protokolliert.

## 6. UI (`ShopGui`)
Wird von `ShopUI.client.luau` per Code erzeugt (`ResetOnSpawn = false`).

| Element | Pfad in `PlayerGui.ShopGui` | Funktion |
|---|---|---|
| Shop-Button | `ShopButton` (unten links) | Öffnet/schließt das Shop-Fenster |
| Shop-Fenster | `ShopFrame` (Mitte) | Titel, Coins, eine Zeile pro Item mit `BuyButton`, Statuszeile, `CloseButton` |
| Inventar | `InventoryFrame` (rechts) | Zeigt alle Items mit Anzahl > 0, sonst „leer“ |

- Der Einkaufen-Prompt am Tresen (`Tag GasStationPrompt`, `Interaction = "Einkaufen"`) öffnet zusätzlich das Shop-Fenster.
- Zu teure Items haben einen grauen Kaufen-Button. Der Klick wird trotzdem gesendet, abgelehnt wird auf dem Server.
- Die Statuszeile zeigt die Antwort des Servers 3 s lang (grün = Erfolg, rot = abgelehnt).

## 7. Testergebnisse (02.11.2026, Studio-Playtest, 1 Spieler)

| Test | Ergebnis |
|---|---|
| Erster Beitritt | `[PlayerData] … geladen (Coins: 100, neu: true)`, leaderstats vorhanden |
| Kauf Schokoriegel per Mausklick | 100 → 75 Coins, Inventar „Schokoriegel x1“, grüne Statuszeile |
| Kauf Benzinkanister | 75 → 25 Coins |
| Kanister erneut (25 < 50) | abgelehnt „Nicht genug Coins (50 benötigt)“, Button grau |
| `FireServer("GratisGold")` | abgelehnt „Unbekanntes Item“ |
| `FireServer(123)` / `FireServer({price = 0})` | abgelehnt „Ungültige Anfrage“ |
| 2× `FireServer("Wasser")` direkt hintereinander | 1. gekauft, 2. „Zu schnell“ |
| Playtest stoppen und neu starten | `geladen (Coins: 15, neu: false)`, Inventar Wasser/Snack/Kanister je 1 → **Speichern funktioniert** |
| Taste E am Tresen-Prompt | Shop-Fenster öffnet sich, Tankstellen-Logik läuft weiter |
| Schließen-Button | Fenster geschlossen |

Keine Fehler aus den neuen Skripten in der Konsole. (`rbxassetid://203785492 …` ist bekannt und kommt nicht aus diesen Skripten, siehe Task 04.)

**Offen:** Test mit 2 Spielern auf einem lokalen Server (*Test → Clients and Servers → Local Server, 2 Players*). Der kann über das Studio-MCP nicht gestartet werden und muss manuell durchgeführt werden. Prüfen: Jeder Spieler sieht nur seine eigenen Coins/Items im Shop, und die Käufe von Spieler 1 ändern nichts bei Spieler 2.

## 8. Weitere Systeme
- Runden-System (Game Loop & State Machine): `docs/architecture/round_system.md`. Vergibt Coins am Rundenende über `PlayerDataService.addCoins`.

**Nachtrag 02.11.2026:** 2-Spieler-Test auf lokalem Server vom User manuell durchgeführt. Runden-System, Coins-Verteilung und UI-Anzeigen funktionieren im Multiplayer.
- Map-Cleanup, Status-Broadcasts & Analytics (Praxisprojekt 03): `docs/architecture/analytics_and_cleanup.md`.

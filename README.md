# MiniSzene – Tankstellen-Rundenspiel (Roblox)

Rundenbasiertes Multiplayer-Spiel an einer Tankstelle für bis zu 8 Spieler: Die Spieler warten in der Lobby (Gang hinter dem Shop), werden zur Tankstelle teleportiert und sammeln in 60 Sekunden Punkte durch Tanken und Einkaufen. Gewinner bekommen 50 Coins, die übrigen Teilnehmer 10. Coins und Inventar werden per DataStore gespeichert und im Shop ausgegeben.

**Version:** `v1.0.0-rc1` (Release Candidate, siehe [`docs/release/release_candidate.md`](docs/release/release_candidate.md))

## Features
- Runden-System als State Machine: Waiting → Intermission → Countdown → Playing → RoundEnd
- Punkte durch Tanken/Einkaufen, Gewinner-Ermittlung, Coin-Belohnungen
- DataStore für Coins und Inventar, Shop mit serverseitiger Kauf-Validierung
- Bildschirmfüllende Phasen-Ankündigungen, Statusleiste, Sounds und „+1 Punkt“-Popups
- Map-Cleanup nach jeder Runde, Analytics-Logging (`[Analytics] …`)
- Mobile-optimierte UI (nur Querformat), automatische Release-Prüfung beim Serverstart

## Setup
1. Toolchain über [Aftman](https://github.com/LPGhatguy/aftman): `aftman install` (Rojo 7.7.1 aus `aftman.toml`)
2. Place bauen: `rojo build -o MiniSzene.rbxlx` oder Live-Sync mit `rojo serve` + Rojo-Plugin in Studio
3. In Studio: *Game Settings → Security → Enable Studio Access to API Services* (für den DataStore)
4. Map und Startpunkte (`Workspace`) liegen nur im Place, nicht in `src/`

## Projektstruktur
```
src/
  shared/   -> ReplicatedStorage      Configs (ShopConfig, RoundConfig, SoundConfig), Log, UITheme, UILayout, RemoteEvents
  server/   -> ServerScriptService    PlayerData(Service), ShopService, RoundService, MapCleanup, RoundAnalytics, ReleaseCheck, GasStationInteractions
  client/   -> StarterPlayerScripts   ShopUI, RoundUI, AnnouncementUI, FeedbackFX
docs/       Architektur- und Release-Doku
tasks/      Aufgaben (active / completed)
```

## Dokumentation
| Thema | Datei |
|---|---|
| Projektübersicht | [`docs/README.md`](docs/README.md) |
| Spielerdaten & Shop | [`docs/architecture/systems_overview.md`](docs/architecture/systems_overview.md) |
| Runden-System | [`docs/architecture/round_system.md`](docs/architecture/round_system.md) |
| Cleanup, Broadcasts, Analytics | [`docs/architecture/analytics_and_cleanup.md`](docs/architecture/analytics_and_cleanup.md) |
| Release Candidate, Mobile, Polish | [`docs/release/release_candidate.md`](docs/release/release_candidate.md) |
| Level-Design | [`docs/level-design/`](docs/level-design/) |

## Mitwirken
Regeln für Arbeitsbereiche, Namen und Ablauf: [`AGENTS.md`](AGENTS.md).

# MiniSzene – Tankstellen-Rundenspiel (Roblox)

Rundenbasiertes Multiplayer-Spiel an einer Tankstelle: Spieler warten in der Lobby (Gang hinter dem Shop), werden zur Tankstelle teleportiert und sammeln in 60 Sekunden Punkte durch Tanken und Einkaufen. Gewinner bekommen 50 Coins, die übrigen Teilnehmer 10. Coins und Inventar werden per DataStore gespeichert und im Shop ausgegeben.

**Version:** `v1.0.0-rc1` (Release Candidate, siehe `release/release_candidate.md`)

## Setup
- Toolchain über [Aftman](https://github.com/LPGhatguy/aftman): `aftman install` (installiert Rojo 7.7.1 aus `aftman.toml`).
- Place bauen: `rojo build -o MiniSzene.rbxlx`
- Live-Sync mit Studio: `rojo serve` + Rojo-Plugin in Studio.
- In Studio: *Game Settings → Security → Enable Studio Access to API Services* (für den DataStore).
- Map und Startpunkte (`Workspace`) liegen nur im Place, nicht in `src/`.

## Projektstruktur
```
src/
  shared/   -> ReplicatedStorage      Configs (ShopConfig, RoundConfig, SoundConfig), Log, UITheme, UILayout, RemoteEvents
  server/   -> ServerScriptService    PlayerData(Service), ShopService, RoundService, MapCleanup, RoundAnalytics, ReleaseCheck, GasStationInteractions
  client/   -> StarterPlayerScripts   ShopUI, RoundUI, AnnouncementUI, FeedbackFX
docs/       Architektur- und Release-Doku
tasks/      Aufgaben (active / completed)
```

## Systeme
| System | Kurz | Doku |
|---|---|---|
| Spielerdaten & Shop | DataStore `PlayerData_v1`, Kauf-Validierung über `BuyItem` | `architecture/systems_overview.md` |
| Runden-System | State Machine Waiting → Intermission → Countdown → Playing → RoundEnd | `architecture/round_system.md` |
| Cleanup, Broadcasts, Analytics | Map-Reset, Vollbild-Ankündigungen, `[Analytics]`-Logs | `architecture/analytics_and_cleanup.md` |
| Release, Mobile, Polish | Logging, ReleaseCheck, responsive UI, Sounds | `release/release_candidate.md` |

## Regeln für Mitwirkende
Siehe `AGENTS.md` im Projektordner (Arbeitsbereiche, Namensregeln, Ablauf mit `tasks/`).

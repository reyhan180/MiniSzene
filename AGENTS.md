# AGENTS.md – Richtlinien für KI-Agenten

Verhaltensregeln, Namenskonventionen und Systemgrenzen für KI-Agenten (In Repo arbeiten)

---
## 1. Arbeitsgrenzen(Scope & Boundaries):
- Code wird nur im Ordner `src/` bearbeitet. ->Source of Truth
- Änderungen nur in `src/`, `docs/` und `tasks/`.
- Kein automatisches Hochladen auf GitHub (git push). `git push`
- Die Projektstruktur `default.project.json` nicht ohne Rücksprache ändern.


---

## 2. Namensregeln (Luau & Rojo)
feste Regeln, wie Dateien und Variablen heißen müssen.

- Server-Skripte: `.server.luau` -> Bsp. `init.server.luau` , `PlayerManager.server.luau`
- Client-Skripte: `.client.luau` -> Bsp. `init.client.luau` , `UIHandler.client.luau`
- Module: `.luau` -> Bsp. `MathUtilis.luau` , `Config.luau`
- Variablen/Funktionen: `camelCase` -> Bsp. `playerHealth` , `calculateDamage()`
- Services/Klassen: `PascalCase` -> Bsp. `Workspace` , `Players` , `ServerScriptService`
- Konstanten: `SNAKE_CASE_CAPS` , Bsp. `MAX_Players` , `WALK_SPEED`


---
## 3. Arbeitsablauf
1. Zuerst die Aufgabe in `tasks/active/` lesen.
2. Während der Arbeit den Fortschritt aktualisieren.
3. Wenn die Aufgabe fertig ist, nach `tasks/completed/` verschieben.

für mich : 
Merksatz: AGENTS.md ist wie ein Regelbuch für KI-Agenten. Es sagt ihnen, wo sie arbeiten dürfen, wie sie Dinge benennen müssen und wie sie Aufgaben erledigen sollen.
# Task 03: Environment Building & Storytelling

* **Status:** Completed (01.11.2026)
* **Zugewiesen an:** AI Agent / Developer
* **Erstellt am:** 1.11.2026

---

## Ziel
Den abgenommenen Blockout aus Task 02 in eine glaubwürdige Tankstelle verwandeln: Materialien, Beleuchtung und Props sollen eine Geschichte erzählen, ohne die Balance von Scale und Sightlines zu verändern.

**Arbeitsthese Story:** abgelegene Highway-Tankstelle in der Abenddämmerung, kurz vor Ladenschluss. Diese Annahme kann noch geändert werden.

---

## Arbeitsplan

### Phase 1 – Materialien (Palette mit 3–4 Hauptfarben)
- [x] Boden: `Bodenplatte` bleibt Concrete. Unter der Überdachung liegt `Roads/VorplatzBoden` (35 × 0.1 × 20, Concrete, 150, 148, 144), damit die Zone gut lesbar ist.
- [x] Spawn: `GamePlay/Spawns/SpawnLocation` von (98, 90) an der Straßenkante nach (66.5, −23.5) hinter den Shop verlegt. Von der Straße aus nicht sichtbar (0/60). Hinweis: steht nur 0,5 Studs vom Kartenrand entfernt.
- [x] Straße: `MainRoad` Asphalt, dunkelgrau (48, 48, 52).
- [x] Parkplatz: `ParkplatzBoden` Asphalt, Farbe (55, 55, 58) beibehalten, minimal heller als die Straße.
- [x] Shop: Wände und `Türsturz` Concrete, heller warmer Beton (190, 186, 176). `Dach` Metal, dunkel (88, 92, 98).
- [x] Shop: `ShopFloor` Marble, hell (226, 223, 216).
- [x] Insel: `Fundament` Concrete (170, 168, 162), `Überdachung` Metal hell (215, 217, 220), `Säule01–04` Metal (120, 124, 130).
- [x] Zapfsäulen: Korpus `Gas01`/`Gas02` Metal, gebürstet hell (200, 204, 208).
- [x] Zapfsäulen: `Props/ZapfsäulenDetails` mit je 2 Kunststoff-Verkleidungen (SmoothPlastic, Markenrot 196, 40, 47) und 2 Neon-Displays (90, 220, 255) pro Säule, auf beiden Längsseiten. `CanCollide = false`, damit Kollision und Deckung unverändert bleiben.
- [x] Deckung: `Mauer01` Brick (150, 82, 62), `Kiste01` WoodPlanks (140, 100, 62).

### Phase 2 – Beleuchtung
- [x] ClockTime auf 18.0 (Dämmerung) gesetzt.
- [x] Technology „Future“: manuell im Studio-UI gesetzt (Developer).
- [x] `Lighting.Ambient` von (0, 0, 0) auf (40, 35, 45) angehoben, damit dunkle Flächen nicht pechschwarz wirken.
- [x] Doppelte Sky entfernt: der sichtbare Himmel `Stylized` bleibt, die Standard-`Sky` wurde gelöscht (IDs zur Wiederherstellung: Bk/Ft 6444884337, Up 6412503613, Sun 6196665106, Moon 6444320592).
- [x] Atmosphere: Density 0.35, Offset 0.15, Color (210, 165, 140), Decay (95, 85, 120), Glare 0.3, Haze 1.2.
- [x] Bloom: Intensity 0.6, Size 24, Threshold 1.6. Dezent, damit fast nur Neon leuchtet.
- [x] DepthOfField: aktiviert, nur leichte Fernunschärfe (Far 0.15, Near 0, Focus 50, Radius 70), damit die Sicht im Gameplay nicht leidet.
- [x] Ordner `Workspace.Lighting` mit den wirkungslosen Effekten (SunRays, DepthOfField, ColorCorrection, Bloom) gelöscht. Post-Processing wirkt nur im Lighting-Service oder in der Camera.
- [x] Überdachung: `Props/Leuchten` mit 4 Neon-Leuchtpanels (`Leuchte01–04`) direkt unter der Überdachung, je ein SpotLight (Face Bottom, Angle 100, Range 22, Brightness 3, kaltweiß, Shadows an). Das ist die hellste Lichtinsel und der Landmark-Punkt.
- [x] Shop: `Shop/Innenlicht` mit 3 Neon-Deckenleuchten, je ein PointLight (warmgelb 255, 190, 120, Range 18, Brightness 1.5, Shadows an). Die vordere Leuchte sitzt nahe der Tür, ihr Licht fällt nach außen.
- [x] Laternen: `Props/Laternen` mit 3 Models (Mast 12 Studs, Ausleger, Neon-Leuchtkopf mit SpotLight: Angle 110, Range 24, Brightness 2, warmweiß). `Laterne01` am Parkplatz (12, 6), `Laterne02`/`Laterne03` am Straßenrand (10, 91) und (70, 91). Die Deckungszonen um `Mauer01` und `Kiste01` bleiben im Halbdunkel.
- [x] Performance: insgesamt 10 Lights (4 SpotLights Überdachung, 3 PointLights Shop, 3 SpotLights Laternen), unter dem Budget von 15. Hinweis: Alle 10 werfen derzeit Schatten. Falls die Performance auf schwachen Geräten leidet, bei Shop-Innenlicht und Laternen `Shadows` ausschalten.

### Phase 3 – Props & Storytelling
- [x] Shop innen: `Props/Shop/Innenraum` mit `Tresen` (rechts der Tür, mit Kasse und Display) und `Regal01`/`Regal02` (linke Shophälfte, mit Waren). Der Gang von der Tür bleibt bewusst frei. Die Stelle direkt hinter der Tür bleibt daher bei 25/60, zwischen den Regalen ist man jetzt komplett gedeckt (1 → 0).
- [x] Kartenrand: `Props/Begrenzung/ZaunNord`, ein Maschendrahtzaun über die ganze Nordkante plus ein Stück an der Ostkante hinter dem Shop, dazu eine unsichtbare Wand (30 Studs hoch, `CanQuery = false`).
- [x] Shop außen: `Props/Shop/Müllcontainer01` (Ostwand), `Props/Shop/Kistenstapel01` (3 Kisten, Ostwand), `Props/Shop/Gasflaschenkäfig01` (Shopfront rechts neben der Tür, 4 Gasflaschen hinter halbtransparentem Gitter).
- [x] Straße: `Props/Straße/Preistafel` bei (35, 89) mit Fantasiemarke „NORDSTERN“ und 3 Preisen (SurfaceGui, leuchtet unabhängig vom Licht). Die Tafel beginnt erst bei 8 Studs Höhe, darunter stehen nur zwei dünne Pfosten, damit die Sicht auf Augenhöhe frei bleibt.
- [x] Insel: `Props/Insel/Mülleimer01` zwischen den Zapfsäulen auf dem Fundament.
- [x] Shop außen: `Props/Shop/Leuchtschild` auf der Dachkante über der Tür („NORDSTERN SHOP“, Markenrot, Neon-Leuchtleiste).
- [x] Insel: `Feuerlöscher01` an Säule02, `WischerEimer01` am Westende des Fundaments, `Luftdruckstation01` westlich der Überdachung abseits der Fahrspuren.
- [x] Sichtachsen-Kontrolle nach dem Einbau: alle 9 Messpunkte vorher = nachher (Gas01 4, Gas02 6, hinter Tür 25, Shop Mitte 15, Shop hinten 9, Mauer 0, Kiste 1, Freifläche 29, Spawn 0 von 60).
- [x] Parkplatz: `Props/Parkplatz/Auto01` aus Parts, vorwärts in der rechten Bucht eingeparkt.
- [x] Story-Details: `Props/Deko/Ölflecken` mit 5 flachen Scheiben statt Decals (kein Bild-Asset nötig): in der leeren Bucht, unter dem Auto und auf den Fahrspuren der Insel.
- [x] Struktur: `Props/Shop`, `Props/Insel`, `Props/Straße`, `Props/Parkplatz`, `Props/Deko`, `Props/Begrenzung`. Alle Parts `Anchored = true`, kleine Deko zusätzlich `CanCollide = false`, `CastShadow = false`, `CanQuery = false`.
- [x] Sichtachsen-Kontrolle nach dem Einbau: alle 9 Messpunkte aus Task 02 unverändert. Neue Deckung gewollt: hinter dem Auto 44 → 35, zwischen den Regalen 1 → 0.
- Backlog (nicht Teil von Phase 3): Eistruhe, Einkaufswagen, Reifenstapel, schiefes Straßenschild.

### Phase 4 – Prüfung & Doku
- [x] Sightline- und Raycast-Check wiederholt (gleiche 60 Straßenpunkte wie in Task 02, 13 Messpunkte). Keine neuen Sichtlöcher, keine Deckung ungewollt zugebaut. Alle Deckungspunkte aus Task 02 sind gleich geblieben oder besser geworden.
- [x] Integritätsprüfung: 169 Parts unter `Environment`, alle `Anchored = true`. 10 Lights, 1 Sky, kein `Workspace.Lighting` mehr. Spawn verankert und hinter der unsichtbaren Wand gesichert.
- [x] Ergebnisse in `docs/level-design/tankstelle_environment.md` (Abschnitt 8) dokumentiert, Task nach `tasks/completed/` verschoben.

---

## Aufgabenstellung
- [ x] 1. **Proportionen & Layout anlegen:**
  - Grundplatte (~150x150 Studs) als Fundament erstellen.
  - Shop-Gebäude (Wandhöhe 12–15 Studs, Türöffnung 5x8 Studs) platzieren.
  - Zapfsäulen-Inseln mit Überdachung (Höhe 16–18 Studs) bauen.
  - Anbindungen für Straße und Parkplatz abstecken.
- [x ] 2. **Ordnerstruktur organisieren:**
  - Parts in Studio im Explorer sauber unter `Workspace -> Environment` (Buildings, Props, Terrain) einordnen.
  - `Anchored = true` für alle statischen Teile aktivieren.
- [ x] 3. **Agent-Analyse durchführen:**
  - **Scale Check:** Prüfung der Größenverhältnisse im Vergleich zur Roblox-Avatarhöhe (~5 Studs).
  - **Sightlines Check:** Analyse der Sichtachsen und Deckungsmöglichkeiten (Cover).
- [x ] 4. **Dokumentation:**
  - Ergebnisse in `docs/level-design/tankstelle_blockout.md` eintragen.

---

## Akzeptanzkriterien
* Der Blockout steht vollständig als Part-Konstruktion in Roblox Studio.
* Alle baulichen Elemente sind korrekt verankert (`Anchored`).
* Die Analyse zu Scale und Sightlines ist in den Docs dokumentiert.

---

## Notizen / Dokumentation
* **Ordnerpfad:** `tasks/completed/task_03.md`
* **Dokumentationspfad:** `docs/level-design/tankstelle_environment.md` (Grundlage: `docs/level-design/tankstelle_blockout.md`)
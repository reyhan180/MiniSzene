# Praxisprojekt 01 – Gas Station Environment (Task 03)

Stand: 01.11.2026 | Task 03 abgeschlossen (Phase 1–4) | Grundlage: Blockout aus `tankstelle_blockout.md` | Task: `tasks/completed/task_03.md`

## 1. Ziel & Stimmung
- Story-These: abgelegene Highway-Tankstelle in der Abenddämmerung, kurz vor Ladenschluss.
- Grundsatz: Materialien und Licht erzählen die Szene, ohne Scale und Sightlines aus Task 02 zu verändern.
- Bestehende Parts: nur `Material` und `Color` geändert. Position, Drehung, Größe und `Anchored` wurden vor und nach jeder Änderung verglichen, ohne Abweichung.

## 2. Phase 1 – Materialien

| Bereich | Part(s) | Material | Farbe (RGB) |
|---|---|---|---|
| Straße | `Roads.MainRoad` | Asphalt | 48, 48, 52 |
| Parkplatz | `Roads.Parkplatz.ParkplatzBoden` | Asphalt | 55, 55, 58 |
| Shop | Wände (5) + `Türsturz` | Concrete | 190, 186, 176 |
| Shop | `Dach` | Metal | 88, 92, 98 |
| Shop | `ShopFloor` | Marble | 226, 223, 216 |
| Insel | `Roads.VorplatzBoden` (neu, 35 × 0.1 × 20) | Concrete | 150, 148, 144 |
| Insel | `Fundament` | Concrete | 170, 168, 162 |
| Insel | `Überdachung` | Metal | 215, 217, 220 |
| Insel | `Säule01–04` | Metal | 120, 124, 130 |
| Zapfsäulen | `Gas01`, `Gas02` (Korpus) | Metal | 200, 204, 208 |
| Deckung | `Mauer01` | Brick | 150, 82, 62 |
| Deckung | `Kiste01` | WoodPlanks | 140, 100, 62 |

**Neue Detail-Parts** (`Props/ZapfsäulenDetails`, 8 Parts): Pro Zapfsäule und Längsseite gibt es eine Kunststoff-Verkleidung (SmoothPlastic, Markenrot 196, 40, 47) und ein Neon-Display (90, 220, 255). Die Parts haben `CanCollide = false`, damit Kollision und gemessene Deckung unverändert bleiben.

## 3. Phase 2 – Beleuchtung

### Lichtquellen (10 insgesamt)
| Ort | Ordner | Lichttyp | Einstellungen | Zweck |
|---|---|---|---|---|
| Zapfsäulen-Überdachung | `Props/Leuchten` (4 Neon-Panels) | SpotLight, nach unten | Angle 100, Range 22, Brightness 3, kaltweiß 230, 240, 255 | Hellste Lichtinsel und Landmark |
| Shop innen | `Buildings/Shop/Innenlicht` (3 Deckenleuchten) | PointLight | Range 18, Brightness 1.5, warmgelb 255, 190, 120 | Warmes Licht fällt durch die Tür und führt zum Eingang |
| Parkplatz + Straße | `Props/Laternen` (3 Models: Mast, Ausleger, Leuchtkopf) | SpotLight, nach unten | Angle 110, Range 24, Brightness 2, warmweiß 255, 205, 150 | Orientierung. Die Deckungszonen bleiben bewusst im Halbdunkel |

Laternen-Positionen: `Laterne01` Parkplatz (12, 6) · `Laterne02` Straße (10, 91) · `Laterne03` Straße (70, 91).

### Lighting-Service
| Einstellung | Vorher | Nachher |
|---|---|---|
| Technology | – | Future (manuell gesetzt) |
| ClockTime | 14.5 | 18.0 (Dämmerung) |
| Ambient | 0, 0, 0 | 40, 35, 45 |
| Sky | `Sky` + `Stylized` (doppelt) | nur `Stylized` |
| Atmosphere | Density 0.30, Offset 0.25, Glare 0, Haze 0 | Density 0.35, Offset 0.15, Color 210, 165, 140, Decay 95, 85, 120, Glare 0.3, Haze 1.2 |
| Bloom | Intensity 1.0, Threshold 2.0 | Intensity 0.6, Size 24, Threshold 1.6 (fast nur Neon leuchtet) |
| DepthOfField | aus | an, nur leichte Fernunschärfe (Far 0.15, Near 0, Focus 50, Radius 70) |

### Aufräumen
- Standard-`Sky` gelöscht. IDs zur Wiederherstellung: Bk/Ft 6444884337, Up 6412503613, Sun 6196665106, Moon 6444320592.
- Ordner `Workspace.Lighting` mit 4 wirkungslosen Effekten gelöscht (SunRays, DepthOfField, ColorCorrection, Bloom). Post-Processing wirkt nur im Lighting-Service oder in der Camera.

## 4. Constraints
- Alle neuen Parts sind `Anchored = true`.
- Kleine Deko- und Leuchtteile haben `CanCollide = false` und `CastShadow = false`. Laternenmasten bleiben kollidierbar.
- Lichtbudget: 10 von maximal 15 Lights. Alle werfen derzeit Schatten. Bei Performance-Problemen zuerst Shop-Innenlicht und Laternen auf `Shadows = false` setzen.

## 5. Spawn
- `SpawnLocation` von (98, 90) an der Straßenkante nach (66.5, −23.5) an die Nordseite hinter dem Shop verlegt. Von keinem der 60 Straßenpunkte aus sichtbar.
- Der Bereich hinter dem Shop ist nur 6 Studs tief, der Spawn steht 0,5 Studs vom Kartenrand entfernt. Deshalb ist der Rand gesichert (`Props/Begrenzung/ZaunNord`):
  - Maschendrahtzaun (Metallpfosten alle 5 Studs, Oberholm, halbtransparentes Gitter) über die gesamte Nordkante plus 6 Studs an der Ostkante, wo der Gang hinter dem Shop endet.
  - Dahinter eine unsichtbare Wand, 30 Studs hoch, mit `CanQuery = false`, damit Raycasts nicht beeinflusst werden. Spieler können weder durchlaufen noch darüberspringen.

## 6. Phase 3 – Props & Storytelling

| Prop | Ordner | Position | Hinweis |
|---|---|---|---|
| Müllcontainer | `Props/Shop/Müllcontainer01` | Ostwand Shop (89.75, −12) | Metal grün mit dunklem Deckel |
| Kistenstapel | `Props/Shop/Kistenstapel01` | Ostwand Shop (89.5, 0.6) | 3 Kisten WoodPlanks, die oberste leicht gedreht |
| Gasflaschen-Käfig | `Props/Shop/Gasflaschenkäfig01` | Shopfront rechts der Tür (77, 11.6) | Metallrahmen, Gitter halbtransparent, 4 Gasflaschen (`CanCollide = false`) |
| Mülleimer | `Props/Insel/Mülleimer01` | zwischen Gas01 und Gas02 | Zylinder, Metal |
| Preistafel | `Props/Straße/Preistafel` | Straßenrand (35, 89) | Fantasiemarke „NORDSTERN“, 3 Preise per SurfaceGui. Tafel erst ab 8 Studs Höhe |
| Leuchtschild | `Props/Shop/Leuchtschild` | Dachkante über der Tür | „NORDSTERN SHOP“ in Markenrot, Neon-Leuchtleiste, SurfaceGui leuchtet unabhängig vom Licht |
| Tresen | `Props/Shop/Innenraum/Tresen` | rechts hinter der Tür (77, 1.25) | Holzkorpus, Marmorplatte, Kasse mit Neon-Display |
| Regale | `Props/Shop/Innenraum/Regal01`, `Regal02` | linke Shophälfte (x 52 / 58) | Metallregale mit Warenreihen, der Gang von der Tür bleibt frei |
| Feuerlöscher | `Props/Insel/Feuerlöscher01` | Südseite von Säule02 | Mit Halterung an der Säule |
| Scheibenwischer-Eimer | `Props/Insel/WischerEimer01` | Westende Fundament | Eimer mit schräg stehendem Wischer |
| Luftdruckstation | `Props/Insel/Luftdruckstation01` | westlich der Überdachung (10, 30) | Gelbes Gehäuse, Manometer (Neon), Schlauchrolle, Sockel |
| Auto | `Props/Parkplatz/Auto01` | rechte Parkbucht (35.75, −2.5) | Aus Parts: Karosserie, Glas-Kabine, 4 Räder, Scheinwerfer und Rücklichter |
| Ölflecken | `Props/Deko/Ölflecken` (5 Stück) | leere Bucht, unter dem Auto, Fahrspuren der Insel | Flache Scheiben statt Decals: leicht glänzend, ohne Kollision, ohne Schatten |

**Story-Lesart:** Die Tankstelle ist kurz vor Ladenschluss. Ein einzelnes Auto steht noch auf dem Parkplatz, daneben ein alter Ölfleck in der leeren Bucht. An der Insel sind Spuren vom Tagesbetrieb zu sehen (Ölflecken, Wischer im Eimer). Shop-Schild und Preistafel leuchten als Landmarken zur Straße.

**Sichtachsen-Kontrolle** (Methode aus Task 02: 60 Straßenpunkte, Spieler 2 Studs breit, Füße/Torso/Kopf), gemessen vor und nach dem Einbau:

| Messpunkt | sichtbar von | Änderung durch Props |
|---|---|---|
| Hinter Gas01 / Gas02 anliegend | 4 / 6 | keine |
| Shop direkt hinter der Tür | 25 | keine (Gang zur Tür bleibt frei) |
| Shop Mitte / hinten | 15 / 9 | keine |
| Hinter Mauer01 / Kiste01 | 0 / 1 | keine |
| Freifläche zwischen Insel und Shop | 29 | keine |
| Spawn | 0 | keine |
| Parkplatz hinter dem Auto | 35 | neue Teildeckung (vorher 44) |
| Shop zwischen den Regalen | 0 | neue volle Deckung (vorher 1) |
| Shop hinter dem Tresen | 0 | keine |

Die Werte für den Shop liegen unter den Werten aus Task 02. Das liegt an der Tür mit Sturz und den seitdem vergrößerten Deckungen (`Mauer01` 8 × 6 × 1, `Kiste01` 4 × 6 × 8).

## 7. Backlog (optional)
- Eistruhe, Einkaufswagen, Reifenstapel, schiefes Straßenschild.
- Zapfsäulen auf 4–5 Studs verbreitern: Die Deckung funktioniert nur direkt an der Säule (siehe Abschnitt 8).
- Performance: Alle 10 Lights werfen Schatten. Bei Bedarf Shop-Innenlicht und Laternen auf `Shadows = false` setzen.

## 8. Phase 4 – Abschlussprüfung

**Methode** (wie in Task 02): 60 Beobachterpunkte auf der Straße (x −45 bis 100 in 5er-Schritten, z 95 und 108, Augenhöhe 5,7). Der Spieler ist 2 Studs breit und wird an je 3 Höhen gemessen (Füße 1, Torso 2,5, Kopf 4,5). Gezählt wird, von wie vielen der 60 Punkte mindestens ein Messpunkt sichtbar ist. „Nur Torso“ zählt ohne Kopf.

| Messpunkt | Task 02 (nach Optimierung) | Final: voll | Final: nur Torso | Bewertung |
|---|---|---|---|---|
| Hinter Gas01 anliegend | 4 | 4 | 4 | ✅ gute Deckung |
| Hinter Gas02 anliegend | 6 | 6 | 6 | ✅ gute Deckung |
| Hinter Gas02, 2 Studs Abstand | – | 43 | 41 | ⚠️ Deckung nur direkt an der Säule |
| Shop direkt hinter der Tür | 50 | 25 | 25 | ⚠️ bewusst offen (Eingang) |
| Shop Mitte | 19 | 15 | 15 | ✅ verbessert |
| Shop hinten | 11 | 9 | 9 | ✅ verbessert |
| Shop zwischen den Regalen | – | 0 | 0 | ✅ neue volle Deckung |
| Shop hinter dem Tresen | – | 0 | 0 | ✅ volle Deckung |
| Hinter Mauer01 | 0 (Torso) | 0 | 0 | ✅ volle Deckung |
| Hinter Kiste01 | 0 (Torso) | 1 | 0 | ✅ praktisch volle Deckung |
| Freifläche zwischen Insel und Shop | – ¹ | 29 | 26 | ⚠️ Lauffläche, absichtlich exponiert |
| Parkplatz hinter dem Auto | – | 35 | 26 | ⚠️ Teildeckung |
| Spawn | – | 0 | 0 | ✅ nicht einsehbar |

¹ In Task 02 wurde die Freifläche nur mit einem Strahl pro Beobachter gemessen (77 % sichtbar). Das ist mit der 9-Punkte-Methode nicht direkt vergleichbar.

**Ergebnis:**
- Keine Deckung aus Task 02 wurde durch Materialien, Licht oder Props verschlechtert. Gegenüber dem ersten Blockout sind Shop und Freifläche deutlich besser geschützt.
- Die neuen Props schaffen gezielt zusätzliche Deckung (Regale, Tresen, Auto). Freie Sichtachsen haben sie nicht zugebaut: Der Eingang und die Laufwege bleiben einsehbar.

**Integrität:**
| Prüfung | Ergebnis |
|---|---|
| Parts unter `Environment` | 169, alle `Anchored = true` |
| Lichtquellen | 10 (Budget 15), alle mit Schatten |
| Sky-Objekte | 1 (`Stylized`) |
| `Workspace.Lighting` | entfernt |
| Lighting | Technology Future, ClockTime 18.0, Ambient 40, 35, 45 |
| Spawn | (66.5, −23.5), verankert. Die Nordkante (z −26) liegt innerhalb der unsichtbaren Wand (Südkante z −26.5) |

**Freigabe:** Task 03 erfüllt die Ziele. Materialien, Beleuchtung und Props erzählen die Szene „Highway-Tankstelle kurz vor Ladenschluss“, ohne die in Task 02 abgenommene Balance von Scale und Sightlines zu verschlechtern.

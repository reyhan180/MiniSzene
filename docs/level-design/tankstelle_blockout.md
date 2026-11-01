# Praxisprojekt 01 – Gas Station Environment

## 1. Projekt-Übersicht & Layout
- Grundfläche: 150x150 Studs
- Shop Gebäude: 40x30 Studs | Wandhöhe: 10 Studs | Türöffnung: 5x8 Studs inkl. Türsturz
- Zapfsäulen: Parallele Ausrichtung zur Straße | 2 Zapfsäulen (Gas01&Gas02): nebeneinander- Abstand von 10 Studs
- Hauptstraße: Verläuft am Südrand (z: 93,5 bis 123,5) quer über die gesamte Kartenbreite mit gelben Fahrbahnmarkierungen
- Parkplatz & Freifläche: Parkplatz-Bodenplatte neben dem Shop + Parkbuchten-Markierungen; Freifläche zur Straße hin mit zusätzlicher Deckung
- SpawnLocation: An der geschützten Ecke der Karte platziert


## 2. Ordnerstruktur & Constraints
- Alle Objekte sauber eingeordnet unter `Workspace-> Environment` (`Buildings` , `Props` , `Roads`)
- sämtl. statischen Bauteile sind verankert `Anchored=true`
- Z-Fightning-> Anpassung durch Dachtiefe & leichtes Anheben der Starßenmarkierungen vermieden

## 3. Agent-Analyse & Vorher/Nachher-Ergebnisse 

### Scale Check
- Shop Wandhöhe: von 14 Studs auf 10 Studs angepasst -> optimale Avatar-Proportionen
- Türöffnung: von 10 Studs Breite auf 5x8 Studs inkl. Türsturz verengt, um die direkte Sichtachse von der Straße zur Rückwand zu brechen
- Zapfsäulen-Ausrichtung: von hintereinander auf parallel zur Straße gedreht, um 2 getrennte Deckungspunkte zu schaffen

### Sightlines & Cover Check
- Direkt an der Zapfsäule: 6/60 (nur 1 nutzbaren Punkt) -> 4/60 & 6/60 (2 getrennte Punkte) => Zafpsäulen verdecken sich vorher gegenseitig; jetzt 2 Deckungen
- Shop Mitte: 31/60 ->  19/60  => Sichtachse durch schmalere Tür & Türsturz deutlich reduziert
- Shop hinten: 17/60 -> 11/60 => Einsicht in den Innenraum von der Straße erschwert 
- Hinter Mauer / Kiste: Keine Deckung vorhanden -> 0/60 (Volle Deckung) => Kiste (4x6x8) & Mauer (8x6x1) bieten vollständigen Schutz auf der Freifläche

---

## 4. Fazit & Freigabe
Blockout ist bzgl. Proportionalität (Scale) & Sichtachsen (Sightlines) ausbalanciert und erfüllt alle Anforderungen für Task 02
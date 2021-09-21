# SSV-SDU-GUC
How to set up an agent for a given SDU-GUC

## 1 Achitektur
**- SDU Server:** Ein Secure Device Update Server (SDU Server) stellt Firmwareupdates zur verfügung.

**- Client:** Ein Gateway Update Client verwaltet einzelne Agenten und die Kommunikation zum SDU Server.

**- SDU Agent:** Für jedes Produkt ist ein Agent vorhanden und ermöglicht eine Statusabfrage der Firmware auf dem gegebenen Produkt und die eigentliche Installation eines Updates.

![Architektur Guc](https://user-images.githubusercontent.com/59482387/132204706-ce3661f2-0328-4731-bce8-013f67b2ba7d.PNG)
Beschreibung der Architektur

Ein SDU Server stellt Firmwareupdates für einen GUC und dieser zugehörige Agenten für die gewünschten Sensoren / Baugruppen.
Der Code des GUC und des Agenten befinden sich auf einem Raspberry Pi und der Sensor liegt hier in Form eines Sam R30 Mikrocontrollers vor.
Der GUC veranlasst ein Update basierend auf Informationen über die aktuelle Firmware des Sensors. Das Update wird vom SDU Server bezogen und über den GUC zur Installation auf dem sam R30 überprüft und bereitgestellt. Anschließend erfolgt die Installation der neuen Firmware anhand des Agenten auf dem angeschlossenen Sensor.

## 2 Agent implementieren
Implmentierung des bestehenden SDU-GUC

Für jedes neue Produkt wird ein individueller Agent benötigt, dazu hier eine Einführung in den Code: 



## 3 Schnittstelle GUC und Agent
Wie wird der Agent angesprochen, was muss übergeben werden? welche Hilfsmittel werden benötigt?

* **Aufruf**: `/path/to/agent install [version] [sha256]`
   - `[version]`: Versions-String des zu installierenden Updates. Der Agent kann hieran bereits entscheiden, ob das Update akzeptiert wird. Bspw. können darüber Downgrades verhindert werden, wenn die Firmware damit nicht umgehen kann.
   - `[sha256]`: Der SHA256-Hash des Updates. Der Agent muss prüfen, ob die empfangenen Daten tatsächlich diesen Hash bilden. Um einen vollständigen Download zum Prüfen des Hashes zu verhindern (bei großen Update ist das bspw. gar nicht möglich), wird die Prüf-Aufgabe nicht vom Gateway-Update-Client erledigt.
  
## 4 Beispielagent für Sam R30
Beschreiben anhand der Codeschnipsel was passiert
Code link

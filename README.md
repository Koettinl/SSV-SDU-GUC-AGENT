# SSV-SDU-GUC
How to set up an agent for a given SDU-GUC

## 1 Achitektur

![Architektur Guc](https://user-images.githubusercontent.com/59482387/132204706-ce3661f2-0328-4731-bce8-013f67b2ba7d.PNG)
Beschreibung der Architektur

Ein Secure Device Update (SDU) Server stellt Firmwareupdates zur verfügung und ein Gateway Update Client (GUC) verarbeitet diese für mit Hilfe eines Agenten für die gewünschte Baugruppe / den gewünschten Sensor. Dabei befinden sich die Scripte des GUC und des Agenten auf einem Raspberry Pi und der Sensor liegt in Form eines Sam R30 Mikrocontrollers vor.
Der GUC veranlasst ein Update basierend auf den über den Agenten angeforderten Informationen über die aktuelle Firmware des Sensors. Das Update wird vom SDU Server bezogen und über den GUC zur Installation auf dem sam R30 überprüft und bereitgestellt. Anschließend führt der Agent die Installation der neuen Firmware auf dem angeschlossenen Sensor aus.

## 2 Agent implementieren
Implmentierung des bestehenden SDU-GUC

Der gegebene Agent muss für jeden neuen Sensor angepasst werden, dafür erfolgt hier eine kurze Einführung in den Code:
Der Agetn wird wie folgt durch den GUC aufgerufen und prüft folglich die aktuelle Firmware des Sensors. Wenn eine neuere Firmware verfügbar ist, erfolgt ein Updateprozes.
[Code]


## 3 Schnittstelle GUC und Agent
wie wird der agent angesprochen, was muss übergeben werden? welche hilfsmittel werden benötigt?

## 4 Beispielagent für Sam R30
Beschreiben anhand der Codeschnipsel was passiert

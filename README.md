# SSV-SDU-GUC
How to set up an agent for a given SDU-GUC

## 1 Achitektur
Ein SDU Server stellt Firmwareupdates für einen GUC und dieser zugehörige Agenten für die gewünschten Produkte.
Der Code des GUC und des Agenten befinden sich auf einem Raspberry Pi und das Produkt liegt hier in Form eines Sam R30 Mikrocontrollers vor.
Der GUC veranlasst ein Update basierend auf Informationen über die aktuelle Firmware des Produkts. Das Update wird vom SDU Server bezogen und über den GUC zur Installation auf dem Produkt überprüft und bereitgestellt. Anschließend erfolgt die Installation der neuen Firmware anhand des Agenten auf dem angeschlossenen Produkt.

![Architektur Guc](https://user-images.githubusercontent.com/59482387/132204706-ce3661f2-0328-4731-bce8-013f67b2ba7d.PNG)

* **SDU Server:** Ein Secure Device Update Server (SDU Server) stellt Firmwareupdates zur verfügung.

* **Client:** Ein Gateway Update Client verwaltet einzelne Agenten und die Kommunikation zum SDU Server.

* **SDU Agent:** Für jedes Produkt ist ein Agent vorhanden und ermöglicht eine Statusabfrage der Firmware auf dem gegebenen Produkt und die eigentliche Installation eines Updates.

## 2 Schnittstelle GUC und Agent
Wie wird der Agent angesprochen, was muss übergeben werden? welche Hilfsmittel werden benötigt?

Implmentierung für einen bestehenden SDU-GUC

### Versionsabfrage
* **Aufruf**: `/path/to/agent info`
Die Abfrage erlaubt dem SDU-Gateway-Update-Client herauszufinden, welches Produkt der Agent bedient, welche Version installiert ist und ggf. wo ein Abbild der aktuell installierten Version zu finden ist. Letzteres wird benötigt, um Updates per Differenzen zu komprimieren.

### Neue Version

Die Abfrage erlaubt dem SDU-Gateway-Update-Client ein neues Update zu installieren. Dies wird passieren, wenn die Version, die der `info`-Befehl zurück liefert sich von der Version, die der SDU-Server vorsieht, unterscheidet.

* **Aufruf**: `/path/to/agent install [version] [sha256]`
   - `[version]`: Versions-String des zu installierenden Updates. Der Agent kann hieran bereits entscheiden, ob das Update akzeptiert wird. Bspw. können darüber Downgrades verhindert werden, wenn die Firmware damit nicht umgehen kann.
   - `[sha256]`: Der SHA256-Hash des Updates. Der Agent muss prüfen, ob die empfangenen Daten tatsächlich diesen Hash bilden. Um einen vollständigen Download zum Prüfen des Hashes zu verhindern (bei großen Update ist das bspw. gar nicht möglich), wird die Prüf-Aufgabe nicht vom Gateway-Update-Client erledigt.


## 3 Beispielagent für Sam R30
* `info` Die Funktion ist Produktunabhängig.
* `install` ist für jedes neue Produkt zu modifizieren. Hier wird über edbg mit dem Mikrocontroller kommuniziert. Im Code werden Pfade explizit angegeben, damit systemd Aufrufe fehlerfrei möglich sind.

```bash
install_update () {
	local VERSION=$1
	local EXPECTED_SHA256=$2

	# Store update in file
	cat >$FILENAME-$VERSION

	# Check SHA256
	local SHA256
	SHA256=$(get_sha256 $FILENAME-$VERSION)
	[ "$EXPECTED_SHA256" != "$SHA256" ] && return 3

	# Store current version
	echo -n $VERSION >$FILENAME

	# extract bin from .tar and return extracted filename
	local UpdateFile=$(tar -xvf $FILENAME-$VERSION)

	# flash *.bin to samr30 via edbg
	# ~/path/to/edbg -t $BOARD -p -f ~/path/to/*.bin to be installed or flashed
	/home/pi/bin/edbg -t samr30 -pv -f /home/pi/$UpdateFile	
	# write LogFile
	echo -e "$(date -u) samr updated to $VERSION\n" >>/home/pi/sdu_guc_ssv/clients/sam-r30/sam-r30_fwUpdate_logfile.txt
}
```

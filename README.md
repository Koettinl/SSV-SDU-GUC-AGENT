# SSV-SDU-GUC
Tutorail für den Aufbau eines Agenten für ein gegebenes GUC-SDU

## 1 Achitektur
Ein SDU Server stellt Firmwareupdates für einen GUC und dieser verwaltet zugehörige Agenten für die gewünschten Produkte.
Der Code des GUC und des Agenten befinden sich auf einem [Raspberry Pi 4](https://www.raspberrypi.org/products/raspberry-pi-4-model-b/) und das Produkt liegt hier in Form eines [Sam R30](http://ww1.microchip.com/downloads/en/devicedoc/50002612a.pdf) vor.
Der GUC veranlasst zyklische Updates basierend auf Informationen über die aktuelle Firmware des Produktes. Dafür werden `systemd` funktionen genutzt. Das Update wird vom SDU Server bezogen und über den GUC zur Installation auf dem Produkt überprüft und bereitgestellt. Anschließend erfolgt die Installation der neuen Firmware anhand des Agenten auf dem angeschlossenen Produkt.

### 1.1 Hardware Beispiel
Für das beigefügte Beispiel wird der SAMR30 mit Jumperkabeln über die Pins PA06/07 an die Pins 23/24 des Rapsberry Pi angeschlossen. Des weiteren ist der Raspberry Pi mit dem EDBG-USB des SAMR30 zu verbinden.

### 1.2 Software Beispiel
Zur Installation auf einem Raspberry Pi mit Raspbian OS ist lediglich das Kopieren der Dateien mit gegebener Ordnerstruktur notwendig. Um den Ordner und darin enthaltene Skripte ausführbar zu machen, wird folgendes in die Komandozeile eingegeben: `chmod -R 500 path/to/folder/`.
Zur Ausführung eines Updates wird dann das [`sdu-guc-update.sh`](https://github.com/Koettinl/SSV-SDU-GUC-AGENT/blob/main/clients/guc_sdu-update.sh) Skript ausgeführt.
Bei Bedarf kann über Systemd ein zyklischer Aufruf realisiert werden.

![Architektur Guc](https://user-images.githubusercontent.com/59482387/132204706-ce3661f2-0328-4731-bce8-013f67b2ba7d.PNG)

* **SDU Server:** Ein Secure Device Update Server (SDU Server) stellt Firmwareupdates zur verfügung.

* **Client:** Ein Gateway Update Client verwaltet einzelne Agenten und die Kommunikation zum SDU Server.

* **SDU Agent:** Für jedes Produkt ist ein Agent vorhanden und ermöglicht eine Statusabfrage der Firmware auf dem gegebenen Produkt und die eigentliche Installation eines Updates.


## 2 Schnittstelle GUC zu Agent für einen bestehenden SDU-GUC

### Versionsabfrage
* **Aufruf**: [`/path/to/agent info`](https://github.com/Koettinl/SSV-SDU-GUC/blob/eb0e3c7d2ba375e34df7808e4a0e9e3be56c72bb/clients/guc_sdu-update.sh#L117)
Die Abfrage erlaubt dem SDU-Gateway-Update-Client herauszufinden, welches Produkt der Agent bedient, welche Version installiert ist und ggf. wo ein Abbild der aktuell installierten Version zu finden ist. Letzteres wird benötigt, um Updates per Differenzen zu komprimieren.

### Neue Version

Die Abfrage erlaubt dem SDU-Gateway-Update-Client ein neues Update zu installieren, wenn sich die Version, die der `info`-Befehl zurück liefert von der Version, die der SDU-Server vorsieht, unterscheidet.

* **Aufruf**: [`/path/to/agent install [version] [sha256]`](https://github.com/Koettinl/SSV-SDU-GUC/blob/eb0e3c7d2ba375e34df7808e4a0e9e3be56c72bb/clients/guc_sdu-update.sh#L145)
   - `[version]`: Versions-String des zu installierenden Updates. Der Agent kann hieran bereits entscheiden, ob das Update akzeptiert wird. Bspw. können darüber Downgrades verhindert werden, wenn die Firmware damit nicht umgehen kann.
   - `[sha256]`: Der SHA256-Hash des Updates. Der Agent muss prüfen, ob die empfangenen Daten tatsächlich diesen Hash bilden. Um einen vollständigen Download zum Prüfen des Hashes zu verhindern (bei großen Update ist das bspw. gar nicht möglich), wird die Prüf-Aufgabe nicht vom Gateway-Update-Client erledigt.

## 3 Schnittstelle Agent zu Mikrocontroller
* [`edbg`](https://github.com/ataradov/edbg) Linux-Tool zum flashen des Sam R30 xplained pro

### Flashen einer neuen Firmware

* **Aufruf**: `path/to/edbg [options]`
  - `[options]`: Verkettung von Target und [Optionen](https://github.com/ataradov/edbg#usage) zum bearbeiten des Chips und verarbeiten von .bin Dateien.
```bash
# flash *.bin to samr30 via edbg
# ~/path/to/edbg -t <BOARD> -p -f ~/path/to/*.bin to be installed or flashed
/home/pi/bin/edbg -t samr30 -pv -f /home/pi/$UpdateFile	
```
## 4 Beispielagent für Sam R30 xplained pro
* [`info`](https://github.com/Koettinl/SSV-SDU-GUC/blob/eb0e3c7d2ba375e34df7808e4a0e9e3be56c72bb/agents/agent_samr30_sdu-agent-samr30.sh#L19) Die Funktion ist Produktunabhängig.
* [`install`](https://github.com/Koettinl/SSV-SDU-GUC/blob/eb0e3c7d2ba375e34df7808e4a0e9e3be56c72bb/agents/agent_samr30_sdu-agent-samr30.sh#L31) ist für jedes neue Produkt zu modifizieren. Hier wird das Update, das im .tar Format vorliegt, entpackt und über edbg der Mikrocontroller geflasht. Im Code werden Pfade explizit angegeben, damit systemd-Aufrufe fehlerfrei möglich sind.


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
	# /home/pi/path/to/edbg -t <BOARD> -p -f /home/pi/path/to/*.bin to be installed or flashed
	/home/pi/bin/edbg -t samr30 -pv -f /home/pi/$UpdateFile	
	
	# write logfile
	echo -e "$(date -u) samr updated to $VERSION\n" >>/home/pi/sdu_guc_ssv/clients/sam-r30/sam-r30_fwUpdate_logfile.txt
}
```

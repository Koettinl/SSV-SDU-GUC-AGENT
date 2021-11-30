# **SSV-SDU-GUC**
Tutorail für den Aufbau eines Agenten für ein gegebenes GUC-SDU

## **1 Achitektur**
Ein SDU Server stellt Firmwareupdates für einen GUC und dieser verwaltet zugehörige Agenten für die gewünschten Produkte.
Der Code des GUC und des Agenten befinden sich auf einem [Raspberry Pi 4](https://www.raspberrypi.org/products/raspberry-pi-4-model-b/) und das Produkt liegt hier in Form eines [Sam R30](http://ww1.microchip.com/downloads/en/devicedoc/50002612a.pdf) vor.
Der GUC veranlasst zyklische Updates basierend auf Informationen über die aktuelle Firmware des Produktes. Für den zyklischen Aufruf werden `systemd` funktionen genutzt. Das Update wird vom SDU Server bezogen und über den GUC zur Installation auf dem Produkt überprüft und bereitgestellt. Anschließend erfolgt die Installation der neuen Firmware auf dem angeschlossenen Produkt anhand des Agenten.

![Architektur Guc](https://user-images.githubusercontent.com/59482387/132204706-ce3661f2-0328-4731-bce8-013f67b2ba7d.PNG)

* **SDU Server:** Ein Secure Device Update Server (SDU Server) stellt Firmwareupdates zur verfügung.

* **Client:** Ein Gateway Update Client verwaltet einzelne Agenten und die Kommunikation zum SDU Server.

* **SDU Agent:** Für jedes Produkt ist ein Agent vorhanden und ermöglicht eine Statusabfrage der Firmware auf dem gegebenen Produkt und die eigentliche Installation eines Updates.

### **1.1 Hardware Beispiel**
Für das beigefügte Beispiel wird der SAMR30 mit Jumperkabeln über die Pins PA06/07 an die Pins 23/24 des Rapsberry Pi angeschlossen. Des weiteren ist der Raspberry Pi mit dem EDBG-USB des SAMR30 zu verbinden.
Im [`Ordner`](https://github.com/Koettinl/SSV-SDU-GUC-AGENT/tree/as-sdu-v2/agent/samr30/assets/examples/sam-r30/bin) befinden sich zwei .bin Dateien als Firmware zum Test eines Updatezyklus. Jede Firmware lässt jeweils eine andere LED leuchten, sodass optisch geprüft werden kann, ob ein Update erfolgreich abgeschlossen wurde.

### **1.2 Software Beispiel**
Dieses Softwarebeispiel funktioniert auf einem Raspberry Pi mit Raspian os und dem default Benutzer *Pi*. Wenn ein anderer Benutzer verwendet wird, müssen alle `$FILEPATH` mit dem entsprechenden Benutzer angepasst werden.
Bei Bedarf kann über Systemd ein zyklischer Aufruf realisiert werden.

### **1.2.1 Install**

```bash
# all FILEPATHS have to be adaptet to user name of the used Pi,
# also in all *.sh
cd /home/pi
git clone https://github.com/Koettinl/SSV-SDU-GUC-AGENT.git

# go to folder
cd SSV-SDU-GUC-AGENT
# make all scripts executable within the folder
find . -type f -name *.sh -exec chmod 0775 {} \;
```
Folgend wird [`edbg`](https://github.com/ataradov/edbg), ein Linux-Tool zum flashen des Sam R30 xplained pro, installiert.
```bash
# install all necessary dependencies for edbg
sudo apt-get install git build-essential libudev-dev
sudo apt-get update

# clone the edbg Gitrepo 
cd /home/pi
git clone https://github.com/ataradov/edbg.git
cd edbg
make all

# copy the edbg.bin into the bin folder
mkdir -p /home/pi/bin
cp edbg /home/pi/bin/edbg
```

### **1.2.2 Run**
```bash
# execution of a single update cycle
/home/pi/SSV-SDU-GUC-AGENT/guc/app/update.sh
```

## **2 SDU Agent**

SDU-Agent ist ein speziell für den jeweiligen Updateprozess, eine Komponente/Maschine/Anlage, erstelltes Programm. Der Agent wird im Gateway vom GUC (Gateway Update Client) ausgeführt/bedient und bietet dazu eine spezielle Schnittstelle (ADU-Agent API). Es können mehrere Agenten im System installiert werden.

### **2.1 SDU-Agent API**
Ein SDU-Agent hat folgende Aufgaben:

* Auskunft geben über die aktuell installierte Version
* Eine neue Version installieren

Die Kommunikation erfolgt durch Aufrufparameter, Standard Input/Output/Error und Exit Code des Programms.

### Aktuelle Version abfragen

Die Abfrage erlaubt dem SDU-Gateway-Update-Client herauszufinden, welches Produkt der Agent bedient, welche Version installiert ist und ggf. wo ein Abbild der aktuell installierten Version zu finden ist. Letzteres wird benötigt, um Updates per Differenzen zu komprimieren.

* **Aufruf**: `/path/to/agent info`
* **STDOUT**:
```js
{
	"product": "rmg941",
	"version": "3.2.5", // Optional (nicht angegeben -> auf jeden Fall updaten)
	"path": "/dev/mmcblk0p3", // Optional
	"sha256": "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" // Optional
}
```
* **STDERR**: Fehlermeldungen für den Fall, dass der Exit-Code nicht 0 ist.
* **Exit**:
   - `0`: OK
   - `1`: Busy
   - `2`: WrongConfiguration

### **Neue Version schreiben**

Die Abfrage erlaubt dem SDU-Gateway-Update-Client ein neues Update zu installieren. Dies wird passieren, wenn die Version, die der `info`-Befehl zurück liefert sich von der Version, die der SDU-Server vorsieht, unterscheidet.

* **Aufruf**: `/path/to/agent install [version] [sha256]`
   - `[version]`: Versions-String des zu installierenden Updates. Der Agent kann hieran bereits entscheiden, ob das Update akzeptiert wird. Bspw. können darüber Downgrades verhindert werden, wenn die Firmware damit nicht umgehen kann.
   - `[sha256]`: Der SHA256-Hash des Updates. Der Agent muss prüfen, ob die empfangenen Daten tatsächlich diesen Hash bilden. Um einen vollständigen Download zum Prüfen des Hashes zu verhindern (bei großen Update ist das bspw. gar nicht möglich), wird die Prüf-Aufgabe nicht vom Gateway-Update-Client erledigt.
* **STDIN**: Datenstrom des neuen Images
* **STDERR**: Statusmeldungen über den aktuellen Schritt
* **STDOUT**: Aktionen, die dem GUC mitgeteilt werden können
   - `REBOOT`: Neustart des Gateways nach dem erfolgreichen Update
* **Exit**:
   - 0: Done
   - 1: Failed
   - 2: RejectWrongVersion
   - 3: RejectWrongSHA256


## 3 edbg als Schnittstelle von Agent zu Mikrocontroller 

### 3.1 Flashen einer neuen Firmware

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

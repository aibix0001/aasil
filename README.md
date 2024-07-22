# aasil - aibix' awesome setup (for) ISP learning
Dies ist eine Sammlung von Scripten, die dazu geeignet sind auf dem Proxmox PVE eine Anzahl miteinander vernetzter vyos-VMs zu erstellen.
Diese sind zum Beispiel dazu geeignet sich mit ISP Routing zu beschäftigen.

Voraussetzung ist ein python3-environment mit ansible und paramiko. 
Siehe requirements.txt

Ebenso vonnöten sind folgende Bridges (oder VXLANs)
MGMT
P1
P2
P3
die Px Bridges bzw. deren VNets (bei VXLAN) sollen eine MTU von 1950 haben und VLAN aware sein.
MGMT kann 1500 und nicht VLAN aware sein.

Ich habe dasa Prefix 10.20.30.0/24 für mgmt vorgesehen, das kann natürlich beliebig geändert werden.
Allerdings muss dann create-vm-vyos.sh angepasst werden, sonst stehen die falschen IPs in der DHCP-Vorlage.

Die derzeit aktuelle Version von Paramiko hat eine lästige Warnung dass 3DES veraltet ist.
3DES wird nicht verwendet, die Warnung entsteht beim importieren des Moduls und kann ignoriert werden.

## Folgende Programme sind beteiligt
- create-provider.sh
    ### Das Programm hat drei erforderliche und einen optionalen Parameter:
    - node: eine Nummer die den node (bei einem möglichen cluster-setup) beziffert
    - provider: der provider (eine numer, vorgesehen sind max 3 ISP/provider, da sonst die automatishe Zuordnung von VLANs nicht mehr funktioniert)
    - router: wieviele Router sollen erstellt werden (derzeit am besten 8 einstellen, andere Anzahl ist möglich, braucht dann aber Anpassung)
    - ansible_limit. zb. "-l p1r1v" um nur p1r1v zu bearbeiten. Bitte *mit* den "" angeben.

    ### Sowie ein paar weitere Anforderungen
    - Mind. eine vyos ISO (bestenfalls neuer als die qcow) im Ordner vyos-iso, damit das Update während der Ausführung funktioniert.
    - eine seed.iso, siehe Ordner seed-iso

    ### Weiterhin werden nach dem erstellen der VMs einige ansible-Scripte ausgeführt:
    - vyos_setup.yml (initiales Setup, Hostname, mgmt-vrf, SSH)
    - vyos_finish.yml (erforderlich weil vyos_setup.yml derzeit beim aktivieren des VRF abbricht)
    - vyos_update.yml -> selbsterklärend
    - vyos_reboot.yml -> ditto

- create-vm-vyos.sh
    Das Programm wird von create-prider.sh aufgerufen und hat folgende Voraussetzungen
    - ein vyos qcow2 Image zum importieren in die zu erstellenden VMs. Dieses Image kann gebaut werden mit dem git-repo das im Ordner vyos-qcow in der readme verlinkt ist.
    - im Programm ist derzeit hardcoded die Topology des Versuchsnetzes beschrieben (Zeile 37):
        - vlanid=$(./vlans3.sh 8 2 ${router} ${net} ${provider})
        - Hier sind die 8 die Anzahl Router und die 2 die Anzahl Reihen, damit das vlans3.sh die richiteg VLAN IDs generieren kann
        - Es wird also eine typische Topologie erstellt, die man immer wieder in Beispielen oder Kursen antrifft:
        - 8 Router in einer 4 (brei) x 2 (hoch) Anordnung. Hier kann man experimentieren mit anderen Topologien, zb "9 3" o.a.
        - Es sollte immer ein Gitter ergeben in dessen Spalten oder Zeilen keine Router fehlen, es sollte also immer rechteckig aussehen
        - Funktionierende Beipiele wären zb. 4 2 (für 2x2 Router) oder 6 2 (für 3x2 Router) oder 9 3 (für 3x3 Router) usw.

### Zur weiteren Einführung kommt ein youtube-Video das dann hier verlinkt wird.

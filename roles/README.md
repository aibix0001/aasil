# rollen für die initiale config der VMs
Hier werden das mgmt-vrf und der SSH Dienst sowie der Hostname gesetzt

## fixme
Aktuell gibt es zwei Rollen
- vyos_setup
- vyos_finish

Das ist weil vyos_setup nach dem Konfigurieren des mgmt-VRF in einen Timeout läuft
vyos_finish setzt da wieder an und speichert die Einstellungen vor einem Reboot der VM
(das tut vyos_setup nach Abbruch nicht, daher geht sonst die Konfig verloren)

Das kann man sicherlich eleganter lösen, aber so funktioniert es erstmal.
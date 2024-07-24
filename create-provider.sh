#!/bin/bash

##
## provider.sh erstellt eine Anzahl VMs auf einem Proxmox-Host um ein ISP-Netzwerk zu erstellen.
##

## SSH beschwert sich wenn man die VMs ein paar mal auf- und abbaut wegen der Host-Keys
export ANSIBLE_HOST_KEY_CHECKING=False

## 
## Kommandozeilen-Parameter (unnamed)
## 
## Variablem um die VM-ID zu bauen
## node falls mehr als ein node vorhanden ist
node=$1
provider=$2
## aus wievielen Routern soll das Gitter bestehen?
## Vorsicht! Das ansible inventory muss dazu passen!
routers=$3
rows=$4
## nur bestimmte VMs bearbeiten
ansible_limit=$5


## Funktion zum warten auf reboots nach Installation, Update und Config
sleeping ()
{
    for r in $(seq 1 $2)
    do
        runs=1
        while true
        do
            ansible p$1r${r}v -m ping -u vyos | grep -q pong && break
            echo ${runs}
            if [[ ${runs} -eq 24 ]]
            # VM neu starten falls sie nicht funktioniert, kann helfen bei langsameren pve
            then
                echo "VM ${node}0${provider}00${r} reagiert nicht, starte neu"
                sudo qm reset ${node}0${provider}00${r}
                runs=0
            fi
            ((runs++))
        done
	echo "Router ${r} in Betrieb"
    done
}

## neue VMs erstellen
echo "Erstelle VMs"
for r in $(seq 1 ${routers})
do
    sudo bash create-vm-vyos.sh -c create -n ${node} -p ${provider} -r ${r}
    sudo qm start ${node}0${provider}00${r}
	# evtl. vorhandene public keys in known_host entfernen
    ssh-keygen -f "/home/aibix/.ssh/known_hosts" -R "10.20.30.${provider}${r}"
done

#exit 1

## sleeping
echo "Warte auf ersten Start"
sleeping $provider $routers

## update and reboot
echo "System Upgrade"
ansible-playbook -i inventories/inventory${provider}.yml vyos_update.yml -e "vyos_version=$(ls -t vyos-iso/vyos* | head -n 1 | sed -e 's/^vyos-iso\/vyos-//' | sed -e 's/-amd.*$//')" $ansible_limit

## sleeping
echo "Warte auf zweiten Start"
sleeping $provider $routers

## configuring
echo "Konfiguriere Hostname, ssh, mgmt-vrf"
ansible-playbook -i inventories/inventory${provider}.yml vyos_setup.yml $ansible_limit
ansible-playbook -i inventories/inventory${provider}.yml vyos_finish.yml $ansible_limit

## remove cdrom
echo "Entferne seed.iso (cloud-init) CD aus dem Laufwerk"
for r in $(seq 1 ${routers})
do
    sudo qm set ${node}0${provider}00${r} --ide2 media=cdrom,file=none
done

## reboot (muss nicht sein, aber mal checken schadet ja nicht)
echo "Warte auf dritten Start"
ansible-playbook -i inventories/inventory${provider}.yml vyos_reboot.yml $ansible_limit
sleeping $provider $routers

echo "Fertig."


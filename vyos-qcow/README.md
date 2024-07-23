# vyos-qcow
Hier muss ein lauffähiges vyos qcow2 Image rein, das erstellt man am besten in einer VM, da die Installation der nötigen Voraussetzungen sich auf dem Proxmox nicht durchführen lässt (das würde pve entfernen!!!).

## Hier ist die Anleitung:
https://github.com/vyos/vyos-vm-images
https://docs.vyos.io/en/latest/automation/cloud-init.html

### In einer Debian-VM folgendes ausführen
```
apt update && apt full-upgrade
apt install curl git ansible
git clone https://github.com/vyos/vyos-vm-images.git
curl -fL https://github.com/vyos/vyos-rolling-nightly-builds/releases/download/1.5-rolling-202407100021/vyos-1.5-rolling-202407100021-amd64.iso -o /tmp/vyos.iso
cd vyos-vm-images
sed -i '/download-iso/p' qemu.yml
sudo ansible-playbook qemu.yml -e disk_size=10 -e iso_local=/tmp/vyos.iso -e grub_console=serial -e vyos_version=1.5.0 -e cloud_init=true -e cloud_init_ds=NoCloud
```

Die daraus resultierende ISO /tmp/vyos-1.5.0-cloud-init-10G-qemu.qcow2 dann in das Verzeichnis vyos-qcow/ legen um die VMs zu erstellen.
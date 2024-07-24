#!/bin/env bash

set -euo pipefail
while getopts c:n:p:r: flag
do
    case "${flag}" in
	c) command=${OPTARG};;
	n) node=${OPTARG};;
	p) provider=${OPTARG};;
	r) router=${OPTARG};;
    esac
done

echo "vmid:${node}0${provider}00${router} provider:${provider} router:${router}"

if [[ -n "${node+set}" && "${provider+set}" && "${router+set}" ]]
then
    vmid=${node}0${provider}0`printf '%02d' $router`
    mgmtmac=00:24:18:A${provider}:`printf '%02d' $router`:00

    case "${command}" in
	create)
	    vmid=${node}0${provider}0`printf '%02d' $router`
	    ## Create VM, import disk and define boot order
	    qm create $vmid --name "p${provider}r${router}v" --ostype l26 --memory 2048 --balloon 2048 --cpu cputype=x86-64-v2-AES --cores 2 --scsihw virtio-scsi-single --net0 virtio,bridge=ABXMGMTN,mtu=1500,macaddr="${mgmtmac}"
	    qm importdisk $vmid vyos-qcow/vyos-1.5.0-cloud-init-10G-qemu.qcow2 local-zfs
	    qm set $vmid --virtio0 local-zfs:vm-$vmid-disk-0,iothread=1
	    qm set $vmid --boot order=virtio0
	    qm set $vmid --serial0 socket
		qm set $vmid --tags "ISP${provider}"
	    ## add interfaces to the router
	    for net in {1..4}
	    do
		if [[ ${router} == 1 && ${net} == 1 ]]
		then
		    qm set $vmid --net${net} virtio,bridge=vmbr0,mtu=1500,macaddr=00:${node}4:18:F${provider}:`printf '%02d' $router`:`printf '%02d' $net`
		else
			vlanid=$(./vlans3.sh 8 2 ${router} ${net} ${provider})

			# check ob vlanid länger als 3 zeichen ist
			# (dann ist es ein "externes" interface und bekommt standard mtu)
			if [ "${#vlanid}" -lt 4 ]
			then
				newmtu=1528
			else
				newmtu=1500
			fi

			qm set $vmid --net${net} virtio,bridge=ABXP${provider}VXN,mtu=${newmtu},tag=${vlanid},macaddr=00:${node}4:18:F${provider}:`printf '%02d' $router`:`printf '%02d' $net`
		fi
	    done
	    ## Import seed.iso for cloud init
		qm set $vmid --ide2 media=cdrom,file=/var/lib/vz/template/iso/seed.iso
	    
	    qm set $vmid --onboot 1

		# dhcp config for fixed mgmt ip for kea dhcp-server
	    echo "                {
                    \"hw-address\": \"${mgmtmac}\",
                    \"ip-address\": \"10.20.30.${provider}${router}\",
                    \"client-classes\": [ \"KnownClients\" ]
                }," >> dhcp/kea-dhcp-static-config.txt

		# dhcp config for fixed mgmt ip for isc dhcp-server
		echo "host p${provider}r${router}v {
  hardware ethernet ${mgmtmac};
  fixed-address 10.20.30.${provider}${router};
}" >> dhcp/isc-dhcp-static-config.txt

	    ;;

	destroy)
	    qm stop $vmid && qm destroy $vmid
	    ;;

	dhcp)
	    echo "                {
                    \"hw-address\": \"${mgmtmac}\",
                    \"ip-address\": \"10.20.30.${provider}${router}\",
                    \"client-classes\": [ \"KnownClients\" ]
                },"
	    ;;

	*)
	    echo "hi there, possible commands are create and destroy"
	    ;;
    esac

else
    echo "something went wrong"

fi




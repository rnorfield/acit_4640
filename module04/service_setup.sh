#!/bin/bash

NET_NAME="net_4640"
VM_NAME="VM_ACIT4640"
PXE_NAME="PXE_4640"
clean_all () {
	vbmg natnetwork remove --netname "$NET_NAME"
	vbmg unregistervm "$VM_NAME" --delete
}

vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

create_network () {
	vbmg natnetwork add --netname "$NET_NAME" \
		--network 192.168.250.0/24 \
		--dhcp off \
		--enable \
		--port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22" \
		--port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80" \
		--port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443" \
		--port-forward-4 "ssh2:tcp:[]:50222:[192.168.250.200]:22"
}

create_vm () {
	vbmg createvm --name "$VM_NAME" --ostype "RedHat_64" --register
	vbmg modifyvm "$VM_NAME" --memory 1536 --nic1 natnetwork \
		--cableconnected1 on \
		--nat-network1 "$NET_NAME" \
		--boot1 disk --boot2 net --boot3 none --boot4 none \
		--audio none

	SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
	VBOX_FILE=$(vbmg showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
	VM_DIR=$(dirname "$VBOX_FILE")

	vbmg createmedium disk --filename "$VM_DIR"/"$VM_NAME".vdi \
		--format VDI \
		--size 10000

	vbmg storagectl "$VM_NAME" --name "Controller1" --add sata \
		--bootable on

	vbmg storageattach "$VM_NAME" --storagectl "Controller1" \
		--port 0 --device 0 \
		--type hdd \
		--medium "$VM_DIR"/"$VM_NAME".vdi

	vbmg storageattach "$VM_NAME" --storagectl "Controller1" \
		--type dvddrive --medium emptydrive \
		--port 1 --device 0
}

setup_pxe () {
	vbmg startvm "$PXE_NAME"
	while /bin/true; do
	        ssh -i ~/.ssh/acit_admin_id_rsa -p 50222 \
	            -o ConnectTimeout=2 -o StrictHostKeyChecking=no \
        	    -q admin@localhost exit
	        if [ $? -ne 0 ]; then
                	echo "PXE server is not up, sleeping..."
                	sleep 2
        	else
			echo "PXE server is up!"
                	break
        	fi
	done
	echo "Copy files now"
	scp -i ~/.ssh/acit_admin_id_rsa -P 50222 \
		-o ConnectTimeout=2 -o StrictHostKeyChecking=no \
		-r files admin@localhost:/home/admin
	echo "move appsetup"
	ssh -i ~/.ssh/acit_admin_id_rsa -p 50222 \
		-o ConnectTimeout=2 -o StrictHostKeyChecking=no \
		-q admin@localhost \
		"sudo mv /home/admin/files/app_setup.sh /var/www/lighttpd/app_setup.sh && exit"
	echo "move ks"
	ssh -i ~/.ssh/acit_admin_id_rsa -p 50222 \
		-o ConnectTimeout=2 -o StrictHostKeyChecking=no \
		-q admin@localhost \
		"sudo mv /home/admin/files/ks.cfg /var/www/lighttpd/ks.cfg && exit"
	echo "move files folder"
	ssh -i ~/.ssh/acit_admin_id_rsa -p 50222 \
		-o ConnectTimeout=2 -o StrictHostKeyChecking=no \
		-q admin@localhost \
		"sudo mv /home/admin/files /var/www/lighttpd/ && exit"
	echo "Starting VM"
	vbmg startvm "$VM_NAME"
}



clean_all
create_network
create_vm
setup_pxe

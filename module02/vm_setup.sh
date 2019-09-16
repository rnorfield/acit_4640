#!/bin/bash -x
vbmg () { VBoxManage.exe "$@"; }
export PATH=/mnt/c/Program\ Files/Oracle/VirtualBox:$PATH
setup_system () { 
	echo "Configuring system";
	vbmg createvm --name "VM_ACIT_4640" --register
	vbmg modifyvm "VM_ACIT_4640" --ostype RedHat_64 --cpus 1 --memory 1024 --audio none --nic1 natnetwork --nat-network1 "net_4640" --cableconnected1 on;
	VM_DIR=$(vbmg showvminfo "VM_ACIT_4640" | grep -m 1 -h '^Config' | head -1 | sed 's/^Config file:\s*//' | sed 's/\.[^.]*$//');
	echo $VM_DIR;
	vbmg createmedium disk --filename "${VM_DIR}/VM_ACIT_4640.vdi" --size 10240 --format VDI;
	vbmg storagectl "VM_ACIT_4640" --name "SATA Controller" --add sata --controller IntelAHCI;
	vbmg storageattach "VM_ACIT_4640" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "${VM_DIR}/VM_ACIT_4640.vdi";
	vbmg storagectl "VM_ACIT_4640" --name "IDE Controller" --add ide;
	vbmg storageattach "VM_ACIT_4640" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium emptydrive;
}
install_packages () { echo "Installing packages"; }
install_app () { echo "Installing app"; }
setup_app () { echo "Configuring app"; }

setup_system
install_packages
install_app
setup_app

echo "DONE!"


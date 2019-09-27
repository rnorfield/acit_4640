#!/bin/bash

VM_NAME="VM_ACIT4640"
USER="admin"
setup_system () {
	echo "Configuring system";
	useradd "$USER";
	sed -r -i 's/^(%wheel\s+ALL=\(ALL\)\s+)(ALL)$/\1NOPASSWD: ALL/' /etc/sudoers;
	usermod -aG wheel "$USER";
	echo "admin:$6$wxik4aL4mCfNrC3e$T1JS9RBwQcmHVOsM.DzmZ22FDtzYAGnO90Kq/eLBlt/8O3wBuXriKnMN70wC74wVkfTMRV8kNbNp6voKRlwhX0" | chpasswd -e;
	cat setup_files/acit_admin_id_rsa.pub >> ~admin/.ssh/authorized_keys;
	ssh -copy_id -i  "$VM_NAME" admin@localhost;
}
install_packages () {
	echo "Installing packages";
	yum install epel-release vim git tcpdump curl net-tools bzip2;
	yum update;
	#Firewall config
	firewall-cmd --zone=public --add-service=http;
	firewall-cmd --zone=public --add-service=https;
	firewall-cmd --zone=public --add-service=ssh;
	firewall-cmd --runtime-to-permanent;
	#Disable SELinux
	setenforce 0;
	sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config;
	#Web service
	useradd -m -r todo-app && passwd -l todo-app;
	yum install nodejs npm;
	yum install mongodb-server;
	systemctl enable mongod && systemctl start mongod;
}
install_app () {
	echo "Installing app";
	su - todo-app;
	mkdir app
	cd app;
	git clone https://github.com/timoguic/ACIT4640-todo-app.git;
	npm install;
	cp -f ../setup_files/database.js config/database.js;
	curl -s localhost:8080/api/todos | jq;
	exit;
}
setup_app () {
	echo "Configuring app";
	yum install nginx;
	systemctl enable nginx;
	systemctl start nginx;
	cp setup_files/todoapp.service /lib/systemd/system;
	systemctl daemon-reload;
	systemctl enable todoapp;
	systemctl start todoapp;
}

setup_system
install_packages
install_app
setup_app

echo "DONE!"

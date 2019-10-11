#!/bin/bash

create_account () {
	useradd -m admin
	echo "admin:P@ssw0rd" | chpasswd
	usermod -aG wheel admin

	cp /tmp/sudoers /etc/sudoers
	chown root:root /etc/sudoers
	chmod 440 /etc/sudoers
}

setup_firewall () {
	systemctl start firewalld
	firewall-cmd --zone=public --add-service=http
	firewall-cmd --zone=public --add-service=ssh
	firewall-cmd --zone=public --add-service=https
	firewall-cmd --runtime-to-permanent
	setenforce 0
}

create_todo_app_user () {
	useradd -m -r todo-app && passwd -l todo-app
	systemctl enable mongod && systemctl start mongod
}

application_setup () {
	mkdir -p /home/todo-app/app
	git clone https://github.com/timoguic/ACIT4640-todo-app.git /home/todo-app/app
	cd /home/todo-app/app && npm install
	cp /tmp/database.js /home/todo-app/app/config/database.js
	chown -R todo-app /home/todo-app/app
}

production_setup () {
	chmod a+rx /home/todo-app
	mkdir /etc/nginx/
	cp /tmp/nginx.conf /etc/nginx/nginx.conf
	systemctl enable nginx && systemctl start nginx
	cp /tmp/todoapp.service /lib/systemd/system
	systemctl daemon-reload
	systemctl enable todoapp
	systemctl start todoapp
}

create_account
setup_firewall
setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config
create_todo_app_user
application_setup
production_setup

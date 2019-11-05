#!/bin/bash
setup_firewall () {
	firewall-cmd --zone=public --add-service=http
	firewall-cmd --zone=public --add-service=ssh
	firewall-cmd --zone=public --add-service=https
	firewall-cmd --runtime-to-permanent
}

create_todo_app_user () {
	useradd -m -r todoapp && passwd -l todoapp
	systemctl enable mongod && systemctl start mongod
}

application_setup () {
	mkdir -p /home/todoapp/app
	git clone https://github.com/timoguic/ACIT4640-todo-app.git /home/todoapp/app
	cd /home/todoapp/app && npm install
	sed -r -i 's/CHANGEME/acit4640/g' /home/todo-app/app/config/database.js
    cd /home/
	cp /home/admin/files/database.js /home/todoapp/app/config/database.js
	chown -R todoapp:todoapp /home/todoapp/app
}

production_setup () {
	yum -y install nginx
	chmod a+rx /home/todoapp
	cp /home/admin/files/nginx.conf /etc/nginx/nginx.conf
	systemctl enable nginx
	systemctl start nginx
	cp /home/admin/files/todoapp.service /lib/systemd/system
	systemctl daemon-reload
	systemctl enable todoapp
	systemctl start todoapp
	systemctl restart nginx
}

setup_firewall
setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config
create_todo_app_user
application_setup
production_setup
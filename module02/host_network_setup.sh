#!/bin/bash -x
vbmg () { VBoxManage.exe "$@"; }
export PATH=/mnt/c/Program\ Files/Oracle/VirtualBox:$PATH
vbmg natnetwork add --netname net_4640 --network "192.168.250.0/24" --enable
vbmg natnetwork modify --netname net_4640 --dhcp off
vbmg natnetwork modify \
  --netname net_4640 --port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22"
vbmg natnetwork modify \
  --netname net_4640 --port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80"
vbmg natnetwork modify \
  --netname net_4640 --port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443"
vbmg natnetwork start --netname net_4640


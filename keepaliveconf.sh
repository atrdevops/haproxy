#! /bin/bash

if [ "$(rpm -qa |grep -c keepalived)" != "1" ]; then
	/usr/bin/yum install -y keepalived
fi

if ! [ -f /etc/firewalld/services/haproxy.xml ]; then
echo """<?xml version="1.0" encoding="utf-8"?>
<service>
<short>HAProxy</short>
<description>HAProxy load-balancer</description>
<port protocol="tcp" port="80"/>
</service>""" >> /etc/firewalld/services/haproxy.xml
fi

/usr/bin/cd /etc/firewalld/services
/usr/bin/restorecon haproxy.xml
/usr/bin/chmod 640 haproxy.xml




echo """
about to configure keepalive vip ip..
"""
echo """
is this the master node or backup node? type 1 for master (haproxy1) and 2 for backup (haproxy2)
"""

read -r whichnode

if [ "$whichnode" == "1" ]; then
	whichnode=MASTER
elif [ "$whichnode" == "2" ]; then
	whichnode=BACKUP
else
	echo "wrong input. exiting"
	exit 1
fi

echo "how many vip ip's would you like to configure?"

read -r ipnum

iplist=()
nicnames=()

for (( i=0; i<ipnum; i++ )); do
	k=$(expr $i + 1)
	echo """enter ip address $k. if you use subnetting enter with '\<subnet>' otherwize ip will be with default subnet.
e.g.: 192.168.10.3/25
"""
	read -r ipaddress
	iplist[$i]=$ipaddress
	echo """
enter nic device name for ip address $k. (e.g. if vip address belongs to the network that
was configured on eth3 then type: eth3
"""
	read -r nicname
	nicnames[$i]=$nicname
done

for (( i=1; i<=ipnum; i++ )); do
	k=$(expr $i - 1)
	echo """vrrp_script chk_haproxy$i {
  script "killall -0 haproxy" # check the haproxy process
  interval 2 # every 2 seconds
  weight 2 # add 2 points if OK
}

""" >> /etc/keepalived/chkscripts

echo """vrrp_instance VI_1 {
  interface ${nicnames[$k]} # interface to monitor
  state MASTER # MASTER on haproxy1, BACKUP on haproxy2
  virtual_router_id 51
  priority 101 # 101 on haproxy1, 100 on haproxy2
  virtual_ipaddress {
    ${iplist[$k]}
  }
  track_script {
    chk_haproxy$i
  }
}

""" >> /etc/keepalived/ip_conf

done

cat /etc/keepalived/chkscripts > keepalived.conf
cat /etc/keepalived/ip_conf >> keepalived.conf

rm -f /etc/keepalived/chkscripts /etc/keepalived/ip_conf

if [ "$whichnode" == "BACKUP" ]; then
	sed -i 's/state MASTER/state BACKUP/g' /etc/keepalived/keepalived.conf
fi

systemctl restart keepalived

echo "keepalived configuration is completed."

#eof

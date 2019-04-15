#! /bin/bash

home1="/var/tmp"

/usr/bin/yum install -y epel-release net-tools tcpdump httpd gcc pcre-static pcre-devel openssl-devel openssl


tar zxvf $home1/haproxy-1.9.4_with_openssl.tar.gz

cd $home1/haproxy-1.9.4

make TARGET=linux2628

make install

mkdir -p /etc/haproxy
mkdir -p /var/lib/haproxy
touch /var/lib/haproxy/stats
mkdir -p /run/haproxy
ln -s /usr/local/sbin/haproxy /usr/sbin/haproxy



cp $home1/haproxy-1.9.4/examples/haproxy.init /etc/init.d/haproxy
chmod 755 /etc/init.d/haproxy

/sbin/chkconfig haproxy on




systemctl daemon-reload; wait

/usr/sbin/useradd -r haproxy




firewall-cmd --permanent --add-service=haproxy
firewall-cmd --reload



echo "haproxy installation was suuessfull"

#EOF
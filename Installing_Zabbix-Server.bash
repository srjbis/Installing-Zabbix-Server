########### Update yum ##########
yum update -y

########### Installing httpd service #######
yum -y install httpd
systemctl start httpd
systemctl enable httpd
netstat -plntu | grep httpd

########### Installing EPEL latest release #########
yum -y install https://mirror.webtatic.com/yum/el7/epel-release.rpm

########### Upgrading the PHP latest release #########
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum -y install mod_php72w php72w-cli php72w-common php72w-devel php72w-pear php72w-gd php72w-mbstring 
yum -y install php72w-mysql php72w-xml php72w-bcmath

########### Changing the php.ini ##############
sed -i "s/^max_execution_time =.*/max_execution_time = 600/g" /etc/php.ini
sed -i "s/^max_input_time =.*/max_input_time = 600/g" /etc/php.ini
sed -i "s/^memory_limit =.*/memory_limit = 256M/g" /etc/php.ini
sed -i "s/^post_max_size =.*/post_max_size = 32M/g" /etc/php.ini
sed -i "s/^upload_max_filesize =.*/upload_max_filesize = 16M/g" /etc/php.ini
sed -i "s/^;date.timezone =/date.timezone = America\/New_York/g" /etc/php.ini
scp /usr/share/zoneinfo/America/New_York /etc/localtime
systemctl restart httpd

########### Installing Maria DB server ############
yum -y install mariadb-server
systemctl start mariadb
systemctl enable mariadb

########### Configuring mysql for zabbix-server ##################
echo -e "\nnone\nY\nzabbix\nzabbix\nn\nn\nn\nY\n " | mysql_secure_installation 2>/dev/null
mysql -uroot -pzabbix -e "create database zabbix;"
mysql -uroot -pzabbix -e "grant all privileges on zabbix.* to zabbix@'localhost' identified by 'zabbix';"
mysql -uroot -pzabbix -e "grant all privileges on zabbix.* to zabbix@'%' identified by 'zabbix';"
mysql -uroot -pzabbix -e "flush privileges;"

########### Installing zabbix latest release ############# 
yum -y install http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-1.el7.centos.noarch.rpm
yum -y install zabbix-get zabbix-server-mysql zabbix-web-mysql zabbix-agent

########### MySQL queries for zabbix database table's ############
gunzip `find /usr/share/doc/ -name "zabbix-server-mysql*"`/create.sql.gz
mysql -uroot -pzabbix zabbix < `find /usr/share/doc/ -name "zabbix-server-mysql*"`/create.sql

########### Configuring zabbix_server.conf #################

sed -i "s/^# DBPassword=/DBPassword=zabbix/g" /etc/zabbix/zabbix_server.conf
systemctl start zabbix-server
systemctl enable zabbix-server

########### Configuring zabbix_agentd.conf #################
sed -i "s/^Hostname=.*/Hostname=`echo "$(hostname)"`/g" /etc/zabbix/zabbix_agentd.conf
systemctl start zabbix-agent
systemctl enable zabbix-agent

########### Installing and Configuring Firewall ###########
yum -y install firewalld
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --add-service={http,https} --permanent
firewall-cmd --add-port={10051/tcp,10050/tcp} --permanent
firewall-cmd --reload
firewall-cmd --list-all

########### Restarting all services ##########
systemctl restart zabbix-server
systemctl restart zabbix-agent
systemctl restart httpd

########### Disabling the selinux #########
sed -i "s/^SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config
reboot -f

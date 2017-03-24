#!/bin/bash

echo "openvpn setup script started..."

apt-get update -y
apt-get install openvpn easy-rsa -y
rm -rf ~/openvpn-ca
make-cadir ~/openvpn-ca
cd ~/openvpn-ca
configfile=vars

country=$1
province=$2
city=$3
org=$4
email=$5
ou=$6
proto=$7
port=$8
publichostname=$9
username=${10}

echo "country: $country" 
echo "province: $province"
echo "city $city"
echo "org $org"
echo "email $email"
echo "ou $ou"
echo "proto $proto"
echo "port $port"
echo "publichostname $publichostname"
echo "username $username"


[ ! -z "$country" ] && echo "updating country to $country in config" && sed -i 's/KEY_COUNTRY=.*/KEY_COUNTRY="'$country'"/' $configfile
[ ! -z "$province" ] && echo "updating province to $province in config" && sed -i 's/KEY_PROVINCE=.*/KEY_PROVINCE="'$province'"/' $configfile
[ ! -z "$city" ] && echo "updating city to $city in config" && sed -i 's/KEY_CITY=.*/KEY_CITY="'$city'"/' $configfile
[ ! -z "$org" ] && echo "updating org to $org in config" && sed -i 's/KEY_ORG=.*/KEY_ORG="'$org'"/' $configfile
[ ! -z "$email" ] && echo "updating email to $email in config" && sed -i 's/KEY_EMAIL=.*/KEY_EMAIL="'$email'"/' $configfile
[ ! -z "$ou" ] && echo "updating ou to $ou in config" && sed -i 's/KEY_OU=.*/KEY_OU="'$ou'"/' $configfile
sed -i 's/KEY_NAME=.*/KEY_NAME="server"/' $configfile

source vars

echo "cleaning all keys..."
./clean-all

echo "generating ca key..."
echo -e "\n\n\n\n\n\n\n" | ./build-ca

echo "generating server key..."
echo -e "\n\n\n\n\n\n\n\n\n\n" | ./build-key-server --batch server

./build-dh

openvpn --genkey --secret keys/ta.key

echo "generating client key..."
echo -e "\n\n\n\n\n\n\n\n\n\n" | ./build-key --batch client1 

cd ~/openvpn-ca/keys

echo "copying certs and keys..."
cp ca.crt ca.key server.crt server.key ta.key dh2048.pem /etc/openvpn

gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz | sudo tee /etc/openvpn/server.conf

echo "updating server config..."
cd /etc/openvpn
serverconfig=server.conf

sed -i 's/;tls-auth ta.key.*/tls-auth ta.key 0/' $serverconfig
sed -i '/tls-auth ta.key/a key-direction 0' $serverconfig
sed -i 's/;cipher AES-128-CBC.*/cipher AES-128-CBC/' $serverconfig
sed -i '/cipher AES-128-CBC/a auth SHA256' $serverconfig
sed -i 's/;user nobody.*/user nobody/' $serverconfig
sed -i 's/;group nogroup.*/group nogroup/' $serverconfig
sed -i 's/;push "redirect-gateway def1 bypass-dhcp".*/push "redirect-gateway def1 bypass-dhcp"/' $serverconfig
sed -i 's/;push "dhcp-option DNS 208.67.222.222".*/push "dhcp-option DNS 208.67.222.222"/' $serverconfig
sed -i 's/;push "dhcp-option DNS 208.67.220.220".*/push "dhcp-option DNS 208.67.220.220"/' $serverconfig
sed -i "s/port [[:digit:]]*/port $port/" $serverconfig
sed -i "s/proto [[:alpha:]]*/proto $proto/" $serverconfig

cd /etc/
sysctlconfig=sysctl.conf
sed -i 's/#net.ipv4.ip_forward=1.*/net.ipv4.ip_forward=1/' $sysctlconfig
sysctl -p


interface="$(ip route | grep default | grep -oP "dev\s\w+" | cut -c 5-)"
openvpnrules="# START OPENVPN RULES\n# NAT table rules\n*nat\n:POSTROUTING ACCEPT [0:0]\n# Allow traffic from OpenVPN client to $interface\n-A POSTROUTING -s 10.8.0.0/8 -o $interface -j MASQUERADE\nCOMMIT\n# END OPENVPN RULES"

cd /etc/ufw
beforesulesconfig=before.rules

sed -i "/#   ufw-before-forward/a $openvpnrules" $beforesulesconfig

cd /etc/default/

sed -i 's/DEFAULT_FORWARD_POLICY="DROP".*/DEFAULT_FORWARD_POLICY="ACCEPT"/' ufw

ufw allow $port
ufw allow $proto

ufw allow ssh
ufw allow 22

ufw disable
ufw enable

systemctl start openvpn@server

systemctl status openvpn@server

systemctl enable openvpn@server

systemctl start openvpn@server


echo "generating client configuration..."
mkdir -p ~/client-configs/files
chmod 700 ~/client-configs/files

cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf

cd ~/client-configs
configbase=base.conf

sed -i "s/remote my-server-1 [[:digit:]]*/remote $publichostname $port/" $configbase
sed -i "s/proto [[:alpha:]]*/proto $proto/" $configbase
sed -i 's/;user nobody.*/user nobody/' $configbase
sed -i 's/;group nogroup.*/group nogroup/' $configbase

sed -i 's/ca ca.crt.*/#ca ca.crt/' $configbase
sed -i 's/cert client.crt.*/#cert client.crt/' $configbase
sed -i 's/key client.key.*/#key client.key/' $configbase

sed -i 's/;cipher x.*/cipher AES-128-CBC/' $configbase
sed -i '/cipher AES-128-CBC/a auth SHA256' $configbase
sed -i '/auth SHA256/a key-direction 1' $configbase

wget ""

chmod 700 make_config.sh

./make_config.sh client1

dest="/home/$username"
cd ~
cp -R client-configs/ $dest

cd $dest
chown -R $username:$username client-configs

echo "open vpn setup script finished..."
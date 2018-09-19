#!/bin/sh -

export PATH=/bin:/usr/bin:/sbin:/usr/sbin:/opt/aws/bin

export OPENVPN=/etc/openvpn
export EASYRSA_PKI=/var/openvpn/pki

SERVER=`ec2-metadata -v | awk '{ print $2 }'`
NUM_CLIENTS=10

OVPN_DIR=/tmp/ovpn


##################################################
# Helper functions to create .ovpn files

embed() {
    TAG=$1
    FILE=$2

    echo "<${TAG}>" >> ${OVPN_DIR}/${OVPN_FILE}
    cat ${FILE} >> ${OVPN_DIR}/${OVPN_FILE}
    echo "</${TAG}>" >> ${OVPN_DIR}/${OVPN_FILE}
}

mkovpn() {
    CLIENT=$1
    OVPN_FILE=${CLIENT}.ovpn

    mkdir -p ${OVPN_DIR}

    cat > ${OVPN_DIR}/${OVPN_FILE} <<EOF
client
dev tun
key-direction 1
nobind
persist-key
persist-tun
proto udp
remote ${SERVER} 1194
remote-cert-tls server
resolv-retry infinite
verb 1
EOF

    embed ca ${EASYRSA_PKI}/ca.crt
    embed cert ${EASYRSA_PKI}/issued/${CLIENT}.crt
    embed key ${EASYRSA_PKI}/private/${CLIENT}.key
    embed tls-auth ${OPENVPN}/ta.key
}


##################################################
# Install updates and packages

yum -y update
yum -y install openvpn easy-rsa --enablerepo=epel


##################################################
# Put EASYRSA_PKI on persistent storage

if [ -b /dev/xvdf ]; then
    mke2fs -F -t ext4 -j -L pki /dev/xvdf

    mkdir -p `dirname ${EASYRSA_PKI}`

    echo "LABEL=pki `dirname ${EASYRSA_PKI}` ext4 defaults 0 0" >> /etc/fstab
    mount LABEL=pki
fi


##################################################
# Create a new CA

cd `dirname $(rpm -ql easy-rsa | grep easyrsa)`

./easyrsa --batch init-pki
./easyrsa --batch build-ca nopass


##################################################
# Generate server cert and key

./easyrsa --batch build-server-full ${SERVER} nopass


##################################################
# Generate DH (Diffie-Hellman) parameters

./easyrsa gen-dh


##################################################
# Populate OpenVPN configuration

pushd ${OPENVPN}

openvpn --genkey --secret ta.key

ln -s ${EASYRSA_PKI}/dh.pem dh2048.pem
ln -s ${EASYRSA_PKI}/ca.crt
ln -s ${EASYRSA_PKI}/issued/${SERVER}.crt server.crt
ln -s ${EASYRSA_PKI}/private/${SERVER}.key server.key

cp `rpm -ql openvpn | grep /server.conf` .

cat >> server.conf <<EOF

push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 1.0.0.1"
push "redirect-gateway def1 bypass-dhcp"
EOF

popd


##################################################
# Generate client certs and keys

for N in $(seq 1 ${NUM_CLIENTS}); do
    ./easyrsa --batch build-client-full client${N} nopass
    mkovpn client${N}
done


##################################################
# Enable OpenVPN service

chkconfig openvpn on


##################################################
# Enable IP forwarding and NAT

echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
service iptables save


##################################################
# Reboot

sync
shutdown -r now

#!/bin/bash

set -x

### USAGE: ./bm_configure_secondary_vnic.sh <INTERFACE NAME>

apt -qq install -y ipcalc jq

SECONDARY_VNIC_IP=$(curl -s http://169.254.169.254/opc/v1/vnics/ | jq -e -r '.[1].privateIp | select (.!=null)')
SECONDARY_VNIC_SUBNET_CIDR_BLOCK=$(curl -s http://169.254.169.254/opc/v1/vnics/ | jq -e -r '.[1].subnetCidrBlock | select (.!=null)')
SECONDARY_VNIC_NETMASK=$(ipcalc --nobinary 10.0.1.0/24 | awk '/Netmask/ {print $2}')

while [ -z "$SECONDARY_VNIC_IP" ] && [ -z "$SECONDARY_VNIC_SUBNET_CIDR_BLOCK" ]
do 
    echo "Waiting for the secondary VNIC to be attached"
    sleep 10
    SECONDARY_VNIC_IP=$(curl -s http://169.254.169.254/opc/v1/vnics/ | jq -e -r '.[1].privateIp | select (.!=null)')
done 

cat <<EOF > /etc/network/interfaces.d/$1
auto $1
iface $1 inet static
      address $SECONDARY_VNIC_IP
      netmask $SECONDARY_VNIC_NETMASK
EOF

ifup $1

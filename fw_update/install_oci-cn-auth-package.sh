#!/bin/bash

#DEBIAN_FRONTEND=noninteractive

# check if ubuntu or oracle
source /etc/os-release

# download file
UBUNTU_PACKAGE_URL="https://objectstorage.eu-frankfurt-1.oraclecloud.com/p/F7gihhVuJbrnsV8KjAMA7XblkZYRBYJ2xAH2FPmaIJrgtYcuy5wJRWAQXMfw9hLD/n/hpc/b/source/o/oci-cn-auth_2.1.4-compute_all.deb"
UBUNTU_PACKAGE="/tmp/oci-cn-auth_2.1.4-compute_all.deb"
ORACLE_PACKAGE_URL="https://objectstorage.eu-frankfurt-1.oraclecloud.com/p/F7gihhVuJbrnsV8KjAMA7XblkZYRBYJ2xAH2FPmaIJrgtYcuy5wJRWAQXMfw9hLD/n/hpc/b/source/o/oci-cn-auth-2.1.4-compute.el7.noarch.rpm"
ORACLE_PACKAGE="/tmp/oci-cn-auth-2.1.4-compute.el7.noarch.rpm"


if [ $ID == "ol" ] ; then
  echo "oracle"
  USERNAME=opc
  wget -O $ORACLE_PACKAGE  $ORACLE_PACKAGE_URL
  sudo yum localinstall -y -q  $ORACLE_PACKAGE
fi

if [ $ID == "ubuntu" ] ; then
  echo "ubuntu"
  USERNAME=ubuntu
  wget -O $UBUNTU_PACKAGE  $UBUNTU_PACKAGE_URL
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q  $UBUNTU_PACKAGE
fi

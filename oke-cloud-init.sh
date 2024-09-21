#!/bin/bash

add-apt-repository -y 'deb [trusted=yes] https://odx-oke.objectstorage.us-sanjose-1.oci.customer-oci.com/n/odx-oke/b/okn-repositories/o/prod/ubuntu-jammy/kubernetes-1.29 stable main'

apt update && apt install -y oci-oke-node-all*

cat <<EOF > /etc/containers/storage.conf
[storage]
# Default storage driver
driver = "overlay"
# Temporary storage location
runroot = "/var/run/containers/storage"
# Primary read/write location of container storage 
graphroot = "/var/lib/oke-crio"
EOF

oke bootstrap --manage-gpu-services

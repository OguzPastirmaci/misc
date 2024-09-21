#!/bin/bash

# Add OKE Ubuntu package repo
add-apt-repository -y 'deb [trusted=yes] https://odx-oke.objectstorage.us-sanjose-1.oci.customer-oci.com/n/odx-oke/b/okn-repositories/o/prod/ubuntu-jammy/kubernetes-1.29 stable main'

# Wait for apt lock and install the package
while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
   sleep 1
done

apt-get update && apt-get install -y oci-oke-node-all*

# Edit storage.conf for using the first Nvme drive for container images
cat <<EOF > /etc/containers/storage.conf
[storage]
# Default storage driver
driver = "overlay"
# Temporary storage location
runroot = "/var/run/containers/storage"
# Primary read/write location of container storage
graphroot = "/var/lib/oke-crio"
EOF

# OKE bootstrap
oke bootstrap --manage-gpu-services

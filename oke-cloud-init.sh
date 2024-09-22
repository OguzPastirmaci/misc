#!/bin/bash

distrib_codename=$(lsb_release -c -s)
kubernetes_version=$1
oke_package_version="${kubernetes_version:1}"
echo $oke_package_version
oke_package_repo_version="${oke_package_version:0:4}"
echo $oke_package_repo_version
oke_package_name="oci-oke-node-all-$oke_package_version"
echo $oke_package_name
oke_package_repo="https://odx-oke.objectstorage.us-sanjose-1.oci.customer-oci.com/n/odx-oke/b/okn-repositories/o/prod/ubuntu-$distrib_codename/kubernetes-$oke_package_repo_version"
echo $oke_package_repo
# Add OKE Ubuntu package repo
add-apt-repository -y "deb [trusted=yes] $oke_package_repo stable main"

apt-get -y -o DPkg::Lock::Timeout=-1 update

apt-get -y -o DPkg::Lock::Timeout=-1 install $oke_package_name

# Edit storage.conf to use the first Nvme drive (if it exists) for container images
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

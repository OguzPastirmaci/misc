#!/bin/bash

# Wait for apt lock and install the package
#while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
#   sleep 1
#done
distrib_codename=$(lsb_release -c -s)
kubernetes_version=$1
oke_package_version="${kubernetes_version:1:4}"
oke_package_name="oci-oke-node-all-$oke_package_version"
oke_package_repo="https://odx-oke.objectstorage.us-sanjose-1.oci.customer-oci.com/n/odx-oke/b/okn-repositories/o/prod/ubuntu-$distrib_codename/kubernetes-$oke_package_version"

# Add OKE Ubuntu package repo
add-apt-repository -y "deb [trusted=yes] $oke_package_repo stable main"

apt-get -y -o DPkg::Lock::Timeout=-1 update

apt-get -y -o DPkg::Lock::Timeout=-1 install $oke_package_name

# Use the first Nvme drive (/dev/nvme0n1) for CRI-O if it exists
#if [ -e '/dev/nvme0n1' ]; then
#    echo "/dev/nvme0n1 found, configuring it for CRI-O"
#    mkdir -p /var/lib/oke-crio
#    parted -a opt --script /dev/nvme0n1 mklabel gpt mkpart primary 0% 100%
#    mkfs.ext4 /dev/nvme0n1p1
#    mount /dev/nvme0n1p1 /var/lib/oke-crio
#    echo "/dev/nvme0n1p1 /var/lib/oke-crio ext4 rw,noatime,nofail 0 2" | tee -a /etc/fstab
#else
#    echo "/dev/nvme0n1 not found"
#    mkdir -p /var/lib/oke-crio
#fi

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

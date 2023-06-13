#!/bin/bash
# Script to set roce_tx_window_en=0
#
#
mlxreg=$(which mlxreg)
shape=$(curl -q -s 169.254.169.254/opc/v1/instance/shape)
for pci_id in $(cat /opt/oci-hpc/oci-cn-auth/configs/shapes.json | jq '.["hpc-shapes"]' | jq ".[] | select(.shape==\"$shape\") " | jq -r '.["rdma-nics"] | .[].pci') ; do
echo $pci_id ; $mlxreg --yes -d $pci_id --reg_name ROCE_ACCL --set roce_tx_window_en=0
done

### Get IDs of instances in a cluster network
```sh
oci compute-management cluster-network list-instances --all --cluster-network-id $CLUSTER_NETWORK_ID -c $COMPARTMENT_ID | jq -r '.data[].id'
```

### Get GPUs and VFs of BM GPU instances in OKE
```sh
kubectl get nodes -l 'node.kubernetes.io/instance-type in (BM.GPU.H100.8, BM.GPU.A100-v2.8, BM.GPU4.8, BM.GPU.B4.8)' --sort-by=.status.capacity."nvidia\.com/sriov_rdma_vf" -o=custom-columns='NODE:metadata.name,GPUs:status.allocatable.nvidia\.com/gpu,RDMA-VFs:status.allocatable.nvidia\.com/sriov_rdma_vf'
```

### Add a block volume to to an instance from the instance
```sh
AD=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/ | jq -r '.availabilityDomain')
COMPARTMENT_ID=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/ | jq -r '.compartmentId')
INSTANCE_ID=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/ | jq -r '.id')
CREATED_VOLUME_ID=$(oci bv volume create --availability-domain $AD --compartment-id $COMPARTMENT_ID --display-name $(hostname) --size-in-gbs 100 --auth instance_principal | jq -r '.data | .id')

# Wait until block volume status becomes available before trying to attach
until [ oci bv volume get --volume-id $CREATED_VOLUME_ID --auth instance_principal | jq -r '.data."lifecycle-state"') == "AVAILABLE" ]; do
sleep 10
done

oci compute volume-attachment attach-paravirtualized-volume --instance-id $INSTANCE_ID --volume-id $CREATED_VOLUME_ID --auth instance_principal
```

### Add secondary vnics to an OKE node pool
```sh
OKE_CLUSTER_ID=
COMPARTMENT_ID=
KUBERNETES_VERSION=
NODE_POOL_NAME=
NODE_POOL_SIZE=
NODE_POOL_BOOT_VOLUME_SIZE_IN_GB=
NODE_POOL_SHAPE=
NODE_IMAGE_ID=
NODE_POOL_SUBNET_ID=
AVAILABILITY_DOMAIN=
SSH_PUBLIC_KEY=
REGION=
SECONDARY_VNIC_DISPLAY_NAME=

# Create a new node pool and get the work request ID
CREATED_NODE_POOL_WORK_REQUEST_ID=$(oci ce node-pool create \
--region $REGION \
--cluster-id $OKE_CLUSTER_ID \
--name $NODE_POOL_NAME \
--node-image-id $NODE_IMAGE_ID \
--compartment-id $COMPARTMENT_ID \
--kubernetes-version $KUBERNETES_VERSION \
--node-shape $NODE_POOL_SHAPE \
--node-shape-config '{"ocpus": 2, "memoryInGBs": 16}' \
--size $NODE_POOL_SIZE \
--placement-configs '[{"availabilityDomain": "'$AVAILABILITY_DOMAIN'", "subnetId": "'$NODE_POOL_SUBNET_ID'"}]' \
--ssh-public-key "$SSH_PUBLIC_KEY" \
--node-metadata '{"user_data": "IyEvYmluL2Jhc2gKCmN1cmwgLS1mYWlsIC1IICJBdXRob3JpemF0aW9uOiBCZWFyZXIgT3JhY2xlIiAtTDAgaHR0cDovLzE2OS4yNTQuMTY5LjI1NC9vcGMvdjIvaW5zdGFuY2UvbWV0YWRhdGEvb2tlX2luaXRfc2NyaXB0IHwgYmFzZTY0IC0tZGVjb2RlID4vdmFyL3J1bi9va2UtaW5pdC5zaAoKYmFzaCAvdmFyL3J1bi9va2UtaW5pdC5zaAoKc3VkbyBkZCBpZmxhZz1kaXJlY3QgaWY9L2Rldi9vcmFjbGVvY2kvb3JhY2xldmRhIG9mPS9kZXYvbnVsbCBjb3VudD0xCmVjaG8gIjEiIHwgc3VkbyB0ZWUgL3N5cy9jbGFzcy9ibG9jay9gcmVhZGxpbmsgL2Rldi9vcmFjbGVvY2kvb3JhY2xldmRhIHwgY3V0IC1kJy8nIC1mIDJgL2RldmljZS9yZXNjYW4KCnN1ZG8gL3Vzci9saWJleGVjL29jaS1ncm93ZnMgLXk="}' \
| jq -r '."opc-work-request-id"')

# Wait until the node pool is created
while [[ "$(oci ce work-request get --work-request-id $CREATED_NODE_POOL_WORK_REQUEST_ID | jq -r '.data.status')" != "SUCCEEDED" ]]; do
    echo "$(date) -- Waiting for the node pool to be created"
    sleep 10
done

# Get the node pool ID
CREATED_NODE_POOL_ID=$(oci ce work-request get --work-request-id $CREATED_NODE_POOL_WORK_REQUEST_ID | jq -r '.data.resources[].identifier' |grep nodepool)

# Get the IDs of the instances in the created node pool
INSTANCES_IN_NODEPOOL=$(oci ce node-pool get --node-pool-id $CREATED_NODE_POOL_ID | jq -r '.data.nodes[].id')

# Add a VNIC to all instances in the node pool
SUBNET_ID=$(oci ce node-pool get --node-pool-id $CREATED_NODE_POOL_ID | jq -r '.data.nodes[]."subnet-id"')

for INSTANCE in $INSTANCES_IN_NODEPOOL; do
    oci compute instance attach-vnic --instance-id $INSTANCE --subnet-id $SUBNET_ID --vnic-display-name $SECONDARY_VNIC_DISPLAY_NAME --region $REGION
    done
```

### Sort instances in an instance pool

#### Sort instances by date
```sh
oci compute-management instance-pool list-instances --instance-pool-id $INSTANCE_POOL_ID --region $REGION --compartment-id $COMPARTMENT_ID | jq '.[] |= sort_by(."time-created")
```

#### Get the newest instance
```sh
oci compute-management instance-pool list-instances --instance-pool-id $INSTANCE_POOL_ID --region $REGION --compartment-id $COMPARTMENT_ID | jq '.[] |= sort_by(."time-created")[-1]'

oci compute-management instance-pool list-instances --instance-pool-id $INSTANCE_POOL_ID --region $REGION --compartment-id $COMPARTMENT_ID | jq -r '.[] |= sort_by(."time-created")[-1] | .data.id'
```

#### Get the newest 2
```sh
oci compute-management instance-pool list-instances --instance-pool-id $INSTANCE_POOL_ID --region $REGION --compartment-id $COMPARTMENT_ID | jq -r '.[] |= sort_by(."time-created")[-2:] | .data[] .id'
```

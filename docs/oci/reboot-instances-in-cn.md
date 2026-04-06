```sh
CLUSTER_NETWORK_ID=
COMPARTMENT_ID=

INSTANCES_IN_CN=$(oci compute-management cluster-network list-instances --cluster-network-id $CLUSTER_NETWORK_ID -c $COMPARTMENT_ID | jq -r '.data[].id')

for INSTANCE in $INSTANCES_IN_CN; do
    oci compute instance action --action RESET --instance-id $INSTANCE
    done
```

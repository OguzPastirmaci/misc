INSTANCE_POOL_ID=ocid1.instancepool.oc1.iad.aaaaaaaa6myr7vcber4i3i6qr6jboo5vhkxdokuwcr2kngi4ffo6u2czczuq

# How many instances should be created or destroyed each time the command runs
NUMBER_OF_INSTANCES_TO_ADD_OR_REMOVE=1

# Get the current size of the instance pool
CURRENT_INSTANCE_POOL_SIZE=$(oci compute-management instance-pool get --instance-pool-id $INSTANCE_POOL_ID --query 'data.size' --raw-output)

# SCALE OUT - Add new nodes to the pool by the number of NUMBER_OF_INSTANCES_TO_ADD_OR_REMOVE variable
NEW_INSTANCE_POOL_SIZE=$((CURRENT_INSTANCE_POOL_SIZE + NUMBER_OF_INSTANCES_TO_ADD_OR_REMOVE))
oci compute-management instance-pool update --instance-pool-id $INSTANCE_POOL_ID --size $NEW_INSTANCE_POOL_SIZE

# SCALE IN - Remove nodes from the pool by the number of NUMBER_OF_INSTANCES_TO_ADD_OR_REMOVE variable
NEW_INSTANCE_POOL_SIZE=$((CURRENT_INSTANCE_POOL_SIZE + NUMBER_OF_INSTANCES_TO_ADD_OR_REMOVE))
oci compute-management instance-pool update --instance-pool-id $INSTANCE_POOL_ID --size $NEW_INSTANCE_POOL_SIZE

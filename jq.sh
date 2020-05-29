# Sort instances by date
oci compute-management instance-pool list-instances --instance-pool-id $INSTANCE_POOL_ID --region $REGION --compartment-id $COMPARTMENT_ID | jq '.[] |= sort_by(."time-created")

# Get the newest instance
oci compute-management instance-pool list-instances --instance-pool-id $INSTANCE_POOL_ID --region $REGION --compartment-id $COMPARTMENT_ID | jq '.[] |= sort_by(."time-created")[-1]'

oci compute-management instance-pool list-instances --instance-pool-id $INSTANCE_POOL_ID --region $REGION --compartment-id $COMPARTMENT_ID | jq -r '.[] |= sort_by(."time-created")[-1] | .data.id'

# Get the newest 2
oci compute-management instance-pool list-instances --instance-pool-id $INSTANCE_POOL_ID --region $REGION --compartment-id $COMPARTMENT_ID | jq -r '.[] |= sort_by(."time-created")[-2:] | .data[] .id'

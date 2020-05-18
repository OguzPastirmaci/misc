# Check the number of API Server Requests metric with a 5 minute interval
oci monitoring metric-data summarize-metrics-data --namespace oci_oke --compartment-id ocid1.compartment.oc1..aaaaaaaafxezajxlyjxkh23ux75iqttja2qvdded3fc3v5h4kth6zvhnus3q --query-text='(APIServerRequestCount[5m]{ clusterId="ocid1.cluster.oc1.iad.aaaaaaaaae4deyzygiztszjxgu2wemzrmi4windcmvrdan3cgctdqmrumfsg"}.rate() )' | jq -r '.data[]."aggregated-datapoints"[].value'

# Add a node
SIZE=$(oci ce node-pool get --node-pool-id $NODE_POOL_ID --region $REGION | jq -r '.data | ."node-config-details" | .size')

if [ "$SIZE" -ge "$SCALING_MAX" ]
then
	echo "Skipping because of node pool sizing rules"
elif [ $(( $(date +%s) - $(date +%s -r $SCALE_LOG) )) -le "$SCALING_FREQUENCY" ]
then
	echo "Last scaling operation happened in the last $SCALING_FREQUENCY seconds, skipping"
else
	((SIZE++))
	oci ce node-pool update --node-pool-id $NODE_POOL_ID --region $REGION --size $SIZE --force
    echo "Scaled at $(date)" > $SCALE_LOG
fi


# Remove a node
SIZE=$(oci ce node-pool get --node-pool-id $NODE_POOL_ID --region $REGION | jq -r '.data | ."node-config-details" | .size')

if [ "$SIZE" -le "$SCALING_MIN" ]
then
	echo "Skipping because of node pool sizing rules"
elif [ $(( $(date +%s) - $(date +%s -r $SCALE_LOG) )) -le "$SCALING_FREQUENCY" ]
then
	echo "Last scaling operation happened in the last $SCALING_FREQUENCY seconds, skipping"
else
	((SIZE--))
	oci ce node-pool update --node-pool-id $NODE_POOL_ID --region $REGION --size $SIZE --force
    echo "Scaled at $(date)" > $SCALE_LOG
fi
